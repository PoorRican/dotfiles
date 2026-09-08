"""Install an initial runtime snapshot without replacing an existing file.

Usage: seed-file.py SOURCE DESTINATION [--dry-run] [--verbose]
Only verbose output includes content (a snapshot-to-runtime unified text diff).
"""

import argparse
import difflib
import errno
import io
import os
import secrets
import stat
import sys
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path


def report_existing(source: Path, destination: Path, parent_fd: int, *, verbose: bool) -> bool:
    """Compare a regular file without following links or blocking on a FIFO."""
    try:
        mode = os.stat(destination.name, dir_fd=parent_fd, follow_symlinks=False).st_mode
    except FileNotFoundError:
        return False
    if not stat.S_ISREG(mode):
        print(f"hermes: seed {destination}: non-regular file or symlink exists; preserved")
        return True

    try:
        fd = os.open(destination.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent_fd)
    except FileNotFoundError:
        return False
    except OSError as error:
        if error.errno != errno.ELOOP:
            raise
        print(f"hermes: seed {destination}: symlink appeared; preserved")
        return True
    with os.fdopen(fd, "rb") as runtime:
        if not stat.S_ISREG(os.fstat(runtime.fileno()).st_mode):
            print(f"hermes: seed {destination}: non-regular file appeared; preserved")
            return True
        actual = runtime.read()
    expected = source.read_bytes()
    if actual == expected:
        print(f"hermes: seed {destination}: matches snapshot; preserved")
        return True

    print(f"hermes: seed {destination}: differs from snapshot; preserved")
    if verbose:
        try:
            before = expected.decode("utf-8")
            after = actual.decode("utf-8")
        except UnicodeDecodeError:
            print("hermes: diff unavailable for non-UTF-8 content")
            return True
        if "\x00" in before or "\x00" in after:
            print("hermes: diff unavailable for binary content")
            return True
        for line in difflib.unified_diff(
            io.StringIO(before).readlines(),
            io.StringIO(after).readlines(),
            fromfile=f"{destination} (snapshot)",
            tofile=f"{destination} (runtime)",
        ):
            sys.stdout.write(line)
            if not line.endswith("\n"):
                sys.stdout.write("\n\\ No newline at end of file\n")
    return True


@contextmanager
def parent_directory(destination: Path, *, create: bool) -> Iterator[int | None]:
    """Walk without following symlinks and retain the inspected parent inode."""
    destination = destination.absolute()
    if ".." in destination.parts:
        raise ValueError(f"hermes: seed destination contains parent traversal: {destination}")
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    parent_fd = os.open(destination.anchor, flags)
    try:
        for component in destination.parts[1:-1]:
            try:
                child_fd = os.open(component, flags, dir_fd=parent_fd)
            except FileNotFoundError:
                if not create:
                    yield None
                    return
                try:
                    os.mkdir(component, mode=0o700, dir_fd=parent_fd)
                except FileExistsError:
                    pass  # A competing creator still has to pass O_NOFOLLOW.
                child_fd = os.open(component, flags, dir_fd=parent_fd)
            os.close(parent_fd)
            parent_fd = child_fd
        yield parent_fd
    finally:
        os.close(parent_fd)


def seed_file(source: Path, destination: Path, *, dry_run: bool = False, verbose: bool = False) -> None:
    with parent_directory(destination, create=not dry_run) as parent_fd:
        if parent_fd is not None and report_existing(source, destination, parent_fd, verbose=verbose):
            return
        if dry_run:
            print(f"hermes: seed {destination}: missing; would seed")
            return
        assert parent_fd is not None

        # Every operation stays relative to the inspected directory descriptor:
        # a parent rename/symlink swap cannot redirect publication or cleanup.
        temporary_name = f".hermes-seed-{secrets.token_hex(16)}"
        temporary_fd = os.open(
            temporary_name, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600, dir_fd=parent_fd
        )
        try:
            with os.fdopen(temporary_fd, "wb") as temporary:
                os.fchmod(temporary.fileno(), 0o600)
                temporary.write(source.read_bytes())
                temporary.flush()
                os.fsync(temporary.fileno())
            # Publish a complete private inode without replacing ANY existing
            # entry. Exclusive destination open would expose a partial copy.
            try:
                os.link(
                    temporary_name, destination.name,
                    src_dir_fd=parent_fd, dst_dir_fd=parent_fd, follow_symlinks=False,
                )
            except FileExistsError:
                if not report_existing(source, destination, parent_fd, verbose=verbose):
                    raise RuntimeError(f"hermes: seed destination changed concurrently; retry activation: {destination}")
                return
        finally:
            os.unlink(temporary_name, dir_fd=parent_fd)
    print(f"hermes: seed {destination}: seeded; now runtime-owned")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    try:
        seed_file(args.source, args.destination, dry_run=args.dry_run, verbose=args.verbose)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"hermes: seeding failed: {args.destination}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

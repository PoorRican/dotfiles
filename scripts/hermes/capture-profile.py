"""Create a review-only snapshot of one live Hermes profile and selected sources.

Usage: capture-profile.py --deployment-info STORE_JSON [--profile NAME]
       [--source LABEL=PATH ...] [--output NEW_DIRECTORY]
"""

import argparse
import errno
import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import socket
import stat
import subprocess
import sys


FORMAT = "hermes-profile-capture"
FORMAT_VERSION = 1
STORE_ROOT = Path("/nix/store")
READ_SIZE = 1024 * 1024
SAFE_COMPONENT = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*\Z")


class CaptureError(Exception):
    """A capture cannot be completed without weakening its safety guarantees."""


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def absolute_path(value, description: str) -> Path:
    if not isinstance(value, str) or not value:
        raise CaptureError(f"{description} must be a nonempty path")
    path = Path(os.path.abspath(os.path.expanduser(value)))
    if not path.is_absolute():
        raise CaptureError(f"{description} must be absolute")
    return path


def safe_component(value: str, description: str) -> str:
    if not isinstance(value, str) or not SAFE_COMPONENT.fullmatch(value) or value in {".", ".."}:
        raise CaptureError(f"invalid {description}: expected one safe path component")
    return value



def fd_flags(directory: bool = False) -> int:
    flags = os.O_RDONLY | os.O_NOFOLLOW
    if directory:
        flags |= getattr(os, "O_DIRECTORY", 0)
    return flags


def open_absolute_directory(path: Path) -> int:
    """Open every path component without following symlinks."""
    path = Path(os.path.abspath(path))
    if not path.is_absolute():
        raise CaptureError(f"directory path is not absolute: {path}")
    current = os.open(path.anchor, fd_flags(directory=True))
    try:
        for component in path.parts[1:]:
            child = os.open(component, fd_flags(directory=True), dir_fd=current)
            os.close(current)
            current = child
        return current
    except BaseException:
        os.close(current)
        raise


def open_absolute_parent(path: Path) -> tuple[int, str]:
    path = Path(os.path.abspath(path))
    if path.name in {"", ".", ".."}:
        raise CaptureError(f"path must name a file: {path}")
    return open_absolute_directory(path.parent), path.name


def stat_at(parent_fd: int, name: str):
    return os.stat(name, dir_fd=parent_fd, follow_symlinks=False)


def path_stat(path: Path):
    parent_fd, name = open_absolute_parent(path)
    try:
        return stat_at(parent_fd, name)
    finally:
        os.close(parent_fd)


def is_beneath(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def paths_overlap(first: Path, second: Path) -> bool:
    return is_beneath(first, second) or is_beneath(second, first)


def _store_resolved_path(path: Path) -> Path:
    try:
        resolved = path.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise CaptureError(f"cannot resolve immutable store link: {path}") from error
    if not is_beneath(resolved, STORE_ROOT) or resolved == STORE_ROOT:
        raise CaptureError(f"refusing symlink outside immutable Nix store: {path}")
    return resolved


def read_stable_fd(fd: int, *, source: str) -> tuple[bytes, str]:
    before = os.fstat(fd)
    if not stat.S_ISREG(before.st_mode):
        raise CaptureError(f"not a regular file: {source}")
    digest = hashlib.sha256()
    chunks = []
    count = 0
    while True:
        block = os.read(fd, READ_SIZE)
        if not block:
            break
        chunks.append(block)
        digest.update(block)
        count += len(block)
    after = os.fstat(fd)
    identity_before = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns)
    identity_after = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns)
    if identity_before != identity_after or count != before.st_size:
        raise CaptureError(f"source changed while being read: {source}")
    return b"".join(chunks), digest.hexdigest()


def read_regular_path(path: Path, *, allow_store_link: bool = False) -> tuple[bytes, str, Path]:
    """Read a stable regular file; only an explicitly allowed store symlink is followed."""
    path = Path(os.path.abspath(path))
    parent_fd, name = open_absolute_parent(path)
    try:
        item = stat_at(parent_fd, name)
        if stat.S_ISLNK(item.st_mode):
            if not allow_store_link:
                raise CaptureError(f"symlink is not allowed here: {path}")
            resolved = _store_resolved_path(path)
            if resolved == path:
                raise CaptureError(f"invalid immutable store link: {path}")
            data, digest, _ = read_regular_path(resolved)
            return data, digest, resolved
        if not stat.S_ISREG(item.st_mode):
            raise CaptureError(f"not a regular file: {path}")
        fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0), dir_fd=parent_fd)
        try:
            data, digest = read_stable_fd(fd, source=str(path))
            return data, digest, path
        finally:
            os.close(fd)
    finally:
        os.close(parent_fd)


def regular_path_metadata(path: Path, *, allow_store_link: bool = False) -> Path:
    path = Path(os.path.abspath(path))
    parent_fd, name = open_absolute_parent(path)
    try:
        item = stat_at(parent_fd, name)
        if stat.S_ISLNK(item.st_mode):
            if not allow_store_link:
                raise CaptureError(f"symlink is not allowed here: {path}")
            return _store_resolved_path(path)
        if not stat.S_ISDIR(item.st_mode):
            raise CaptureError(f"not a directory: {path}")
        return path
    finally:
        os.close(parent_fd)


def excluded_reason(name: str, *, is_directory: bool = False, runtime: bool = False) -> str | None:
    lowered = name.lower()
    if lowered == ".git":
        return "git-metadata-excluded"
    if (
        lowered == ".env"
        or lowered.startswith(".env.")
        or lowered in {"auth.json", "vault.key", "vault.json.enc", "id_rsa", "id_ed25519"}
        or lowered.startswith("credentials.")
        or lowered.endswith((".key", ".pem", ".p12", ".pfx"))
    ):
        return "credential-excluded"
    if runtime and is_directory and lowered == ".curator_backups":
        return "legacy-curator-backups-excluded"
    if runtime and is_directory and lowered in {"cache", ".cache", "caches", "tmp", "temp", "temporary", "locks", "lock", "__pycache__"}:
        return "cache-or-temporary-directory-excluded"
    if runtime and not is_directory and (
        lowered.endswith((".lock", ".tmp", ".temp", ".swp", ".part", "~"))
        or lowered.startswith(".#")
    ):
        return "lock-or-temporary-file-excluded"
    return None


def excluded_path_reason(path: str, *, is_directory: bool = False, runtime: bool = False) -> str | None:
    parts = PurePosixPath(path).parts
    for index, part in enumerate(parts):
        reason = excluded_reason(
            part,
            is_directory=is_directory if index == len(parts) - 1 else True,
            runtime=runtime,
        )
        if reason:
            return reason
    return None


def has_credential_path_component(path: str) -> bool:
    """Check every component so runtime cache exclusions cannot mask credentials."""
    return any(
        excluded_reason(part) == "credential-excluded"
        for part in PurePosixPath(path).parts
    )


def relative_join(parent: str, name: str) -> str:
    return name if not parent else parent + "/" + name


def ensure_destination_directory(parent_fd: int, name: str) -> int:
    try:
        os.mkdir(name, mode=0o700, dir_fd=parent_fd)
    except FileExistsError:
        pass
    child = os.open(name, fd_flags(directory=True), dir_fd=parent_fd)
    os.fchmod(child, 0o700)
    return child


def destination_parent(stage_fd: int, relative: str) -> tuple[int, str]:
    path = PurePosixPath(relative)
    if path.is_absolute() or not path.parts or any(part in {"", ".", ".."} for part in path.parts):
        raise CaptureError(f"unsafe snapshot-relative path: {relative!r}")
    current = os.dup(stage_fd)
    try:
        for component in path.parts[:-1]:
            child = ensure_destination_directory(current, component)
            os.close(current)
            current = child
        return current, path.parts[-1]
    except BaseException:
        os.close(current)
        raise


def copy_file_at(
    source_parent_fd: int,
    source_name: str,
    destination_stage_fd: int,
    destination_relative: str,
    *,
    source_path: str,
) -> tuple[str, int]:
    flags = os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0)
    try:
        source_fd = os.open(source_name, flags, dir_fd=source_parent_fd)
    except OSError as error:
        if error.errno == errno.ELOOP:
            raise CaptureError(f"symlink is not followed: {source_path}") from error
        raise
    try:
        destination_parent_fd, destination_name = destination_parent(destination_stage_fd, destination_relative)
    except BaseException:
        os.close(source_fd)
        raise
    destination_fd = -1
    try:
        before = os.fstat(source_fd)
        if not stat.S_ISREG(before.st_mode):
            raise CaptureError(f"not a regular file: {source_path}")
        destination_fd = os.open(
            destination_name,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o600,
            dir_fd=destination_parent_fd,
        )
        os.fchmod(destination_fd, 0o600)
        digest = hashlib.sha256()
        count = 0
        while True:
            block = os.read(source_fd, READ_SIZE)
            if not block:
                break
            digest.update(block)
            view = memoryview(block)
            while view:
                written = os.write(destination_fd, view)
                if written <= 0:
                    raise OSError("snapshot write made no progress")
                view = view[written:]
            count += len(block)
        after = os.fstat(source_fd)
        before_identity = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns)
        after_identity = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns)
        if before_identity != after_identity or count != before.st_size:
            raise CaptureError(f"source changed while being copied: {source_path}")
        os.fsync(destination_fd)
        return digest.hexdigest(), count
    except BaseException:
        if destination_fd >= 0:
            os.close(destination_fd)
            destination_fd = -1
            try:
                os.unlink(destination_name, dir_fd=destination_parent_fd)
            except FileNotFoundError:
                pass
        raise
    finally:
        if destination_fd >= 0:
            os.close(destination_fd)
        os.close(source_fd)
        os.close(destination_parent_fd)


def copy_file_path(
    source_path: Path,
    stage_fd: int,
    destination_relative: str,
    *,
    scope: str,
    files: list,
    skipped: list,
) -> None:
    source_path = Path(os.path.abspath(source_path))
    parent_fd, name = open_absolute_parent(source_path)
    try:
        try:
            item = stat_at(parent_fd, name)
        except FileNotFoundError:
            raise CaptureError(f"source disappeared while being captured: {source_path}")
        reason = excluded_path_reason(str(source_path)) or excluded_reason(
            name, runtime=scope.startswith("runtime:")
        )
        if reason:
            skipped.append({"scope": scope, "path": destination_relative, "original_path": str(source_path), "reason": reason})
            return
        if stat.S_ISLNK(item.st_mode):
            skipped.append({"scope": scope, "path": destination_relative, "original_path": str(source_path), "reason": "symlink-not-followed"})
            return
        if not stat.S_ISREG(item.st_mode):
            skipped.append({"scope": scope, "path": destination_relative, "original_path": str(source_path), "reason": "non-regular-file"})
            return
        digest, size = copy_file_at(
            parent_fd,
            name,
            stage_fd,
            destination_relative,
            source_path=str(source_path),
        )
        files.append({
            "scope": scope,
            "path": destination_relative,
            "original_path": str(source_path),
            "sha256": digest,
            "bytes": size,
        })
    finally:
        os.close(parent_fd)


def copy_tree_fd(
    source_fd: int,
    destination_directory_fd: int,
    stage_fd: int,
    *,
    source_path: Path,
    destination_prefix: str,
    scope: str,
    files: list,
    skipped: list,
) -> None:
    for name in sorted(os.listdir(source_fd)):
        relative = relative_join(destination_prefix, name)
        original = source_path / name
        try:
            item = stat_at(source_fd, name)
        except FileNotFoundError:
            skipped.append({"scope": scope, "path": relative, "original_path": str(original), "reason": "source-disappeared"})
            continue
        is_directory = stat.S_ISDIR(item.st_mode)
        reason = excluded_path_reason(
            relative,
            is_directory=is_directory,
            runtime=scope.startswith("runtime:"),
        )
        if reason:
            skipped.append({"scope": scope, "path": relative, "original_path": str(original), "reason": reason})
            continue
        if stat.S_ISLNK(item.st_mode):
            skipped.append({"scope": scope, "path": relative, "original_path": str(original), "reason": "symlink-not-followed"})
            continue
        if is_directory:
            child_source_fd = os.open(name, fd_flags(directory=True), dir_fd=source_fd)
            child_destination_fd = ensure_destination_directory(destination_directory_fd, name)
            try:
                copy_tree_fd(
                    child_source_fd,
                    child_destination_fd,
                    stage_fd,
                    source_path=original,
                    destination_prefix=relative,
                    scope=scope,
                    files=files,
                    skipped=skipped,
                )
            finally:
                os.close(child_destination_fd)
                os.close(child_source_fd)
            continue
        if not stat.S_ISREG(item.st_mode):
            skipped.append({"scope": scope, "path": relative, "original_path": str(original), "reason": "non-regular-file"})
            continue
        digest, size = copy_file_at(source_fd, name, stage_fd, relative, source_path=str(original))
        files.append({"scope": scope, "path": relative, "original_path": str(original), "sha256": digest, "bytes": size})


def open_destination_directory(stage_fd: int, relative: str, *, create: bool) -> int:
    parts = PurePosixPath(relative).parts
    if not parts or any(part in {"", ".", ".."} for part in parts):
        raise CaptureError(f"unsafe destination directory: {relative!r}")
    current = os.dup(stage_fd)
    try:
        for component in parts:
            if create:
                child = ensure_destination_directory(current, component)
            else:
                child = os.open(component, fd_flags(directory=True), dir_fd=current)
            os.close(current)
            current = child
        return current
    except BaseException:
        os.close(current)
        raise


def copy_tree_path(
    source_path: Path,
    destination_stage_fd: int,
    *,
    destination_prefix: str,
    scope: str,
    files: list,
    skipped: list,
) -> bool:
    source_path = Path(os.path.abspath(source_path))
    try:
        parent_fd, name = open_absolute_parent(source_path)
    except FileNotFoundError:
        return False
    try:
        try:
            item = stat_at(parent_fd, name)
        except FileNotFoundError:
            return False
        if stat.S_ISLNK(item.st_mode):
            skipped.append({"scope": scope, "path": destination_prefix, "original_path": str(source_path), "reason": "symlink-not-followed"})
            return False
        if not stat.S_ISDIR(item.st_mode):
            raise CaptureError(f"capture tree root is not a directory: {source_path}")
    finally:
        os.close(parent_fd)
    source_fd = open_absolute_directory(source_path)
    destination_fd = open_destination_directory(destination_stage_fd, destination_prefix, create=True)
    try:
        copy_tree_fd(
            source_fd,
            destination_fd,
            destination_stage_fd,
            source_path=source_path,
            destination_prefix=destination_prefix,
            scope=scope,
            files=files,
            skipped=skipped,
        )
        return True
    finally:
        os.close(destination_fd)
        os.close(source_fd)





def read_deployment_info(path: Path) -> dict:
    try:
        raw, _digest, _resolved = read_regular_path(path)
        info = json.loads(raw)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise CaptureError("deployment-info JSON is unreadable or invalid") from error
    if not isinstance(info, dict) or info.get("schema_version") != 1:
        raise CaptureError("deployment-info must be an object with schema_version 1")
    if not isinstance(info.get("package"), str):
        raise CaptureError("deployment-info package must be a string")
    for field in ("hermes_revision", "agent_profiles_revision"):
        if info.get(field) is not None and not isinstance(info.get(field), str):
            raise CaptureError(f"deployment-info {field} must be a string or null")
    source_revisions = info.get("source_revisions")
    if source_revisions is not None and (
        not isinstance(source_revisions, dict)
        or any(
            not isinstance(key, str) or (value is not None and not isinstance(value, str))
            for key, value in source_revisions.items()
        )
    ):
        raise CaptureError("deployment-info source_revisions must map strings to strings or null")
    profiles = info.get("profiles")
    if not isinstance(profiles, dict):
        raise CaptureError("deployment-info profiles must be an object")
    return info


def profile_paths(info: dict, name: str) -> dict:
    safe_component(name, "profile name")
    try:
        profile = info["profiles"][name]
    except KeyError as error:
        raise CaptureError(f"profile is not declared in deployment-info: {name}") from error
    if not isinstance(profile, dict):
        raise CaptureError(f"deployment-info profile is not an object: {name}")
    paths = {}
    for field in ("home", "config_file", "skills_directory"):
        if field not in profile:
            raise CaptureError(f"deployment-info profile is missing {field}: {name}")
        paths[field] = absolute_path(profile[field], f"profile {field}")
    return paths


def parse_source_spec(value: str) -> tuple[str, Path]:
    if "=" not in value:
        raise CaptureError("--source must be LABEL=PATH")
    label, raw_path = value.split("=", 1)
    safe_component(label, "source label")
    if label.lower() in {"runtime", "deployed", "manifest", "sources"}:
        raise CaptureError(f"reserved source label: {label}")
    if not raw_path:
        raise CaptureError(f"source path is empty for label {label}")
    return label, absolute_path(raw_path, f"source {label}")


def validate_source_path(path: Path) -> tuple[str, os.stat_result]:
    parent_fd, name = open_absolute_parent(path)
    try:
        item = stat_at(parent_fd, name)
        if stat.S_ISLNK(item.st_mode):
            raise CaptureError(f"source root may not be a symlink: {path}")
        if not (stat.S_ISREG(item.st_mode) or stat.S_ISDIR(item.st_mode)):
            raise CaptureError(f"source root is not a regular file or directory: {path}")
        return ("directory" if stat.S_ISDIR(item.st_mode) else "file", item)
    finally:
        os.close(parent_fd)


def git_run(repo: Path, args: list[bytes], *, check: bool = True) -> subprocess.CompletedProcess:
    command = [
        b"git", b"--no-optional-locks", b"-C", os.fsencode(str(repo)),
        b"-c", b"core.fsmonitor=false", *args,
    ]
    environment = os.environ.copy()
    for name in tuple(environment):
        if (
            name in {
                "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
                "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES",
                "GIT_CEILING_DIRECTORIES", "GIT_DISCOVERY_ACROSS_FILESYSTEM",
                "GIT_CONFIG", "GIT_CONFIG_GLOBAL", "GIT_CONFIG_SYSTEM", "GIT_CONFIG_PARAMETERS",
            }
            or name.startswith(("GIT_CONFIG_", "GIT_TRACE"))
        ):
            environment.pop(name)
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    environment["LC_ALL"] = "C"
    environment.pop("LANGUAGE", None)
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=environment, check=False)
    except OSError as error:
        raise CaptureError("git could not be executed for selected source") from error
    if check and result.returncode != 0:
        raise CaptureError(f"git metadata query failed for {repo} (exit {result.returncode})")
    return result


def git_output(repo: Path, *args: bytes) -> bytes:
    return git_run(repo, list(args)).stdout


def has_git_metadata_ancestor(path: Path) -> bool:
    probe = path if path.is_dir() else path.parent
    while True:
        try:
            path_stat(probe / ".git")
        except FileNotFoundError:
            pass
        else:
            return True
        if probe.parent == probe:
            return False
        probe = probe.parent


def git_repo_for(path: Path) -> Path | None:
    probe = path if path.is_dir() else path.parent
    result = git_run(probe, [b"rev-parse", b"--show-toplevel"], check=False)
    if result.returncode == 0:
        try:
            root = Path(os.fsdecode(result.stdout.rstrip(b"\n")))
            return Path(os.path.abspath(root))
        except (OSError, ValueError) as error:
            raise CaptureError(f"git returned an invalid repository root for {path}") from error
    if b"not a git repository" in result.stderr and not has_git_metadata_ancestor(path):
        return None
    raise CaptureError(f"git repository probe failed for selected source (exit {result.returncode})")


def source_pathspec(selected: Path, repo: Path) -> list[bytes]:
    if selected == repo:
        return []
    try:
        relative = selected.relative_to(repo).as_posix()
    except ValueError as error:
        raise CaptureError(f"selected source is outside discovered Git root: {selected}") from error
    if relative == ".":
        return []
    return [b"--", b":(literal)" + os.fsencode(relative)]


def git_status_records(raw: bytes, selected_rel: str) -> list[dict]:
    records = []
    fields = raw.split(b"\0")
    index = 0
    while index < len(fields):
        entry = fields[index]
        index += 1
        if not entry:
            continue
        if len(entry) < 4 or entry[2:3] != b" ":
            raise CaptureError("git returned malformed NUL-delimited status")
        code = os.fsdecode(entry[:2])
        path = os.fsdecode(entry[3:])
        original = None
        if "R" in code or "C" in code:
            if index >= len(fields):
                raise CaptureError("git returned incomplete rename status")
            original = os.fsdecode(fields[index])
            index += 1
        local_path = source_local_path(path, selected_rel)
        record = {"index": code[0], "worktree": code[1], "path": local_path}
        if original is not None:
            record["original_path"] = source_local_path(original, selected_rel)
        records.append(record)
    return records


def source_local_path(path: str, selected_rel: str) -> str:
    if not selected_rel:
        return path
    directory = path.endswith("/")
    normalized = path[:-1] if directory else path
    if normalized == selected_rel:
        local = Path(normalized).name
    else:
        selected = PurePosixPath(selected_rel)
        current = PurePosixPath(normalized)
        try:
            local = current.relative_to(selected).as_posix()
        except ValueError as error:
            raise CaptureError("git returned a path outside the selected source") from error
    return local + "/" if directory else local


def git_state(repo: Path, pathspec: list[bytes]) -> dict:
    head_result = git_run(repo, [b"rev-parse", b"--verify", b"HEAD"], check=False)
    if head_result.returncode == 0:
        head = os.fsdecode(head_result.stdout.strip())
    else:
        # Accept an unborn branch, but not a missing or malformed HEAD.
        git_dir = git_run(repo, [b"rev-parse", b"--git-dir"], check=False)
        head_ref = git_run(repo, [b"symbolic-ref", b"--quiet", b"HEAD"], check=False)
        if (
            git_dir.returncode != 0
            or head_ref.returncode != 0
            or b"Needed a single revision" not in head_result.stderr
        ):
            raise CaptureError(f"git HEAD query failed for {repo}")
        head = None
    branch_result = git_run(repo, [b"rev-parse", b"--abbrev-ref", b"HEAD"], check=False)
    branch = os.fsdecode(branch_result.stdout.strip()) if branch_result.returncode == 0 else None
    if branch_result.returncode not in {0, 128}:
        raise CaptureError(f"git branch query failed for {repo}")
    status = git_output(
        repo,
        b"status", b"--porcelain=v1", b"-z", b"--untracked-files=all", b"--ignore-submodules=none",
        *pathspec,
    )
    candidates = git_output(repo, b"ls-files", b"--cached", b"--others", b"--exclude-standard", b"-z", *pathspec)
    tracked = git_output(repo, b"ls-files", b"--cached", b"-z", *pathspec)
    ignored = git_output(
        repo,
        b"ls-files", b"--others", b"--ignored", b"--exclude-standard",
        b"--directory", b"--no-empty-directory", b"-z", *pathspec,
    )
    head_tree = b""
    if head:
        head_tree = git_output(repo, b"ls-tree", b"-r", b"-z", b"HEAD", *pathspec)
    return {
        "head": head,
        "branch": branch,
        "status_raw": status,
        "candidate_raw": candidates,
        "tracked_raw": tracked,
        "ignored_raw": ignored,
        "head_tree_raw": head_tree,
    }


def split_git_paths(raw: bytes) -> list[str]:
    return [os.fsdecode(item) for item in raw.split(b"\0") if item]


def head_tree_records(raw: bytes, selected_rel: str) -> list[dict]:
    result = []
    for entry in raw.split(b"\0"):
        if not entry:
            continue
        try:
            metadata, raw_path = entry.split(b"\t", 1)
            mode, object_type, object_id = metadata.split(b" ", 2)
        except ValueError as error:
            raise CaptureError("git returned malformed HEAD tree data") from error
        path = os.fsdecode(raw_path)
        local = source_local_path(path, selected_rel)
        result.append({"path": local, "mode": os.fsdecode(mode), "type": os.fsdecode(object_type), "object_id": os.fsdecode(object_id)})
    return result


def copy_git_source(
    label: str,
    selected: Path,
    repo: Path,
    stage_fd: int,
    files: list,
    skipped: list,
) -> dict:
    pathspec = source_pathspec(selected, repo)
    selected_rel = "" if selected == repo else selected.relative_to(repo).as_posix()
    before = git_state(repo, pathspec)
    candidate_relative = split_git_paths(before["candidate_raw"])
    tracked_paths = set(split_git_paths(before["tracked_raw"]))
    ignored_paths = set(split_git_paths(before["ignored_raw"]))
    for path in sorted(ignored_paths):
        local = source_local_path(path, selected_rel)
        skipped.append({"scope": "source:" + label, "path": local, "original_path": str(repo / path), "reason": "gitignored"})

    repo_fd = open_absolute_directory(repo)
    deleted = set()
    try:
        for repo_relative in sorted(set(candidate_relative)):
            local = source_local_path(repo_relative, selected_rel)
            original = repo / Path(repo_relative)
            reason = excluded_path_reason(repo_relative)
            if reason:
                skipped.append({"scope": "source:" + label, "path": local, "original_path": str(original), "reason": reason})
                continue
            parent_fd = os.dup(repo_fd)
            try:
                path_parts = PurePosixPath(repo_relative).parts
                try:
                    for component in path_parts[:-1]:
                        next_fd = os.open(component, fd_flags(directory=True), dir_fd=parent_fd)
                        os.close(parent_fd)
                        parent_fd = next_fd
                    item = stat_at(parent_fd, path_parts[-1])
                except (FileNotFoundError, NotADirectoryError):
                    if repo_relative in tracked_paths:
                        deleted.add(local)
                    continue
                if stat.S_ISLNK(item.st_mode):
                    skipped.append({"scope": "source:" + label, "path": local, "original_path": str(original), "reason": "symlink-not-followed"})
                    continue
                if not stat.S_ISREG(item.st_mode):
                    skipped.append({"scope": "source:" + label, "path": local, "original_path": str(original), "reason": "non-regular-file"})
                    continue
                digest, size = copy_file_at(
                    parent_fd, path_parts[-1], stage_fd, f"sources/{label}/{local}", source_path=str(original)
                )
                files.append({
                    "scope": "source:" + label,
                    "path": f"sources/{label}/{local}",
                    "original_path": str(original),
                    "sha256": digest,
                    "bytes": size,
                })
            finally:
                os.close(parent_fd)
    finally:
        os.close(repo_fd)

    status_records = git_status_records(before["status_raw"], selected_rel)
    deleted.update(
        item["path"] for item in status_records
        if "D" in (item["index"] + item["worktree"])
    )
    head_files = head_tree_records(before["head_tree_raw"], selected_rel)
    after = git_state(repo, pathspec)
    comparable = ("head", "branch", "status_raw", "candidate_raw", "tracked_raw")
    if any(before[field] != after[field] for field in comparable):
        raise CaptureError(f"Git HEAD or scoped status changed during capture: {label}")
    return {
        "repo_root": str(repo),
        "head": before["head"],
        "branch": before["branch"],
        "status": status_records,
        "head_files": head_files,
        "deleted_tracked_paths": sorted(deleted),
    }


def copy_explicit_source(label: str, path: Path, stage_fd: int, files: list, skipped: list) -> dict:
    kind, _ = validate_source_path(path)
    root_reason = excluded_path_reason(str(path), is_directory=kind == "directory")
    if root_reason:
        skipped.append({
            "scope": "source:" + label,
            "path": path.name,
            "original_path": str(path),
            "reason": root_reason,
        })
        return {"label": label, "path": str(path), "destination": f"sources/{label}", "git": None}
    try:
        repo = git_repo_for(path)
    except OSError as error:
        raise CaptureError(f"cannot inspect Git state for source {label}") from error
    if repo is not None:
        git_info = copy_git_source(label, path, repo, stage_fd, files, skipped)
    else:
        git_info = None
        if kind == "file":
            copy_file_path(
                path,
                stage_fd,
                f"sources/{label}/{path.name}",
                scope="source:" + label,
                files=files,
                skipped=skipped,
            )
        else:
            copied = copy_tree_path(
                path,
                stage_fd,
                destination_prefix=f"sources/{label}",
                scope="source:" + label,
                files=files,
                skipped=skipped,
            )
            if not copied:
                raise CaptureError(f"source directory could not be captured: {path}")
    return {"label": label, "path": str(path), "destination": f"sources/{label}", "git": git_info}


def _deployed_walk(
    directory_fd: int,
    actual_path: Path,
    display_prefix: str,
    *,
    active: set[tuple[int, int]],
    all_files: dict,
    skipped: list,
    discrepancies: list,
) -> None:
    info = os.fstat(directory_fd)
    identity = (info.st_dev, info.st_ino)
    if identity in active:
        skipped.append({"scope": "deployed", "path": display_prefix, "original_path": str(actual_path), "reason": "store-symlink-cycle"})
        discrepancies.append(f"symlink cycle encountered at {display_prefix}")
        return
    active.add(identity)
    try:
        for name in sorted(os.listdir(directory_fd)):
            display = relative_join(display_prefix, name)
            try:
                item = stat_at(directory_fd, name)
            except FileNotFoundError:
                raise CaptureError(f"deployed skill entry disappeared during inventory: {actual_path / name}")
            is_directory = stat.S_ISDIR(item.st_mode)
            reason = excluded_path_reason(display, is_directory=is_directory)
            if reason:
                skipped.append({"scope": "deployed", "path": display, "original_path": str(actual_path / name), "reason": reason})
                continue
            if stat.S_ISLNK(item.st_mode):
                try:
                    resolved = _store_resolved_path(actual_path / name)
                    target_stat = os.stat(resolved, follow_symlinks=False)
                except (CaptureError, OSError) as error:
                    skipped.append({"scope": "deployed", "path": display, "original_path": str(actual_path / name), "reason": "non-store-symlink-not-followed"})
                    discrepancies.append(f"non-store or unresolved symlink skipped at {display}")
                    continue
                if stat.S_ISDIR(target_stat.st_mode):
                    target_fd = open_absolute_directory(resolved)
                    try:
                        _deployed_walk(
                            target_fd,
                            resolved,
                            display,
                            active=active,
                            all_files=all_files,
                            skipped=skipped,
                            discrepancies=discrepancies,
                        )
                    finally:
                        os.close(target_fd)
                elif stat.S_ISREG(target_stat.st_mode):
                    data, digest, resolved_file = read_regular_path(resolved)
                    all_files[display] = {"sha256": digest, "bytes": len(data), "original_path": str(resolved_file)}
                else:
                    skipped.append({"scope": "deployed", "path": display, "original_path": str(actual_path / name), "reason": "non-regular-store-target"})
                    discrepancies.append(f"non-regular store link skipped at {display}")
                continue
            if stat.S_ISDIR(item.st_mode):
                child_fd = os.open(name, fd_flags(directory=True), dir_fd=directory_fd)
                try:
                    _deployed_walk(
                        child_fd,
                        actual_path / name,
                        display,
                        active=active,
                        all_files=all_files,
                        skipped=skipped,
                        discrepancies=discrepancies,
                    )
                finally:
                    os.close(child_fd)
                continue
            if not stat.S_ISREG(item.st_mode):
                raise CaptureError(f"unexpected non-regular deployed skill file: {actual_path / name}")
            fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0), dir_fd=directory_fd)
            try:
                data, digest = read_stable_fd(fd, source=str(actual_path / name))
            finally:
                os.close(fd)
            all_files[display] = {"sha256": digest, "bytes": len(data), "original_path": str(actual_path / name)}
    finally:
        active.remove(identity)


def inventory_deployed(external_dirs: list[Path], skipped: list) -> dict:
    result = {"directories": [], "bundles": [], "discrepancies": []}
    for external in external_dirs:
        try:
            resolved = regular_path_metadata(external, allow_store_link=True)
            external_fd = open_absolute_directory(resolved)
        except FileNotFoundError as error:
            raise CaptureError(f"configured deployed skill directory is missing: {external}") from error
        files = {}
        try:
            _deployed_walk(
                external_fd,
                resolved,
                "",
                active=set(),
                all_files=files,
                skipped=skipped,
                discrepancies=result["discrepancies"],
            )
        finally:
            os.close(external_fd)
        result["directories"].append({"path": str(external), "resolved_path": str(resolved)})
        skill_files = sorted(path for path in files if PurePosixPath(path).name == "SKILL.md")
        if not skill_files:
            result["discrepancies"].append(f"no SKILL.md bundles found in {external}")
        for skill_path in skill_files:
            bundle_rel = str(PurePosixPath(skill_path).parent)
            if bundle_rel == ".":
                bundle_rel = ""
            prefix = bundle_rel + "/" if bundle_rel else ""
            bundle_file_map = {
                path[len(prefix):]: value
                for path, value in sorted(files.items())
                if path == bundle_rel or not prefix or path.startswith(prefix)
            }
            parts = PurePosixPath(bundle_rel).parts if bundle_rel else ()
            result["bundles"].append({
                "name": parts[-1] if parts else external.name,
                "category": parts[0] if len(parts) > 1 else None,
                "path": str(external / bundle_rel) if bundle_rel else str(external),
                "files": bundle_file_map,
            })
    return result


def compare_source_skills(files: list, deployed: dict, selected_sources: dict) -> tuple[list[dict], int]:
    deployed_by_name: dict[str, list[dict]] = {}
    for bundle in deployed["bundles"]:
        deployed_by_name.setdefault(bundle["name"], []).append(bundle)

    source_bundles: dict[tuple[str, str], dict] = {}
    for item in files:
        scope = item["scope"]
        if not scope.startswith("source:") or PurePosixPath(item["path"]).name != "SKILL.md":
            continue
        label = scope.removeprefix("source:")
        prefix = PurePosixPath("sources") / label
        relative = PurePosixPath(item["path"]).relative_to(prefix)
        bundle_path = relative.parent
        parts = bundle_path.parts
        if str(bundle_path) == ".":
            selected_root, kind = selected_sources[label]
            name = selected_root.name if kind == "directory" else selected_root.parent.name
            category = None
        else:
            name = parts[-1]
            category = parts[0] if len(parts) > 1 else None
        key = (label, bundle_path.as_posix())
        source_bundles[key] = {
            "label": label,
            "path": bundle_path.as_posix(),
            "name": name,
            "category": category,
        }

    comparisons = []
    difference_count = 0
    for (label, bundle_path), source_bundle in sorted(source_bundles.items()):
        named = deployed_by_name.get(source_bundle["name"], [])
        category = source_bundle["category"]
        exact = [bundle for bundle in named if category is not None and bundle["category"] == category]
        candidates = exact if exact else named if len(named) == 1 else []
        if len(candidates) != 1:
            state = "ambiguous" if len(named) > 1 else "not-deployed"
            if state == "ambiguous":
                difference_count += 1
            comparison = {**source_bundle, "match": state, "differences": []}
            if state == "not-deployed":
                source_prefix = f"sources/{label}/" + ("" if bundle_path == "." else f"{bundle_path}/")
                comparison["differences"] = [
                    {"path": item["path"][len(source_prefix):], "status": "missing-from-deployed", "source_sha256": item["sha256"]}
                    for item in files
                    if item["scope"] == "source:" + label and item["path"].startswith(source_prefix)
                ]
                difference_count += len(comparison["differences"])
            comparisons.append(comparison)
            continue

        deployed_bundle = candidates[0]
        source_prefix = f"sources/{label}/" + ("" if bundle_path == "." else f"{bundle_path}/")
        source_files = {
            item["path"][len(source_prefix):]: item
            for item in files
            if item["scope"] == "source:" + label and item["path"].startswith(source_prefix)
        }
        deployed_files = deployed_bundle["files"]
        differences = []
        for relative_path in sorted(set(source_files) | set(deployed_files)):
            source_file = source_files.get(relative_path)
            deployed_file = deployed_files.get(relative_path)
            if source_file is None:
                differences.append({
                    "path": relative_path,
                    "status": "missing-from-source",
                    "deployed_sha256": deployed_file["sha256"],
                })
            elif deployed_file is None:
                differences.append({
                    "path": relative_path,
                    "status": "missing-from-deployed",
                    "source_sha256": source_file["sha256"],
                })
            elif source_file["sha256"] != deployed_file["sha256"]:
                differences.append({
                    "path": relative_path,
                    "status": "changed",
                    "source_sha256": source_file["sha256"],
                    "deployed_sha256": deployed_file["sha256"],
                })
        difference_count += len(differences)
        comparisons.append({
            **source_bundle,
            "match": "matched",
            "deployed_path": deployed_bundle["path"],
            "same_file_count": len(set(source_files) & set(deployed_files)) - sum(
                difference["status"] == "changed" for difference in differences
            ),
            "differences": differences,
        })
    return comparisons, difference_count




def load_live_config(path: Path) -> tuple[dict, str, str]:
    try:
        raw, digest, resolved = read_regular_path(path, allow_store_link=True)
        import hermes_yaml as yaml

        config = yaml.safe_load(raw)
    except CaptureError:
        raise
    except Exception as error:
        # Parser errors can contain config excerpts; report only path and safe error type.
        raise CaptureError(f"live Hermes config {path} could not be parsed by Hermes YAML ({type(error).__name__})") from error
    if not isinstance(config, dict):
        raise CaptureError("live Hermes config must contain a YAML mapping")
    return config, digest, str(resolved)


def inspect_external_directory(path: Path) -> tuple[Path | None, str | None]:
    """Validate configured dirs without resolving mutable symlinks."""
    current = os.open(path.anchor, fd_flags(directory=True))
    try:
        components = path.parts[1:]
        for index, component in enumerate(components):
            try:
                item = stat_at(current, component)
            except FileNotFoundError:
                return None, "missing"
            if stat.S_ISLNK(item.st_mode):
                if index != len(components) - 1:
                    return None, "unsafe-symlink"
                try:
                    resolved = _store_resolved_path(path)
                except (CaptureError, OSError):
                    return None, "unsafe-symlink"
                try:
                    resolved_fd = open_absolute_directory(resolved)
                except FileNotFoundError:
                    return None, "missing"
                except NotADirectoryError:
                    return None, "not-directory"
                else:
                    os.close(resolved_fd)
                    return resolved, None
            if not stat.S_ISDIR(item.st_mode):
                return None, "not-directory"
            child = os.open(component, fd_flags(directory=True), dir_fd=current)
            os.close(current)
            current = child
        return path, None
    finally:
        os.close(current)


def configured_external_dirs(
    config: dict, home: Path, skipped: list
) -> tuple[list[Path], list[Path], list[Path], list[str]]:
    """Mirror Hermes scalar/list expansion while retaining no-follow provenance."""
    skills = config.get("skills")
    if not isinstance(skills, dict):
        return [], [], [], ["live skills config is not a mapping"]
    entries = skills.get("external_dirs")
    if isinstance(entries, str):
        entries = [entries]
    elif not isinstance(entries, list):
        if entries is not None:
            return [], [], [], ["live skills.external_dirs has an unsupported value"]
        entries = []

    configured: list[Path] = []
    usable: list[Path] = []
    usable_resolved: list[Path] = []
    discrepancies: list[str] = []
    seen: set[Path] = set()
    local_skills = Path(os.path.abspath(home / "skills"))
    for entry in entries:
        expanded = os.path.expanduser(os.path.expandvars(str(entry).strip()))
        if not expanded:
            continue
        path = Path(expanded)
        if not path.is_absolute():
            path = home / path
        path = Path(os.path.abspath(path))
        configured.append(path)
        if path == local_skills:
            continue
        try:
            resolved, issue = inspect_external_directory(path)
        except ValueError:
            resolved, issue = None, "invalid-path"
        if issue:
            reason = {
                "missing": "configured-skill-directory-missing",
                "unsafe-symlink": "unsafe-symlink-skill-directory",
                "not-directory": "configured-skill-path-not-directory",
                "invalid-path": "configured-skill-directory-invalid",
            }[issue]
            skipped.append({
                "scope": "deployed",
                "path": str(path),
                "original_path": str(path),
                "reason": reason,
            })
            discrepancies.append(f"configured external skill directory {issue} at {path}")
            continue
        if resolved is None or resolved == local_skills:
            continue
        if resolved in seen:
            continue
        seen.add(resolved)
        usable.append(path)
        usable_resolved.append(resolved)
    return configured, usable, usable_resolved, discrepancies


def read_captured_skill_ledger(stage_fd: int, files: list) -> bytes | None:
    relative = "runtime/skills/.curator_ledger.jsonl"
    record = next((item for item in files if item["path"] == relative), None)
    if record is None:
        return None
    skills_fd = open_destination_directory(stage_fd, "runtime/skills", create=False)
    try:
        try:
            fd = os.open(
                ".curator_ledger.jsonl",
                os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0),
                dir_fd=skills_fd,
            )
        except OSError as error:
            raise CaptureError("captured skill mutation ledger could not be read safely") from error
        try:
            data, digest = read_stable_fd(fd, source=relative)
        finally:
            os.close(fd)
    finally:
        os.close(skills_fd)
    if digest != record["sha256"]:
        raise CaptureError("captured skill mutation ledger changed after staging")
    return data


def parse_skill_history_ledger(data: bytes, home: Path) -> tuple[set[str], set[str]]:
    """Return permitted and permanently credential-denied blob hashes."""
    try:
        text = data.decode("utf-8-sig")
        permitted: set[str] = set()
        denied: set[str] = set()
        required = {"id", "ts", "actor", "action", "skill", "evidence", "before", "after"}
        for line in text.splitlines():
            if not line.strip():
                continue
            entry = json.loads(line)
            if not isinstance(entry, dict) or set(entry) != required:
                raise ValueError
            if (
                not isinstance(entry["id"], str)
                or not re.fullmatch(r"[0-9a-f]{12}", entry["id"])
                or not isinstance(entry["ts"], str)
                or not isinstance(entry["actor"], str)
                or entry["actor"] not in {"curator", "agent", "user"}
                or not isinstance(entry["action"], str)
                or not isinstance(entry["skill"], str)
                or not entry["skill"]
                or not isinstance(entry["evidence"], dict)
            ):
                raise ValueError
            timestamp = dt.datetime.fromisoformat(entry["ts"])
            if timestamp.tzinfo is None or timestamp.utcoffset() is None:
                raise ValueError
            skill_is_credential = has_credential_path_component(entry["skill"])
            for section in ("before", "after"):
                references = entry[section]
                if not isinstance(references, list):
                    raise ValueError
                for reference in references:
                    if not isinstance(reference, dict) or set(reference) != {"path", "sha256"}:
                        raise ValueError
                    path = reference["path"]
                    digest = reference["sha256"]
                    if (
                        not isinstance(path, str)
                        or not path
                        or "\x00" in path
                        or not Path(path).is_absolute()
                        or os.path.normpath(path) != path
                        or any(part in {".", ".."} for part in path.split("/")[1:])
                        or not is_beneath(Path(path), home)
                        or Path(path) == home
                        or not isinstance(digest, str)
                        or not re.fullmatch(r"[0-9a-f]{64}", digest)
                    ):
                        raise ValueError
                    is_credential = skill_is_credential or has_credential_path_component(path)
                    (denied if is_credential else permitted).add(digest)
        return permitted - denied, denied
    except Exception:
        raise CaptureError(
            "captured skill mutation ledger is malformed; refusing unverifiable history"
        ) from None


def capture_skill_history(
    home: Path, stage_fd: int, files: list, skipped: list
) -> dict:
    ledger_data = read_captured_skill_ledger(stage_fd, files)
    ledger_skip = next(
        (
            item for item in skipped
            if item["scope"] == "runtime:skills"
            and item["path"] in {
                "runtime/skills",
                "runtime/skills/.curator_ledger.jsonl",
            }
        ),
        None,
    )
    ledger_status = (
        "captured" if ledger_data is not None else ("unavailable" if ledger_skip else "missing")
    )
    if ledger_data is None:
        permitted: set[str] = set()
        denied: set[str] = set()
        omission_reason = (
            "ledger-unavailable-unverifiable-history"
            if ledger_skip
            else "ledger-missing-unverifiable-history"
        )
    else:
        permitted, denied = parse_skill_history_ledger(ledger_data, home)
        omission_reason = "unreferenced-history-blob"

    blob_root = home / ".curator_backups" / "blobs"
    empty_result = {
        "ledger_status": ledger_status,
        "referenced_blob_count": len(permitted | denied),
        "credential_blocked_blob_count": len(denied),
        "captured_blob_count": 0,
    }

    def omit_unavailable(reason: str) -> dict:
        skipped.append({
            "scope": "runtime:skill-history",
            "path": "runtime/skill-history",
            "original_path": str(blob_root),
            "reason": reason,
        })
        if ledger_data is None:
            skipped.append({
                "scope": "runtime:skill-history",
                "path": "runtime/skill-history",
                "original_path": str(blob_root),
                "reason": omission_reason,
            })
        return empty_result

    try:
        parent_fd, name = open_absolute_parent(blob_root)
    except FileNotFoundError:
        if permitted:
            raise CaptureError("ledger-referenced skill history blobs are unavailable")
        return omit_unavailable("history-blob-directory-missing")
    try:
        try:
            root_info = stat_at(parent_fd, name)
        except FileNotFoundError:
            if permitted:
                raise CaptureError("ledger-referenced skill history blobs are unavailable")
            return omit_unavailable("history-blob-directory-missing")
        if stat.S_ISLNK(root_info.st_mode):
            if permitted:
                raise CaptureError("ledger-referenced skill history directory is an unsafe symlink")
            return omit_unavailable("unsafe-history-blob-directory-symlink")
        if not stat.S_ISDIR(root_info.st_mode):
            if permitted:
                raise CaptureError("ledger-referenced skill history directory is not a directory")
            return omit_unavailable("history-blob-directory-not-directory")
        blob_fd = os.open(name, fd_flags(directory=True), dir_fd=parent_fd)
    finally:
        os.close(parent_fd)

    copied: set[str] = set()
    try:
        for name in sorted(os.listdir(blob_fd)):
            destination = f"runtime/skill-history/{name}"
            original = blob_root / name
            if not re.fullmatch(r"[0-9a-f]{64}", name):
                reason = "invalid-content-addressed-history-blob-name"
            elif ledger_data is None:
                reason = omission_reason
            elif name in denied:
                reason = "credential-referenced-history-blob"
            elif name not in permitted:
                reason = "unreferenced-history-blob"
            else:
                reason = None
            if reason:
                skipped.append({
                    "scope": "runtime:skill-history",
                    "path": destination,
                    "original_path": str(original),
                    "reason": reason,
                })
                continue
            file_count = len(files)
            copy_file_path(
                original,
                stage_fd,
                destination,
                scope="runtime:skill-history",
                files=files,
                skipped=skipped,
            )
            record = next(
                (item for item in files[file_count:] if item["path"] == destination),
                None,
            )
            if record is None:
                raise CaptureError("ledger-referenced skill history blob could not be copied safely")
            if record["sha256"] != name:
                raise CaptureError("skill history blob failed content-address verification")
            copied.add(name)
    finally:
        os.close(blob_fd)
    if permitted - copied:
        raise CaptureError("one or more ledger-referenced skill history blobs are unavailable")
    if ledger_data is None:
        skipped.append({
            "scope": "runtime:skill-history",
            "path": "runtime/skill-history",
            "original_path": str(blob_root),
            "reason": omission_reason,
        })
    return {
        "ledger_status": ledger_status,
        "referenced_blob_count": len(permitted | denied),
        "credential_blocked_blob_count": len(denied),
        "captured_blob_count": len(copied),
    }


def write_manifest(stage_fd: int, manifest: dict) -> None:
    encoded = (json.dumps(manifest, ensure_ascii=True, indent=2, sort_keys=True) + "\n").encode("utf-8")
    fd = os.open(
        "manifest.json",
        os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
        0o600,
        dir_fd=stage_fd,
    )
    try:
        os.fchmod(fd, 0o600)
        view = memoryview(encoded)
        while view:
            written = os.write(fd, view)
            view = view[written:]
        os.fsync(fd)
    finally:
        os.close(fd)


def remove_tree_at(parent_fd: int, name: str, expected: tuple[int, int] | None = None) -> None:
    try:
        item = stat_at(parent_fd, name)
    except FileNotFoundError:
        return
    identity = (item.st_dev, item.st_ino)
    if expected is not None and identity != expected:
        return
    if stat.S_ISDIR(item.st_mode) and not stat.S_ISLNK(item.st_mode):
        child_fd = os.open(name, fd_flags(directory=True), dir_fd=parent_fd)
        try:
            opened = os.fstat(child_fd)
            if (opened.st_dev, opened.st_ino) != identity:
                return
            for child in os.listdir(child_fd):
                remove_tree_at(child_fd, child)
        finally:
            os.close(child_fd)
        try:
            current = stat_at(parent_fd, name)
        except FileNotFoundError:
            return
        if (current.st_dev, current.st_ino) != identity:
            return
        try:
            os.rmdir(name, dir_fd=parent_fd)
        except FileNotFoundError:
            pass
    else:
        try:
            current = stat_at(parent_fd, name)
        except FileNotFoundError:
            return
        if (current.st_dev, current.st_ino) != identity:
            return
        try:
            os.unlink(name, dir_fd=parent_fd)
        except FileNotFoundError:
            pass


def output_parent(path: Path) -> tuple[int, str]:
    path = Path(os.path.abspath(path))
    if path.name in {"", ".", ".."}:
        raise CaptureError("output must name a new directory")
    parent = path.parent
    current = os.open(parent.anchor, fd_flags(directory=True))
    try:
        for component in parent.parts[1:]:
            try:
                child = os.open(component, fd_flags(directory=True), dir_fd=current)
            except FileNotFoundError:
                try:
                    os.mkdir(component, mode=0o700, dir_fd=current)
                except FileExistsError:
                    pass
                child = os.open(component, fd_flags(directory=True), dir_fd=current)
            os.close(current)
            current = child
        return current, path.name
    except BaseException:
        os.close(current)
        raise


def publish_snapshot(
    parent_fd: int,
    output_name: str,
    stage_name: str,
    stage_identity: tuple[int, int],
) -> tuple[int, tuple[int, int]]:
    staging_fd = os.open(stage_name, fd_flags(directory=True), dir_fd=parent_fd)
    final_fd = -1
    identity = None
    try:
        staging_stat = os.fstat(staging_fd)
        if stage_identity != (staging_stat.st_dev, staging_stat.st_ino):
            raise CaptureError("private staging directory changed before publication")
        entries = sorted(os.listdir(staging_fd), key=lambda entry: (entry == "manifest.json", entry))
        if "manifest.json" not in entries:
            raise CaptureError("private staging manifest is missing")
        try:
            os.mkdir(output_name, mode=0o700, dir_fd=parent_fd)
        except FileExistsError as error:
            raise CaptureError(f"output already exists; refusing to overwrite: {output_name}") from error
        created_stat = stat_at(parent_fd, output_name)
        identity = (created_stat.st_dev, created_stat.st_ino)
        final_fd = os.open(output_name, fd_flags(directory=True), dir_fd=parent_fd)
        opened_stat = os.fstat(final_fd)
        if identity != (opened_stat.st_dev, opened_stat.st_ino):
            raise CaptureError("output directory changed during exclusive creation")
        os.fchmod(final_fd, 0o700)
        for entry in entries:
            os.rename(entry, entry, src_dir_fd=staging_fd, dst_dir_fd=final_fd)
        os.fsync(final_fd)
        os.fsync(parent_fd)
        return final_fd, identity
    except BaseException:
        if final_fd >= 0:
            os.close(final_fd)
        if identity is not None:
            remove_tree_at(parent_fd, output_name, identity)
        raise
    finally:
        os.close(staging_fd)





def capture_profile(
    deployment_info_path: Path,
    *,
    profile: str = "default",
    source_specs: list[str] | None = None,
    output: Path | None = None,
    hostname: str | None = None,
) -> dict:
    started_at = utc_now()
    deployment_info_path = Path(os.path.abspath(deployment_info_path))
    info = read_deployment_info(deployment_info_path)
    paths = profile_paths(info, profile)
    home = paths["home"]
    home_fd = open_absolute_directory(home)
    os.close(home_fd)
    declared_config = paths["config_file"]
    declared_skills = paths["skills_directory"]
    _, declared_config_hash, declared_config_resolved_text = read_regular_path(declared_config, allow_store_link=True)
    declared_config_resolved = Path(declared_config_resolved_text)
    config_path = home / "config.yaml"
    config, live_config_hash, live_config_resolved = load_live_config(config_path)
    external_dir_skipped: list = []
    configured_skills, actual_skills, actual_skills_resolved, external_dir_discrepancies = (
        configured_external_dirs(config, home, external_dir_skipped)
    )
    declared_skills_resolved = regular_path_metadata(declared_skills, allow_store_link=True)

    source_pairs = [parse_source_spec(spec) for spec in (source_specs or [])]
    labels = [label for label, _ in source_pairs]
    if len(labels) != len(set(labels)):
        raise CaptureError("source labels must be unique")
    selected_sources = {
        label: (path, validate_source_path(path)[0])
        for label, path in source_pairs
    }

    hostname = hostname or socket.gethostname()
    safe_hostname = safe_component(hostname, "hostname")
    if output is None:
        state_home = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
        state_root = absolute_path(state_home, "XDG_STATE_HOME")
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + secrets.token_hex(4)
        output = state_root / "hermes" / "captures" / safe_hostname / profile / stamp
    else:
        output = Path(os.path.abspath(output))

    inputs = [
        deployment_info_path,
        home,
        declared_config,
        declared_config_resolved,
        config_path,
        Path(live_config_resolved),
        declared_skills,
        declared_skills_resolved,
        *configured_skills,
        *actual_skills_resolved,
    ]
    inputs.extend(path for _, path in source_pairs)
    for source in inputs:
        if paths_overlap(output, Path(os.path.abspath(source))):
            raise CaptureError(f"output overlaps an input path: {output}")

    parent_fd, output_name = output_parent(output)
    stage_name = ".hermes-capture-" + secrets.token_hex(16)
    stage_fd = -1
    stage_identity = None
    final_fd = -1
    final_identity = None
    published = False
    try:
        try:
            stat_at(parent_fd, output_name)
        except FileNotFoundError:
            pass
        else:
            raise CaptureError(f"output already exists; refusing to overwrite: {output}")
        try:
            os.mkdir(stage_name, mode=0o700, dir_fd=parent_fd)
        except FileExistsError as error:
            raise CaptureError("could not allocate private staging directory") from error
        stage_stat = stat_at(parent_fd, stage_name)
        stage_identity = (stage_stat.st_dev, stage_stat.st_ino)
        stage_fd = os.open(stage_name, fd_flags(directory=True), dir_fd=parent_fd)
        opened_stage = os.fstat(stage_fd)
        if stage_identity != (opened_stage.st_dev, opened_stage.st_ino):
            raise CaptureError("private staging directory changed during creation")
        os.fchmod(stage_fd, 0o700)
        files = []
        skipped = list(external_dir_skipped)

        copy_tree_path(
            home / "skills",
            stage_fd,
            destination_prefix="runtime/skills",
            scope="runtime:skills",
            files=files,
            skipped=skipped,
        )
        skill_history = capture_skill_history(home, stage_fd, files, skipped)
        copy_tree_path(
            home / "memories",
            stage_fd,
            destination_prefix="runtime/memories",
            scope="runtime:memories",
            files=files,
            skipped=skipped,
        )
        soul = home / "SOUL.md"
        if path_exists_nofollow(soul):
            copy_file_path(soul, stage_fd, "runtime/SOUL.md", scope="runtime:SOUL.md", files=files, skipped=skipped)

        sources = []
        for label, path in source_pairs:
            sources.append(copy_explicit_source(label, path, stage_fd, files, skipped))

        deployed = inventory_deployed(actual_skills, skipped)
        deployed["discrepancies"].extend(external_dir_discrepancies)
        source_vs_deployed, source_skill_difference_count = compare_source_skills(
            files, deployed, selected_sources
        )
        configured_matches = (
            len(actual_skills_resolved) == 1
            and actual_skills_resolved[0] == declared_skills_resolved
            and not external_dir_discrepancies
        )
        drift = {
            "config_matches_declared": live_config_hash == declared_config_hash,
            "configured_live_config_sha256": live_config_hash,
            "declared_config_sha256": declared_config_hash,
            "live_config_path": str(config_path),
            "live_config_resolved_path": live_config_resolved,
            "declared_config_path": str(declared_config),
            "skill_directories_match_declared": configured_matches,
            "deployed_skill_discrepancies": deployed["discrepancies"],
            "source_skill_differences": source_skill_difference_count,
        }
        completed_at = utc_now()
        provenance = {
            "package": info["package"],
            "hermes_revision": info.get("hermes_revision"),
            "agent_profiles_revision": info.get("agent_profiles_revision"),
            "deployment_info_schema_version": info["schema_version"],
        }
        if "source_revisions" in info:
            provenance["source_revisions"] = info["source_revisions"]
        live_config_version = config.get("_config_version")
        if not isinstance(live_config_version, int) or isinstance(live_config_version, bool):
            live_config_version = None
        manifest = {
            "format": FORMAT,
            "format_version": FORMAT_VERSION,
            "snapshot_path": str(output),
            "started_at": started_at,
            "completed_at": completed_at,
            "hostname": hostname,
            "profile": profile,
            "home": str(home),
            "promotion": False,
            "review_only": True,
            "consistency": "per-file stable reads; live runtime state may change between files",
            "snapshot_scopes": {
                "runtime": "mutable profile files copied for review",
                "sources": "explicitly selected source working trees copied for review",
                "deployed": "immutable skill views inventoried by hash and never copied",
            },
            "provenance": provenance,
            "configured_skill_directory": str(declared_skills),
            "configured_skill_directories": [str(path) for path in configured_skills],
            "actual_skill_directories": [str(path) for path in actual_skills],
            "skill_history": skill_history,
            "live_config_version": live_config_version,
            "drift": drift,
            "files": sorted(files, key=lambda item: item["path"]),
            "skipped": sorted(skipped, key=lambda item: (item["scope"], item["path"], item["reason"])),
            "sources": sources,
            "deployed_skills": deployed,
            "source_vs_deployed": source_vs_deployed,
            "summary": {
                "captured_files": len(files),
                "captured_bytes": sum(item["bytes"] for item in files),
                "skipped_entries": len(skipped),
                "source_count": len(sources),
                "deployed_skill_count": len(deployed["bundles"]),
                "source_skill_difference_count": source_skill_difference_count,
                "drift_mismatches": (
                    int(not drift["config_matches_declared"])
                    + int(not configured_matches)
                    + len(deployed["discrepancies"])
                    + source_skill_difference_count
                ),
            },
        }
        write_manifest(stage_fd, manifest)
        os.fsync(stage_fd)
        final_fd, final_identity = publish_snapshot(parent_fd, output_name, stage_name, stage_identity)
        published = True
        os.close(final_fd)
        final_fd = -1
        return manifest
    except CaptureError:
        raise
    except (OSError, ValueError, TypeError, UnicodeError, subprocess.SubprocessError) as error:
        raise CaptureError(f"capture failed safely: {error}") from error
    finally:
        if final_fd >= 0:
            os.close(final_fd)
        if stage_fd >= 0:
            os.close(stage_fd)
        if not published and final_identity is not None:
            remove_tree_at(parent_fd, output_name, final_identity)
        if stage_identity is not None:
            remove_tree_at(parent_fd, stage_name, stage_identity)
        os.close(parent_fd)




def path_exists_nofollow(path: Path) -> bool:
    try:
        path_stat(path)
        return True
    except FileNotFoundError:
        return False


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--deployment-info", required=True, type=Path, help="version-1 Hermes deployment-info JSON")
    parser.add_argument("--profile", default="default", help="declared profile name (default: default)")
    parser.add_argument("--source", action="append", default=[], metavar="LABEL=PATH", help="explicit source tree or file to capture")
    parser.add_argument("--output", type=Path, help="exact new snapshot directory; existing paths are never replaced")
    args = parser.parse_args(argv)
    try:
        manifest = capture_profile(
            args.deployment_info,
            profile=args.profile,
            source_specs=args.source,
            output=args.output,
        )
    except (CaptureError, OSError) as error:
        print(f"hermes-profile-capture: {error}", file=sys.stderr)
        return 1
    summary = manifest["summary"]
    mismatches = summary["drift_mismatches"]
    print(
        f"Created review-only capture: {manifest['snapshot_path']} "
        f"(files={summary['captured_files']}, bytes={summary['captured_bytes']}, "
        f"sources={summary['source_count']}, deployed_skills={summary['deployed_skill_count']}, "
        f"drift_mismatches={mismatches}, source_skill_differences={summary['source_skill_difference_count']})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

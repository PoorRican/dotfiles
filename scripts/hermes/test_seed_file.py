"""Run with: python3 -m unittest discover -s scripts/hermes -p 'test_*.py'."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location("seed_file", Path(__file__).with_name("seed-file.py"))
seed = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(seed)


class SeedFileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / "snapshot"
        self.source.write_bytes(b"initial preference\n")
        self.destination = self.root / "runtime" / "memories" / "USER.md"

    def run_seed(self, **kwargs):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            seed.seed_file(self.source, self.destination, **kwargs)
        return output.getvalue()

    def test_seed_then_preserve_runtime_and_show_diff_only_when_verbose(self):
        self.run_seed()
        self.assertEqual(self.destination.read_bytes(), self.source.read_bytes())
        self.assertEqual(self.destination.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.destination.parent.stat().st_mode & 0o777, 0o700)
        self.destination.write_bytes(b"learned private preference\n")
        self.destination.chmod(0o640)
        before = self.destination.stat()
        normal = self.run_seed()
        verbose = self.run_seed(verbose=True)
        self.assertNotIn("learned private preference", normal)
        self.assertNotIn("initial preference", normal)
        self.assertIn("-initial preference", verbose)
        self.assertIn("+learned private preference", verbose)
        self.assertEqual(self.destination.read_bytes(), b"learned private preference\n")
        after = self.destination.stat()
        self.assertEqual((after.st_ino, after.st_mode, after.st_mtime_ns),
                         (before.st_ino, before.st_mode, before.st_mtime_ns))

    def test_missing_dry_run_creates_nothing_and_existing_dry_run_shows_diff(self):
        self.run_seed(dry_run=True, verbose=True)
        self.assertFalse(self.destination.parents[1].exists())
        self.destination.parent.mkdir(parents=True)
        self.destination.write_bytes(b"runtime only\n")
        before = self.destination.stat()
        output = self.run_seed(dry_run=True, verbose=True)
        self.assertIn("+runtime only", output)
        self.assertEqual(self.destination.read_bytes(), b"runtime only\n")
        self.assertEqual(self.destination.stat().st_mtime_ns, before.st_mtime_ns)
        self.assertEqual(set(self.destination.parent.iterdir()), {self.destination})

    def test_empty_existing_file_is_not_seeded(self):
        self.destination.parent.mkdir(parents=True)
        self.destination.touch()
        self.run_seed()
        self.assertEqual(self.destination.read_bytes(), b"")

    def test_competing_creator_wins_without_partial_seed_or_metadata_change(self):
        real_link = os.link
        winner = {}

        def competing_link(source, destination, **kwargs):
            self.destination.write_bytes(b"concurrent runtime\n")
            self.destination.chmod(0o640)
            winner["stat"] = self.destination.stat()
            return real_link(source, destination, **kwargs)

        with patch.object(seed.os, "link", side_effect=competing_link):
            self.run_seed()
        self.assertEqual(self.destination.read_bytes(), b"concurrent runtime\n")
        after = self.destination.stat()
        self.assertEqual((after.st_ino, after.st_mode, after.st_mtime_ns),
                         (winner["stat"].st_ino, winner["stat"].st_mode, winner["stat"].st_mtime_ns))
        self.assertEqual(set(self.destination.parent.iterdir()), {self.destination})

    def test_symlinks_and_special_destinations_are_preserved_without_following(self):
        self.destination.parent.mkdir(parents=True)
        target = self.root / "absent-target"
        self.destination.symlink_to(target)
        self.run_seed(verbose=True)
        self.assertTrue(self.destination.is_symlink())
        self.assertFalse(target.exists())
        self.destination.unlink()
        target.write_bytes(b"secret outside runtime")
        self.destination.symlink_to(target)
        self.assertNotIn("secret outside runtime", self.run_seed(verbose=True))
        self.assertEqual(target.read_bytes(), b"secret outside runtime")
        self.destination.unlink()
        os.mkfifo(self.destination)
        self.run_seed(verbose=True)
        self.assertTrue(self.destination.is_fifo())

    def test_symlink_parent_is_refused_without_writing_outside_runtime(self):
        outside = self.root / "outside"
        outside.mkdir()
        self.destination.parents[1].symlink_to(outside)
        with self.assertRaises((OSError, ValueError)):
            self.run_seed()
        self.assertEqual(list(outside.iterdir()), [])

    def test_parent_swap_cannot_redirect_publication_or_temporary_cleanup(self):
        self.destination.parent.mkdir(parents=True)
        outside = self.root / "outside"
        outside.mkdir()
        original_parent = self.root / "original-memories"
        real_open = os.open
        swapped = False

        def swapping_open(path, flags, mode=0o777, *, dir_fd=None):
            nonlocal swapped
            if flags & os.O_CREAT and Path(path).name.startswith(".hermes-seed-") and not swapped:
                self.destination.parent.rename(original_parent)
                self.destination.parent.symlink_to(outside)
                swapped = True
            return real_open(path, flags, mode, dir_fd=dir_fd)

        with patch.object(seed.os, "open", side_effect=swapping_open):
            self.run_seed()
        self.assertTrue(swapped)
        self.assertEqual(list(outside.iterdir()), [])
        anchored_destination = original_parent / self.destination.name
        self.assertEqual(anchored_destination.read_bytes(), self.source.read_bytes())
        self.assertEqual(list(original_parent.iterdir()), [anchored_destination])

    def test_failed_publication_leaves_no_destination_or_temporary_files(self):
        with patch.object(seed.os, "link", side_effect=PermissionError("publication denied")):
            with self.assertRaises(PermissionError):
                self.run_seed()
        self.assertFalse(self.destination.exists())
        self.assertEqual(list(self.destination.parent.iterdir()), [])

    def test_verbose_diff_reports_newline_only_difference_and_nontext(self):
        self.destination.parent.mkdir(parents=True)
        self.destination.write_bytes(b"initial preference")
        output = self.run_seed(verbose=True)
        self.assertIn("-initial preference", output)
        self.assertIn("+initial preference", output)
        self.assertIn("\\ No newline at end of file", output)
        self.destination.write_bytes(b"\xff\x00private bytes")
        output = self.run_seed(verbose=True)
        self.assertNotIn("private bytes", output)
        self.assertEqual(self.destination.read_bytes(), b"\xff\x00private bytes")

    def test_verbose_diff_uses_lf_boundaries_not_unicode_separators(self):
        self.source.write_text("old\u2028preference\n")
        self.destination.parent.mkdir(parents=True)
        self.destination.write_text("new\u2028preference\n")
        output = self.run_seed(verbose=True)
        self.assertNotIn("\\ No newline at end of file", output)
        self.assertIn("-old\u2028preference\n", output)
        self.assertIn("+new\u2028preference\n", output)


if __name__ == "__main__":
    unittest.main()

"""Safety-policy tests. No live profile/image deletion occurs here."""
import contextlib
import importlib.util
import io
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SCRATCH = pathlib.Path("/home/swe/.hermes/cache/scratch")

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "bin/cbox-storage-retention.py"
DAY = 86400
NOW = 100 * DAY

class RetentionTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "storage-retention implementation is missing")
        spec = importlib.util.spec_from_file_location("retention", SCRIPT)
        assert spec is not None and spec.loader is not None
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)

    def rows(self, count=12):
        return [{"generation": i, "mtime": i * DAY,
                 "target": f"/nix/store/target-{i}"} for i in range(1, count + 1)]

    def test_old_profiles_keep_five_distinct_predecessors(self):
        p = self.m.plan(self.rows(), 12, NOW)
        self.assertEqual(p["keep_ids"], [7, 8, 9, 10, 11, 12])
        self.assertEqual(p["delete_ids"], [1, 2, 3, 4, 5, 6])

    def test_young_profiles_are_all_retained(self):
        p = self.m.plan(self.rows(), 12, 20 * DAY)
        self.assertEqual(p["delete_ids"], [])

    def test_rollback_keeps_roll_forward_generations(self):
        p = self.m.plan(self.rows(), 5, NOW)
        self.assertTrue(set(range(5, 13)).issubset(p["keep_ids"]))
        self.assertNotIn(5, p["delete_ids"])

    def test_duplicate_closures_do_not_consume_rollback_floor(self):
        rows = self.rows()
        for r in rows[6:]:
            r["target"] = "/nix/store/shared"
        p = self.m.plan(rows, 12, NOW)
        self.assertTrue({2, 3, 4, 5, 6, 12}.issubset(p["keep_ids"]))
        self.assertEqual(p["delete_ids"], [1, 7])

    def test_window_boundary_generation_is_kept(self):
        rows = self.rows(20)
        p = self.m.plan(rows, 20, 45 * DAY)
        self.assertIn(14, p["keep_ids"])
        self.assertIn(15, p["keep_ids"])

    def test_missing_current_is_rejected(self):
        with self.assertRaises(ValueError):
            self.m.plan(self.rows(), 99, NOW)

    def test_duplicate_generation_is_rejected(self):
        rows = self.rows()
        with self.assertRaises(ValueError):
            self.m.plan(rows + [rows[0]], 12, NOW)

    def test_real_profile_symlink_snapshot_does_not_follow_current_alias(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
            root = pathlib.Path(tmp)
            (root / "profile-1-link").symlink_to("/nix/store/example-one")
            (root / "profile-2-link").symlink_to("/nix/store/example-two")
            (root / "profile").symlink_to("profile-2-link")
            rows, current = self.m.snapshot(root / "profile")
            self.assertEqual(current, 2)
            self.assertEqual([r["generation"] for r in rows], [1, 2])
            self.assertEqual(rows[0]["target"], "/nix/store/example-one")

    def image(self, suffix, age=20, tags=None, labels=None):
        return {"Id": "sha256:" + suffix * 64, "Created": NOW - age * DAY,
                "RepoTags": [] if tags is None else tags, "Labels": labels or {}}

    def test_image_age_is_strict_and_every_container_reference_is_protected(self):
        images = [self.image("a"), self.image("b", 14), self.image("c", 20), self.image("d", 13)]
        # Exited/created containers are deliberately included, not just running.
        containers = [{"ImageID": images[2]["Id"], "State": "exited"}]
        self.assertEqual(self.m.image_candidates(images, containers, NOW), [images[0]["Id"]])

    def test_tag_label_and_explicit_id_holds_are_preserved(self):
        images = [self.image("a", tags=["app:latest"]),
                  self.image("b", tags=["app:rollback-good"]),
                  self.image("c", labels={"storage.retention": "keep"}),
                  self.image("d")]
        self.assertEqual(self.m.image_candidates(images, [], NOW, [images[3]["Id"]]), [])

    def test_multitag_and_unknown_age_are_not_forced(self):
        images = [self.image("a", tags=["app:v1", "registry/app:v1"]), self.image("b")]
        images[1]["Created"] = None
        self.assertEqual(self.m.image_candidates(images, [], NOW), [])

    def test_malformed_image_id_is_rejected_not_normalized(self):
        image = self.image("a")
        image["Id"] = "a" * 64
        with self.assertRaises(ValueError):
            self.m.image_candidates([image], [], NOW)

    def test_nonfinite_image_created_is_rejected(self):
        for created in [float("nan"), float("inf"), float("-inf")]:
            with self.subTest(created=repr(created)):
                image = self.image("a")
                image["Created"] = created
                with self.assertRaises(ValueError):
                    self.m.image_candidates([image], [], NOW)

    def test_boolean_image_created_is_not_a_timestamp(self):
        image = self.image("a")
        image["Created"] = True
        self.assertEqual(self.m.image_candidates([image], [], NOW), [])

    def test_hold_json_must_be_a_list_of_literal_sha256_ids(self):
        image = self.image("a")
        malformed = [{image["Id"]: "keep"}, image["Id"], None, 12, False,
                     [12], [None], [{}], ["a" * 64], ["sha256:" + "A" * 64],
                     [image["Id"] + "\n"]]
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
            home = pathlib.Path(tmp)
            holds = home / ".config/storage-retention/keep-images.json"
            holds.parent.mkdir(parents=True)
            for payload in malformed:
                with self.subTest(payload=payload), \
                     mock.patch.object(self.m.Path, "home", return_value=home), \
                     mock.patch.object(self.m, "docker_snapshot", return_value=([image], [], [])), \
                     mock.patch.object(self.m.time, "time", return_value=NOW):
                    holds.write_text(json.dumps(payload))
                    try:
                        result = self.m.docker_images(False)
                    except ValueError:
                        result = None
                    except Exception as error:
                        self.fail(f"hold schema must fail as ValueError, not {type(error).__name__}")
                    self.assertIsNone(result, "malformed hold JSON was accepted")
            holds.write_text(json.dumps([image["Id"]]))
            with mock.patch.object(self.m.Path, "home", return_value=home), \
                 mock.patch.object(self.m, "docker_snapshot", return_value=([image], [], [])), \
                 mock.patch.object(self.m.time, "time", return_value=NOW):
                result = self.m.docker_images(False)
            self.assertEqual(result["candidate_ids"], [])
            self.assertEqual(result["state"], "preview")

    def test_buildcache_command_pins_local_default_and_preserves_reviewable_budgets(self):
        cmd = self.m.cache_command()
        self.assertEqual(cmd[:3], ["/usr/bin/docker", "--host", "unix:///var/run/docker.sock"])
        self.assertIn("default", cmd)
        self.assertIn("until=336h", cmd)
        self.assertIn("100000000000", cmd)
        self.assertIn("20000000000", cmd)
        self.assertNotIn("--all", cmd)
        self.assertNotIn("--volumes", cmd)

    def test_uv_command_never_forces_or_uses_ci(self):
        cmd = self.m.uv_command("/cache/uv", "/bin/uv")
        self.assertIn("prune", cmd)
        self.assertIn("/cache/uv", cmd)
        self.assertNotIn("--force", cmd)
        self.assertNotIn("--ci", cmd)

    def test_uv_busy_and_real_errors_are_distinct(self):
        # A wait notice does not prove that lock acquisition ultimately failed.
        self.assertEqual(self.m.uv_outcome(1, "Cache is currently in-use, waiting for other uv processes"), ("failed", 1))
        self.assertEqual(self.m.uv_outcome(0, "Removed 0 files"), ("completed", 0))
        self.assertEqual(self.m.uv_outcome(1, "invalid cache data"), ("failed", 1))

    def test_nix_apply_blocks_rollback_to_already_kept_generation_before_native_call(self):
        rows = self.rows(20)
        before = (rows, 20)
        # The old selector chose 1..14. A native call could then roll back to
        # already-kept 15, losing the newly required predecessors 10..14.
        after_rollback = ([r for r in rows if r["generation"] >= 15], 15)
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp, \
             mock.patch.object(self.m.Path, "home", return_value=pathlib.Path(tmp)), \
             mock.patch.dict(os.environ, {"HOME": tmp}), \
             mock.patch.object(self.m, "snapshot", side_effect=[before, before, after_rollback]), \
             mock.patch.object(self.m, "closure_paths", return_value=["/fixture/protected"]), \
             mock.patch.object(self.m.time, "time", return_value=NOW), \
             mock.patch.object(self.m, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as native:
            try:
                result = self.m.nix_profiles(True)
            except RuntimeError as error:
                result = {"state": "failed", "reason": str(error)}
        self.assertEqual(native.call_count, 0, "unsupported apply reached a native command")
        self.assertEqual(result["state"], "blocked")
        self.assertEqual(result.get("phase"), "capability-check")
        self.assertTrue(result["reason"])

    def test_image_apply_blocks_protected_retag_at_native_boundary(self):
        image = self.image("a")
        def retag_at_removal(*args, **kwargs):
            image["RepoTags"] = ["app:latest"]
            return subprocess.CompletedProcess(args[0], 0, "", "")
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp, \
             mock.patch.object(self.m.Path, "home", return_value=pathlib.Path(tmp)), \
             mock.patch.object(self.m, "docker_snapshot", return_value=([image], [], [])), \
             mock.patch.object(self.m, "docker_get", side_effect=[[image], []]), \
             mock.patch.object(self.m.time, "time", return_value=NOW), \
             mock.patch.object(self.m, "run", side_effect=retag_at_removal) as native:
            result = self.m.docker_images(True)
        self.assertEqual(native.call_count, 0, "unsupported apply reached a native command")
        self.assertEqual(result["state"], "blocked")
        self.assertTrue(result["reason"])

    def test_image_apply_blocks_hold_update_at_native_boundary(self):
        image = self.image("a")
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
            home = pathlib.Path(tmp)
            holds = home / ".config/storage-retention/keep-images.json"
            holds.parent.mkdir(parents=True)
            holds.write_text("[]")
            def add_hold_at_removal(*args, **kwargs):
                holds.write_text(json.dumps([image["Id"]]))
                return subprocess.CompletedProcess(args[0], 0, "", "")
            with mock.patch.object(self.m.Path, "home", return_value=home), \
                 mock.patch.object(self.m, "docker_snapshot", return_value=([image], [], [])), \
                 mock.patch.object(self.m, "docker_get", side_effect=[[image], []]), \
                 mock.patch.object(self.m.time, "time", return_value=NOW), \
                 mock.patch.object(self.m, "run", side_effect=add_hold_at_removal) as native:
                result = self.m.docker_images(True)
            self.assertEqual(native.call_count, 0, "unsupported apply reached a native command")
            self.assertEqual(result["state"], "blocked")
            self.assertEqual(holds.read_text(), "[]")

    def test_cache_apply_blocks_before_native_prune(self):
        with mock.patch.object(self.m, "docker_snapshot", return_value=([], [], [])), \
             mock.patch.object(self.m, "cache_snapshot", return_value=[]), \
             mock.patch.object(self.m, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as native:
            result = self.m.docker_cache(True)
        self.assertEqual(native.call_count, 0, "unsupported apply reached a native command")
        self.assertEqual(result["state"], "blocked")
        self.assertTrue(result["reason"])

    def test_cli_blocks_unsupported_apply_before_dispatch_on_any_host(self):
        # Keep the controller real, but isolate dispatch: its own gate must not
        # rely on the public action's independently tested gate.
        cases = [(operation, function, hostname)
                 for operation, function in [("nix", "nix_profiles"), ("images", "docker_images"), ("build-cache", "docker_cache")]
                 for hostname in ["computebox", "other-host"]]
        for operation, function, hostname in cases:
            with self.subTest(operation=operation, hostname=hostname), tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
                home = pathlib.Path(tmp)
                output = io.StringIO()
                with mock.patch.object(self.m.Path, "home", return_value=home), \
                     mock.patch.dict(os.environ, {"HOME": tmp}), \
                     mock.patch("sys.argv", [str(SCRIPT), operation, "--apply"]), \
                     mock.patch.object(self.m.socket, "gethostname", return_value=hostname), \
                     mock.patch.object(self.m, function, return_value={"state": "preview"}) as action, \
                     contextlib.redirect_stdout(output):
                    code = self.m.main()
                self.assertEqual(code, 2)
                action.assert_not_called()
                result = json.loads((home / f".local/state/storage-retention/{operation}.latest.json").read_text())
                self.assertEqual(result["state"], "blocked")
                self.assertEqual(result.get("phase"), "capability-check")
                self.assertEqual(result["exit_code"], code)
                self.assertTrue(result["reason"])
                self.assertEqual(json.loads(output.getvalue()).get("reason"), result["reason"])
                self.assertEqual(result.get("error", {}).get("type"), "UnsupportedApply")
                self.assertTrue(result["apply"])

    @contextlib.contextmanager
    def cli_fixture(self, operation, apply=False):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
            home = pathlib.Path(tmp)
            target = home / f".local/state/storage-retention/{operation}.latest.json"
            target.parent.mkdir(parents=True)
            target.write_text(json.dumps({"state": "completed", "observed_at": "old-success"}))
            output = io.StringIO()
            argv = [str(SCRIPT), operation] + (["--apply"] if apply else [])
            with mock.patch.object(self.m.Path, "home", return_value=home), \
                 mock.patch.dict(os.environ, {"HOME": tmp}), \
                 mock.patch("sys.argv", argv), \
                 mock.patch.object(self.m.socket, "gethostname", return_value="computebox"), \
                 contextlib.redirect_stdout(output):
                yield home, target, output

    def invoke_cli(self):
        try:
            return self.m.main()
        except Exception as error:
            self.fail(f"controller must publish an error receipt, not raise {type(error).__name__}: {error}")

    def test_nix_query_error_replaces_stale_success_with_failed_receipt(self):
        with self.cli_fixture("nix") as (home, target, _):
            profiles = home / ".local/state/nix/profiles"
            profiles.mkdir(parents=True)
            (profiles / "profile-1-link").symlink_to("/fixture/nix-target")
            (profiles / "profile").symlink_to("profile-1-link")
            with mock.patch.object(self.m, "run", return_value=subprocess.CompletedProcess([], 7, "partial query", "closure permission denied")):
                code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 1)
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "nix-preview")
        self.assertEqual(result["exit_code"], code)
        self.assertEqual(result["diagnostics"]["returncode"], 7)
        self.assertEqual(result["diagnostics"]["stderr"], "closure permission denied")
        self.assertNotEqual(result["observed_at"], "old-success")

    def test_docker_daemon_error_replaces_stale_success_with_failed_receipt(self):
        connection = mock.Mock()
        response = connection.getresponse.return_value
        response.status = 503
        response.read.return_value = b'{"message":"daemon unavailable"}'
        with self.cli_fixture("images") as (_, target, _), \
             mock.patch.object(self.m, "LocalDocker", return_value=connection):
            code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 1)
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "images-preview")
        self.assertIn("503", result["error"]["message"])
        self.assertIn("daemon unavailable", result["error"]["message"])
        connection.close.assert_called_once()

    def test_cache_query_timeout_is_durable_failed_nonzero(self):
        timeout = subprocess.TimeoutExpired(["fixture-cache-query"], 120, output=b"query partial", stderr=b"query timed out")
        with self.cli_fixture("build-cache") as (_, target, _), \
             mock.patch.object(self.m, "docker_snapshot", return_value=([], [], [])), \
             mock.patch.object(self.m, "docker_get", side_effect=timeout):
            code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 124)
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "build-cache-preview")
        self.assertEqual(result["error"]["type"], "TimeoutExpired")
        self.assertEqual(result["diagnostics"]["stdout"], "query partial")
        self.assertEqual(result["diagnostics"]["stderr"], "query timed out")
        self.assertEqual(result["mutation_status"], "not-started")

    def test_uv_timeout_replaces_stale_success_without_claiming_reclaim(self):
        timeout = subprocess.TimeoutExpired(["fixture-uv", "cache", "prune"], 1800,
                                            output=b"partial manager output", stderr=b"native stderr")
        with self.cli_fixture("uv", apply=True) as (_, target, _), \
             mock.patch.object(self.m, "run", side_effect=timeout) as native:
            code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 124)
        self.assertEqual(native.call_count, 1)
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "uv-prune")
        self.assertEqual(result["error"]["type"], "TimeoutExpired")
        self.assertEqual(result["diagnostics"]["stdout"], "partial manager output")
        self.assertEqual(result["diagnostics"]["stderr"], "native stderr")
        self.assertEqual(result["mutation_status"], "unknown-partial-possible")
        self.assertFalse(result["reclaim_verified"])
        self.assertNotIn("verified_removed_ids", result)

    def test_uv_native_error_preserves_stderr_and_nonzero_receipt(self):
        with self.cli_fixture("uv", apply=True) as (_, target, _), \
             mock.patch.object(self.m, "run", return_value=subprocess.CompletedProcess([], 9, "partial output", "invalid cache data")):
            code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 9)
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "uv-prune")
        self.assertTrue(result["error"])
        self.assertEqual(result["diagnostics"]["stderr"], "invalid cache data")
        self.assertFalse(result["reclaim_verified"])

    UV_WAIT_NOTICE = ("Cache is currently in-use, waiting for other uv processes to finish "
                      "(use `--force` to override)\n")

    def uv_terminal_timeout(self, cache="/fixture/cache"):
        # Exact uv 0.11.21 diagnostic from the read-only production receipt:
        # 2026-10-06T04:03:21.284158-07:00, native returncode 2 (not 1).
        return (f"error: Timeout (5s) when waiting for lock on `{cache}` at `.cache/uv/.lock`, "
                "is another uv process running? You can set `UV_LOCK_TIMEOUT` to increase the timeout.\n")

    def uv_controller_result(self, native_code, stderr, stdout=""):
        # Exercise main -> uv_prune -> real run -> mocked subprocess boundary.
        with self.cli_fixture("uv", apply=True) as (home, target, output):
            def native(command, **kwargs):
                self.assertEqual(json.loads(target.read_text())["state"], "in-progress")
                self.assertEqual(command, self.m.uv_command(str(home / ".cache/uv"),
                                 str(home / ".local/state/nix/profiles/home-manager/home-path/bin/uv")))
                self.assertEqual(kwargs["env"]["HOME"], str(home))
                self.assertEqual(kwargs["env"]["UV_LOCK_TIMEOUT"], "5")
                self.assertEqual(kwargs["timeout"], 1800)
                self.assertTrue(kwargs["capture_output"])
                self.assertTrue(kwargs["text"])
                self.assertFalse(kwargs["check"])
                return subprocess.CompletedProcess(command, native_code, stdout, stderr)
            with mock.patch.object(self.m.subprocess, "run", side_effect=native) as boundary:
                code = self.invoke_cli()
            boundary.assert_called_once()
            result = json.loads(target.read_text())
            summary = json.loads(output.getvalue())
        self.assertEqual(result["returncode"], native_code)
        self.assertEqual(result["diagnostics"], {"stdout": stdout, "stderr": stderr})
        self.assertEqual(result["output"], stdout + stderr, "raw output must not be normalized")
        self.assertEqual(result["exit_code"], code)
        self.assertEqual(summary["exit_code"], code)
        self.assertEqual(summary["state"], result["state"])
        self.assertEqual(result["phase"], "uv-prune")
        self.assertEqual(result["mutation_status"], "unknown-partial-possible")
        self.assertFalse(result["reclaim_verified"])
        self.assertFalse(result["force_used"])
        return code, result

    def assert_uv_failed(self, native_code, stderr, expected_code=None, stdout=""):
        code, result = self.uv_controller_result(native_code, stderr, stdout)
        self.assertEqual(result["state"], "failed", "a wait notice is not a terminal lock failure")
        self.assertEqual(code, native_code if expected_code is None else expected_code)
        self.assertEqual(result["error"]["type"], "NativeCommandError")

    def test_uv_wait_notice_alone_is_failed(self):
        for code in [1, 2, 9]:
            with self.subTest(native_code=code):
                self.assert_uv_failed(code, self.UV_WAIT_NOTICE)

    def test_uv_wait_then_prune_permission_error_is_failed(self):
        stderr = (self.UV_WAIT_NOTICE + "Pruning cache at: /fixture/cache\n"
                  "error: Failed to prune cache at: /fixture/cache\n"
                  "  Caused by: Permission denied (os error 13)\n")
        for code in [1, 2]:
            with self.subTest(native_code=code):
                self.assert_uv_failed(code, stderr, stdout="partial native stdout\n")

    def test_uv_wait_then_other_error_is_failed(self):
        stderr = self.UV_WAIT_NOTICE + "error: invalid cache data\n"
        self.assert_uv_failed(2, stderr)

    def test_uv_verified_terminal_lock_timeout_defers_native_exit_two(self):
        for cache in ["/home/swe/.cache/uv", "/fixture/cache"]:
            for notice in ["", self.UV_WAIT_NOTICE]:
                with self.subTest(cache=cache, notice=bool(notice)):
                    code, result = self.uv_controller_result(2, notice + self.uv_terminal_timeout(cache))
                    self.assertEqual(code, 75)
                    self.assertEqual(result["state"], "deferred-busy")
                    self.assertNotIn("error", result)

    def test_uv_terminal_timeout_with_wrong_native_status_is_failed(self):
        for code in [1, 9, 124]:
            with self.subTest(native_code=code):
                self.assert_uv_failed(code, self.UV_WAIT_NOTICE + self.uv_terminal_timeout())

    def test_uv_ambiguous_or_truncated_timeout_is_failed(self):
        terminal = self.uv_terminal_timeout()
        cases = {
            "multiple-errors": self.UV_WAIT_NOTICE + terminal + "error: permission denied\n",
            "earlier-error": "error: another failure\n" + self.UV_WAIT_NOTICE + terminal,
            "duplicate-terminal": self.UV_WAIT_NOTICE + terminal + terminal,
            "post-lock-progress": self.UV_WAIT_NOTICE + "Pruning cache at: /fixture/cache\n" + terminal,
            "truncated-terminal": self.UV_WAIT_NOTICE + terminal[:100],
            "unverified-old-phrase": "Timed out waiting for lock\n",
            "wrong-timeout": self.UV_WAIT_NOTICE + terminal.replace("(5s)", "(10s)"),
        }
        for name, stderr in cases.items():
            with self.subTest(case=name):
                self.assert_uv_failed(2, stderr)
        self.assert_uv_failed(2, self.UV_WAIT_NOTICE + terminal, stdout="ambiguous stdout\n")

    def test_uv_signal_with_wait_notice_is_failed_and_normalized(self):
        for native_code, expected_code in [(-15, 143), (-2, 130)]:
            for stderr in [self.UV_WAIT_NOTICE, self.UV_WAIT_NOTICE + self.uv_terminal_timeout()]:
                with self.subTest(native_code=native_code, terminal="error:" in stderr):
                    self.assert_uv_failed(native_code, stderr, expected_code, stdout="partial UV output\n")

    def test_uv_signal_receipt_matches_real_isolated_cli_status(self):
        # Only this Python subprocess is real; UV/Docker/native execution and
        # network are forbidden. runpy executes the actual helper __main__ path.
        child = '''import json, os, pathlib, runpy, subprocess, sys
from unittest import mock
script, native_code, waiting = sys.argv[1], int(sys.argv[2]), sys.argv[3] == "wait"
notice = "Cache is currently in-use, waiting for other uv processes to finish (use `--force` to override)\\n"
stderr = notice if waiting else "fixture process was terminated\\n"
home = pathlib.Path(os.environ["HOME"])
assert home.is_relative_to(pathlib.Path(os.environ["TMPDIR"]))
def native(command, **kwargs):
    assert command[1:3] == ["cache", "prune"]
    assert command[command.index("--cache-dir") + 1] == str(home / ".cache/uv")
    assert "--force" not in command and "--ci" not in command
    assert kwargs["env"]["UV_LOCK_TIMEOUT"] == "5"
    return subprocess.CompletedProcess(command, native_code, "partial UV output\\n", stderr)
sys.argv = [script, "uv", "--apply"]
with mock.patch("socket.gethostname", return_value="computebox"), \\
     mock.patch("socket.socket", side_effect=AssertionError("network forbidden")), \\
     mock.patch("subprocess.Popen", side_effect=AssertionError("native process forbidden")), \\
     mock.patch("subprocess.run", side_effect=native):
    runpy.run_path(script, run_name="__main__")
'''
        cases = [(native_code, expected_code, waiting)
                 for native_code, expected_code in [(-15, 143), (-2, 130)]
                 for waiting in [False, True]]
        for native_code, expected_code, waiting in cases:
            with self.subTest(native_code=native_code, waiting=waiting), tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
                home = pathlib.Path(tmp)
                process = subprocess.run([sys.executable, "-B", "-c", child, str(SCRIPT), str(native_code),
                                          "wait" if waiting else "no-wait"],
                                         capture_output=True, text=True, timeout=30,
                                         env={**os.environ, "HOME": tmp, "TMPDIR": str(SCRATCH),
                                              "PYTHONDONTWRITEBYTECODE": "1"})
                result = json.loads((home / ".local/state/storage-retention/uv.latest.json").read_text())
                summary = json.loads(process.stdout)
                self.assertEqual(result["returncode"], native_code)
                self.assertEqual(result["state"], "failed")
                self.assertEqual(result["error"]["type"], "NativeCommandError")
                expected_stderr = self.UV_WAIT_NOTICE if waiting else "fixture process was terminated\n"
                self.assertEqual(result["diagnostics"], {"stdout": "partial UV output\n", "stderr": expected_stderr})
                self.assertEqual(result["mutation_status"], "unknown-partial-possible")
                self.assertFalse(result["reclaim_verified"])
                self.assertEqual(process.stderr, "")
                self.assertEqual(result["exit_code"], expected_code)
                self.assertEqual(summary["exit_code"], expected_code)
                self.assertEqual(process.returncode, expected_code)

    def test_uv_has_durable_in_progress_receipt_before_native_call(self):
        with self.cli_fixture("uv", apply=True) as (_, target, _):
            observed = []
            def manager(cmd, **kwargs):
                observed.append(json.loads(target.read_text()))
                return subprocess.CompletedProcess(cmd, 0, "Removed 0 files", "")
            with mock.patch.object(self.m, "run", side_effect=manager):
                code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 0)
        self.assertEqual(observed[0]["state"], "in-progress")
        self.assertEqual(observed[0]["phase"], "uv-prune")
        self.assertEqual(observed[0].get("mutation_status"), "unknown-partial-possible")
        self.assertEqual(result["state"], "completed")
        self.assertEqual(result["exit_code"], 0)

    def test_maintenance_busy_publishes_deferred_receipt_without_manager_call(self):
        with self.cli_fixture("uv", apply=True) as (_, target, _), \
             mock.patch.object(self.m.fcntl, "flock", side_effect=BlockingIOError), \
             mock.patch.object(self.m, "run") as native:
            code = self.invoke_cli()
            result = json.loads(target.read_text())
        self.assertEqual(code, 75)
        self.assertEqual(result["state"], "deferred-busy")
        self.assertEqual(result.get("phase"), "maintenance-lock")
        self.assertEqual(result["exit_code"], 75)
        self.assertEqual(native.call_count, 0)

    def test_unwritable_receipt_prevents_uv_native_call(self):
        with self.cli_fixture("uv", apply=True) as (_, _, output), \
             mock.patch.object(self.m, "receipt", side_effect=OSError("fixture receipt unavailable")), \
             mock.patch.object(self.m, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as native:
            code = self.invoke_cli()
        self.assertEqual(code, 1)
        self.assertEqual(native.call_count, 0)
        result = json.loads(output.getvalue())
        self.assertEqual(result["state"], "failed")
        self.assertEqual(result.get("phase"), "receipt")

class RetentionUnitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        nix = shutil.which("nix")
        if not nix:
            raise unittest.SkipTest("Nix is required for declarative unit integration tests")
        module = SCRIPT.parents[1] / "nix/modules/storage-retention.nix"
        expression = f'(import {module}) {{ lib.mkForce = x: x; }}'
        result = subprocess.run(
            [nix, "eval", "--json", "--offline", "--impure", "--expr", expression],
            check=True, capture_output=True, text=True, timeout=30,
        )
        cls.units = json.loads(result.stdout)["systemd"]["user"]

    def test_all_non_uv_automation_is_paused_by_default(self):
        for name in ["nix", "images", "build-cache"]:
            with self.subTest(name=name):
                timer = self.units["timers"][f"cbox-retention-{name}"]
                self.assertEqual(timer["Install"].get("WantedBy", []), [])
                self.assertEqual(timer["Timer"]["Unit"], f"cbox-retention-{name}.service")

    def test_uv_retry_timer_and_apply_service_remain_automatic(self):
        timer = self.units["timers"]["cbox-retention-uv"]
        self.assertEqual(timer["Install"]["WantedBy"], ["timers.target"])
        self.assertEqual(timer["Timer"]["OnCalendar"], "hourly")
        service = self.units["services"]["cbox-retention-uv"]["Service"]
        self.assertTrue(service["ExecStart"].endswith(" uv --apply"))
        self.assertEqual(service["SuccessExitStatus"], "75")

    def test_non_uv_services_only_preview_reviewable_policy(self):
        for name in ["nix", "images", "build-cache"]:
            with self.subTest(name=name):
                command = self.units["services"][f"cbox-retention-{name}"]["Service"]["ExecStart"]
                self.assertTrue(command.endswith(f" {name}"))
                self.assertNotIn("--apply", command)


if __name__ == "__main__":
    unittest.main()

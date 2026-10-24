"""End-to-end tests; every fixture/write lives under Hermes scratch.

Run: PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover \
     -s tests -p test_cbox_btrfs_watch.py -v
"""
import fcntl
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "cbox-btrfs-watch.py"
PYTHON = "/usr/bin/python3"
SCRATCH = Path("/home/swe/.hermes/cache/scratch")
UUID = "12345678-1234-4234-8234-123456789abc"
OTHER_UUID = "12345678-1234-4234-8234-123456789abd"
GIB = 1024 ** 3
NOW = 1800000000.0
COUNTERS = ("total_bytes", "bytes_used", "bytes_reserved", "bytes_may_use",
            "bytes_pinned", "bytes_readonly", "bytes_zone_unusable", "disk_total")
ERRORS = ("write_errs", "read_errs", "flush_errs", "corruption_errs", "generation_errs")

FAKE = '''#!/usr/bin/python3
import json, os, pathlib, sys, time
root = pathlib.Path(__file__).parent
name = pathlib.Path(sys.argv[0]).name
with (root / 'calls.jsonl').open('a') as f:
    f.write(json.dumps({'name': name, 'argv': sys.argv[1:], 'locale': os.getenv('LC_ALL')}) + '\\n')
c = json.loads((root / 'scenario.json').read_text())
if c.get(name + '_sleep'):
    time.sleep(c[name + '_sleep'])
if c.get(name + '_rc', 0):
    print(c.get(name + '_stderr', 'injected command failure'), file=sys.stderr)
    sys.exit(c[name + '_rc'])
if name == 'findmnt':
    print(c.get('findmnt_raw', json.dumps(c['mount'])))
elif name == 'btrfs':
    print(c['usage'])
    print(c.get('btrfs_stderr', ''), file=sys.stderr)
elif name == 'notify-send':
    print(c.get('notify_raw', '42'))
else:
    sys.exit(99)
'''


class BtrfsWatchCLI(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="btrfs-watch-test-", dir=SCRATCH)
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.state_dir = self.root / "state"
        self.sysfs = self.root / "sysfs"
        self.metadata = self.sysfs / UUID / "allocation" / "metadata"
        self.metadata.mkdir(parents=True)
        self.devinfo = self.sysfs / UUID / "devinfo"
        (self.devinfo / "1").mkdir(parents=True)
        self.values: dict[str, int] = dict(zip(COUNTERS, (200 * GIB, 140 * GIB, 0, 0, 0, 0, 0, 400 * GIB)))
        self.write_metadata()
        self.write_errors()
        self.mount = "/fixture-mount"
        self.scenario = {
            "mount": {"filesystems": [{"target": self.mount, "fstype": "btrfs",
                                        "uuid": UUID, "options": "rw,relatime,subvol=/@"}]},
            "usage": self.usage(100 * GIB),
            "btrfs_stderr": "WARNING: cannot read detailed chunk info: Operation not permitted",
        }
        self.write_scenario()
        for name in ("findmnt", "btrfs", "notify-send"):
            path = self.root / name
            path.write_text(FAKE)
            path.chmod(0o700)

    def usage(self, unallocated):
        return ("Overall:\n    Device size: 1099511627776\n"
                "    Device allocated: 879609302220\n"
                f"    Device unallocated: {unallocated}\n"
                "    Free (estimated): 123456789\n"
                "Metadata,DUP: Size:429496729600, Used:300647710720\n")

    def write_metadata(self, **updates):
        self.values.update(updates)
        for key, value in self.values.items():
            (self.metadata / key).write_text(str(value) + "\n")

    def write_errors(self, devid="1", **updates):
        directory = self.devinfo / devid
        directory.mkdir(exist_ok=True)
        data: dict[str, int] = dict.fromkeys(ERRORS, 0)
        data.update(updates)
        (directory / "error_stats").write_text("".join(f"{key} {value}\n" for key, value in data.items()))

    def write_scenario(self, **updates):
        self.scenario.update(updates)
        (self.root / "scenario.json").write_text(json.dumps(self.scenario))

    def calls(self):
        path = self.root / "calls.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def notifications(self):
        return [call for call in self.calls() if call["name"] == "notify-send"]

    def run_cli(self, *extra, now=NOW, inject="", no_notify=True, uuid=UUID, state_dir=None):
        args = [str(SCRIPT), "--uuid", uuid, "--mount", self.mount,
                "--state-dir", str(state_dir or self.state_dir),
                "--sysfs-root", str(self.sysfs), "--btrfs", str(self.root / "btrfs"),
                "--findmnt", str(self.root / "findmnt"),
                "--notify-send", str(self.root / "notify-send")]
        if no_notify:
            args.append("--no-notify")
        args.extend(extra)
        # Fault injection only in this child, exercising the actual CLI entrypoint.
        wrapper = ("import os, stat, sys, time, runpy, subprocess; "
                   f"time.time = lambda: {now!r}; " + inject +
                   "sys.argv = sys.argv[1:]; runpy.run_path(sys.argv[0], run_name='__main__')")
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", TMPDIR=str(SCRATCH))
        proc = subprocess.run([PYTHON, "-B", "-c", wrapper, *args], capture_output=True,
                              text=True, timeout=25, env=env, cwd=self.root)
        self.assertTrue(proc.stdout.strip(), f"expected JSON status, stderr={proc.stderr!r}")
        try:
            result = json.loads(proc.stdout)
        except json.JSONDecodeError:
            self.fail(f"expected one JSON status, got {proc.stdout!r}, stderr={proc.stderr!r}")
        self.assertIsInstance(result, dict)
        for call in self.calls():
            if call["name"] == "btrfs":
                self.assertEqual(call["argv"], ["filesystem", "usage", "-b", self.mount])
            elif call["name"] == "findmnt":
                self.assertEqual(call["argv"], ["--json", "--target", self.mount,
                                               "--output", "TARGET,FSTYPE,UUID,OPTIONS"])
            else:
                self.assertEqual(call["name"], "notify-send")
            self.assertEqual(call["locale"], "C")
        return proc, result

    def assert_ok(self, proc, result, severity):
        self.assertEqual(proc.returncode, 0, (result, proc.stderr))
        self.assertTrue(result["ok"])
        self.assertEqual(result["severity"], severity)
        self.assertEqual(result["uuid"], UUID)
        self.assertEqual(result["schema_version"], 1)

    def assert_failure(self, proc, result, contains=""):
        self.assertNotEqual(proc.returncode, 0)
        self.assertFalse(result["ok"])
        self.assertTrue(result["monitor_failure"])
        self.assertEqual(result["severity"], "critical")
        self.assertIn(contains, result["error"])
        self.assertIn("monitor_failure", result["reasons"])

    def state(self):
        return json.loads((self.state_dir / "state.json").read_text())

    def save_state(self, state):
        path = self.state_dir / "state.json"
        path.write_text(json.dumps(state))
        path.chmod(0o600)

    def seed_history(self, points, now=NOW - 60):
        proc, result = self.run_cli(now=now)
        self.assert_ok(proc, result, "healthy")
        state = self.state()
        state["history"] = [{"timestamp": timestamp, "metadata_used_bytes": used}
                            for timestamp, used in points]
        state["history"].append({"timestamp": now, "metadata_used_bytes": self.values["bytes_used"]})
        self.save_state(state)

    def test_healthy_collects_live_counters_and_exact_readonly_commands(self):
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        self.assertEqual(result["reasons"], [])
        m = result["measurement"]
        self.assertEqual(m["device_unallocated_bytes"], 100 * GIB)
        self.assertEqual(m["device_size_bytes"], 1024 * GIB)
        self.assertEqual(m["metadata"]["bytes_used"], 140 * GIB)
        self.assertEqual(m["metadata"]["disk_total"], 400 * GIB)
        self.assertEqual(m["metadata"]["effective_margin_bytes"], 60 * GIB)
        self.assertIn("not guaranteed writable bytes", m["pressure_note"])
        self.assertTrue(m["query_warnings"])
        self.assertEqual(m["device_errors"]["1"], dict.fromkeys(ERRORS, 0))
        self.assertTrue(result["state_published"])
        self.assertEqual(self.state()["history"], [{"timestamp": NOW, "metadata_used_bytes": 140 * GIB}])
        self.assertEqual([c["name"] for c in self.calls()], ["findmnt", "btrfs"])

    def test_warning_policy_each_inclusive_boundary(self):
        cases = [(170 * GIB, 0, 100 * GIB, "metadata_usage_warning"),
                 (140 * GIB, 40 * GIB, 100 * GIB, "metadata_margin_warning"),
                 (140 * GIB, 0, 50 * GIB, "device_unallocated_warning")]
        for index, (used, reserved, unallocated, reason) in enumerate(cases):
            with self.subTest(reason=reason):
                self.write_metadata(bytes_used=used, bytes_reserved=reserved)
                self.write_scenario(usage=self.usage(unallocated))
                proc, result = self.run_cli(state_dir=self.root / f"warning-{index}")
                self.assert_ok(proc, result, "warning")
                self.assertIn(reason, result["reasons"])

    def test_critical_policy_each_inclusive_boundary(self):
        cases = [(190 * GIB, 0, 100 * GIB, "metadata_usage_critical"),
                 (140 * GIB, 55 * GIB, 100 * GIB, "metadata_margin_critical"),
                 (140 * GIB, 0, 10 * GIB, "device_unallocated_critical")]
        for index, (used, reserved, unallocated, reason) in enumerate(cases):
            with self.subTest(reason=reason):
                self.write_metadata(bytes_used=used, bytes_reserved=reserved)
                self.write_scenario(usage=self.usage(unallocated))
                proc, result = self.run_cli(state_dir=self.root / f"critical-{index}")
                self.assert_ok(proc, result, "critical")
                self.assertIn(reason, result["reasons"])

    def test_all_reservations_reduce_effective_margin_and_clamp_zero(self):
        self.write_metadata(bytes_reserved=12 * GIB, bytes_may_use=13 * GIB,
                            bytes_pinned=14 * GIB, bytes_readonly=15 * GIB,
                            bytes_zone_unusable=16 * GIB)
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "critical")
        self.assertEqual(result["measurement"]["metadata"]["effective_margin_bytes"], 0)

    def test_current_host_values_warn_without_claiming_enospc(self):
        self.write_metadata(total_bytes=int(176.5 * GIB), bytes_used=int(149.56 * GIB),
                            disk_total=353 * GIB)
        self.write_scenario(usage=self.usage(24697110528))
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "warning")
        self.assertEqual(result["reasons"], ["device_unallocated_warning"])
        self.assertNotIn("ENOSPC", json.dumps(result))

    def test_readonly_mount_is_critical(self):
        self.scenario["mount"]["filesystems"][0]["options"] = "ro,relatime"
        self.write_scenario()
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "critical")
        self.assertIn("read_only_mount", result["reasons"])
        self.assertTrue(result["measurement"]["mount"]["readonly"])

    def test_each_recorded_device_error_is_critical_including_second_device(self):
        for index, name in enumerate(ERRORS):
            with self.subTest(name=name):
                self.write_errors("2", **{name: 1})
                proc, result = self.run_cli(state_dir=self.root / f"error-{index}")
                self.assert_ok(proc, result, "critical")
                self.assertIn("recorded_device_errors", result["reasons"])
                self.assertEqual(result["measurement"]["device_errors"]["2"][name], 1)

    def test_identity_mismatch_fails_before_btrfs_and_without_state_publication(self):
        self.scenario["mount"]["filesystems"][0]["uuid"] = OTHER_UUID
        self.write_scenario()
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "UUID")
        self.assertEqual([c["name"] for c in self.calls()], ["findmnt"])
        self.assertFalse((self.state_dir / "state.json").exists())

    def test_non_btrfs_or_malformed_mount_identity_fails(self):
        for index, mount in enumerate(({"filesystems": []}, {"filesystems": [{"fstype": "ext4"}]},
                                       {"filesystems": [{"target": self.mount, "fstype": "btrfs",
                                                          "uuid": UUID, "options": "relatime"}]})):
            with self.subTest(mount=mount):
                self.write_scenario(mount=mount)
                proc, result = self.run_cli(state_dir=self.root / f"bad-mount-{index}")
                self.assert_failure(proc, result)

    def test_query_failure_sends_monitor_failure_alert_and_no_false_enospc(self):
        self.write_scenario(btrfs_rc=1, btrfs_stderr="injected usage failure")
        proc, result = self.run_cli(no_notify=False)
        self.assert_failure(proc, result, "injected usage failure")
        self.assertFalse((self.state_dir / "state.json").exists())
        call = self.notifications()[-1]["argv"]
        self.assertEqual(call[-2], "Btrfs Watch monitor failure")
        self.assertEqual(call[-1], "Check failed; filesystem health unknown. See the Btrfs Watch service journal.")
        self.assertNotIn("ENOSPC", call[-1])
        self.assertEqual(result["failure_notification"]["id"], "42")

    def test_findmnt_command_failure_and_bad_json_fail_visibly(self):
        self.write_scenario(findmnt_rc=2)
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "findmnt")
        self.write_scenario(findmnt_rc=0, findmnt_raw="not json")
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "findmnt")

    def test_missing_malformed_or_duplicate_usage_fields_fail(self):
        for index, usage in enumerate(("Overall:\nDevice size: 1024\n", self.usage(100 * GIB) + "Device size: 7\n",
                                       self.usage(100 * GIB).replace(str(100 * GIB), "1.5GiB"),
                                       self.usage(2048 * GIB))):
            with self.subTest(usage=usage):
                self.write_scenario(usage=usage)
                proc, result = self.run_cli(state_dir=self.root / f"bad-usage-{index}")
                self.assert_failure(proc, result)

    def test_missing_metadata_counter_fails_instead_of_defaulting_zero(self):
        (self.metadata / "bytes_reserved").unlink()
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "bytes_reserved")

    def test_invalid_metadata_numbers_fail(self):
        for index, value in enumerate(("-1", "NaN", "inf", "1.5", "9" * 100, "")):
            with self.subTest(value=value):
                (self.metadata / "bytes_used").write_text(value)
                proc, result = self.run_cli(state_dir=self.root / f"bad-number-{index}")
                self.assert_failure(proc, result, "bytes_used")

    def test_missing_device_error_signal_fails(self):
        (self.devinfo / "1" / "error_stats").unlink()
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "error_stats")

    def test_empty_devinfo_fails(self):
        (self.devinfo / "1" / "error_stats").unlink()
        (self.devinfo / "1").rmdir()
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "devinfo")

    def test_malformed_duplicate_or_incomplete_error_stats_fail(self):
        valid = (self.devinfo / "1" / "error_stats").read_text()
        for index, text in enumerate((valid.replace("write_errs 0", "write_errs -1"),
                                      valid + "write_errs 0\n", "write_errs 0\n")):
            with self.subTest(text=text):
                (self.devinfo / "1" / "error_stats").write_text(text)
                proc, result = self.run_cli(state_dir=self.root / f"bad-errors-{index}")
                self.assert_failure(proc, result, "error_stats")

    def test_growth_uses_oldest_point_in_45_to_75_minute_window(self):
        self.seed_history([(NOW - 4500, 138 * GIB), (NOW - 3600, 139 * GIB),
                           (NOW - 2700, 140 * GIB)])
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "warning")
        self.assertIn("metadata_growth_warning", result["reasons"])
        self.assertEqual(result["measurement"]["growth"]["span_seconds"], 4500)
        self.assertAlmostEqual(result["measurement"]["growth"]["bytes_per_hour"], 1.6 * GIB)

    def test_growth_threshold_is_inclusive_at_one_gib_per_hour(self):
        self.seed_history([(NOW - 3600, 139 * GIB)])
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "warning")
        self.assertEqual(result["measurement"]["growth"]["bytes_per_hour"], GIB)

    def test_no_growth_warning_from_noisy_short_delta_or_old_sample(self):
        self.seed_history([(NOW - 4501, 100 * GIB), (NOW - 2699, 100 * GIB)])
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        self.assertIsNone(result["measurement"]["growth"])

    def test_negative_or_below_threshold_growth_does_not_warn(self):
        self.seed_history([(NOW - 3600, 141 * GIB)])
        original = self.state()
        for index, old in enumerate((141 * GIB, 140 * GIB - GIB // 2)):
            with self.subTest(old=old):
                self.save_state(original)
                data = self.state()
                data["history"][0]["metadata_used_bytes"] = old
                self.save_state(data)
                proc, result = self.run_cli()
                self.assert_ok(proc, result, "healthy")

    def test_history_prunes_age_and_count_to_2016(self):
        self.seed_history([(NOW - 8 * 86400, 139 * GIB)])
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        self.assertTrue(all(point["timestamp"] >= NOW - 7 * 86400 for point in self.state()["history"]))
        state = self.state()
        state["history"] = [{"timestamp": NOW - 2016 + i, "metadata_used_bytes": 140 * GIB}
                            for i in range(2016)]
        state["current"]["timestamp"] = NOW - 1
        self.save_state(state)
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        self.assertEqual(len(self.state()["history"]), 2016)
        self.assertEqual(result["history_points"], 2016)
        self.assertEqual(self.state()["history"][-1]["timestamp"], NOW)
        self.assertEqual(set(self.state()["history"][-1]), {"timestamp", "metadata_used_bytes"})

    def test_duplicate_timestamp_replaces_last_history_point_without_growth(self):
        self.run_cli()
        self.run_cli()
        self.assertEqual(len(self.state()["history"]), 1)

    def test_corrupt_wrong_uuid_or_oversized_state_is_not_wiped(self):
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        good = self.state()
        cases = ["{broken", "x" * (1024 * 1024 + 1),
                 json.dumps(dict(good, uuid=OTHER_UUID)), json.dumps(dict(good, version=999))]
        for text in cases:
            with self.subTest(size=len(text)):
                (self.state_dir / "state.json").write_text(text)
                proc, result = self.run_cli()
                self.assert_failure(proc, result, "state")
                self.assertEqual((self.state_dir / "state.json").read_text(), text)

    def test_state_rejects_nonfinite_future_unsorted_and_bool_numbers(self):
        self.run_cli()
        good = self.state()
        for mutation in (lambda s: s["history"][0].update(timestamp=float("nan")),
                         lambda s: s["history"][0].update(timestamp=NOW + 1),
                         lambda s: s["history"][0].update(metadata_used_bytes=True),
                         lambda s: s.update(history=[s["history"][0], {"timestamp": NOW - 1, "metadata_used_bytes": 1}]),
                         lambda s: s["current"]["metadata"].update(bytes_used=float("inf")),
                         lambda s: s.update(last_alert={"timestamp": float("inf"), "severity": "warning", "notification_id": "42"})):
            with self.subTest(mutation=mutation):
                state = json.loads(json.dumps(good))
                mutation(state)
                self.save_state(state)
                before = (self.state_dir / "state.json").read_bytes()
                proc, result = self.run_cli()
                self.assert_failure(proc, result, "state")
                self.assertEqual((self.state_dir / "state.json").read_bytes(), before)

    def test_literal_uuid_validation_never_repairs_or_queries(self):
        for uuid in (UUID.upper(), UUID.replace("-", ""), " " + UUID, UUID + "\n", "../" + UUID):
            with self.subTest(uuid=uuid):
                proc, result = self.run_cli(uuid=uuid)
                self.assert_failure(proc, result, "UUID")
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.state_dir.exists())

    def test_required_cli_options_have_nonzero_json_error(self):
        for args in ([], ["--uuid", UUID], ["--state-dir", str(self.state_dir)]):
            with self.subTest(args=args):
                proc = subprocess.run([PYTHON, "-B", str(SCRIPT), *args], capture_output=True,
                                      text=True, cwd=self.root, timeout=5)
                self.assertNotEqual(proc.returncode, 0)
                self.assertTrue(proc.stdout.strip(), f"expected JSON status, stderr={proc.stderr!r}")
                self.assertFalse(json.loads(proc.stdout)["ok"])

    def test_private_state_and_atomic_publication_leave_no_temporary_files(self):
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "healthy")
        self.assertEqual(stat.S_IMODE(self.state_dir.stat().st_mode), 0o700)
        for name in ("state.json", "lock"):
            self.assertEqual(stat.S_IMODE((self.state_dir / name).stat().st_mode), 0o600)
        self.assertEqual({p.name for p in self.state_dir.iterdir()}, {"state.json", "lock"})

    def test_unsafe_or_symlinked_state_is_rejected_without_target_mutation(self):
        self.state_dir.mkdir(mode=0o700)
        target = self.root / "precious"
        target.write_text("do not overwrite")
        (self.state_dir / "state.json").symlink_to(target)
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "state")
        self.assertEqual(target.read_text(), "do not overwrite")
        (self.state_dir / "state.json").unlink()
        self.state_dir.chmod(0o755)
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "private")

    def test_lock_contention_is_visible_without_sampling_or_state_update(self):
        self.run_cli()
        before = (self.state_dir / "state.json").read_bytes()
        with (self.state_dir / "lock").open("r+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            proc, result = self.run_cli()
        self.assert_failure(proc, result, "lock")
        self.assertEqual((self.state_dir / "state.json").read_bytes(), before)
        self.assertEqual(len([c for c in self.calls() if c["name"] == "btrfs"]), 1)

    def test_print_only_creates_no_directory_lock_history_or_notification(self):
        self.write_metadata(bytes_used=190 * GIB)
        proc, result = self.run_cli("--print-only", no_notify=False)
        self.assert_ok(proc, result, "critical")
        self.assertFalse(result["state_published"])
        self.assertFalse(self.state_dir.exists())
        self.assertEqual(self.notifications(), [])

    def test_print_only_preserves_existing_state_and_still_reads_growth(self):
        self.seed_history([(NOW - 3600, 139 * GIB)])
        before = {p.name: p.read_bytes() for p in self.state_dir.iterdir()}
        proc, result = self.run_cli("--print-only", no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual({p.name: p.read_bytes() for p in self.state_dir.iterdir()}, before)
        self.assertEqual(self.notifications(), [])

    def test_print_only_query_failure_does_not_create_state_or_notify(self):
        self.write_scenario(btrfs_rc=1)
        proc, result = self.run_cli("--print-only", no_notify=False)
        self.assert_failure(proc, result)
        self.assertFalse(self.state_dir.exists())
        self.assertEqual(self.notifications(), [])

    def test_warning_notification_command_and_six_hour_cooldown(self):
        self.write_metadata(bytes_used=170 * GIB)
        proc, result = self.run_cli(no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual(result["notification"], {"status": "accepted", "id": "42"})
        expected = ["--print-id", "--app-name", "Btrfs Watch", "--urgency", "normal", "--expire-time", "0"]
        self.assertEqual(self.notifications()[0]["argv"][:-2], expected)
        self.assertEqual(self.notifications()[0]["argv"][-1],
                         "Metadata: 85.0% used, 30.0 GiB margin\nDevice unallocated: 100.0 GiB")
        self.assertIn("not guaranteed writable bytes", result["measurement"]["pressure_note"])
        self.assertEqual(self.state()["last_alert"], {"timestamp": NOW, "severity": "warning", "notification_id": "42"})
        proc, result = self.run_cli(now=NOW + 6 * 3600 - 1, no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual(result["notification"]["status"], "cooldown")
        self.assertEqual(len(self.notifications()), 1)
        self.run_cli(now=NOW + 6 * 3600, no_notify=False)
        self.assertEqual(len(self.notifications()), 2)

    def test_compact_notification_preserves_readonly_and_device_error_alerts(self):
        self.scenario["mount"]["filesystems"][0]["options"] = "ro,relatime"
        self.write_scenario()
        self.write_errors(write_errs=1)
        proc, result = self.run_cli(no_notify=False)
        self.assert_ok(proc, result, "critical")
        self.assertEqual(self.notifications()[-1]["argv"][-1],
                         "Metadata: 70.0% used, 60.0 GiB margin\nDevice unallocated: 100.0 GiB\n"
                         "Filesystem read-only; recorded device errors.")

    def test_compact_notification_includes_growth_only_when_it_triggers(self):
        self.seed_history([(NOW - 4500, 138 * GIB)])
        proc, result = self.run_cli(no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual(self.notifications()[-1]["argv"][-1],
                         "Metadata: 70.0% used, 60.0 GiB margin\nDevice unallocated: 100.0 GiB\n"
                         "Growth: +1.6 GiB/h over 75 min.")

    def test_twelve_hour_sampling_does_not_invent_hourly_growth(self):
        self.run_cli(now=NOW - 12 * 3600)
        self.write_metadata(bytes_used=170 * GIB)
        proc, result = self.run_cli(no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertIsNone(result["measurement"]["growth"])
        self.assertNotIn("Growth", self.notifications()[-1]["argv"][-1])

    def test_critical_escalation_is_immediate_then_one_hour_cooldown(self):
        self.write_metadata(bytes_used=170 * GIB)
        self.run_cli(no_notify=False)
        self.write_metadata(bytes_used=190 * GIB)
        proc, result = self.run_cli(now=NOW + 1, no_notify=False)
        self.assert_ok(proc, result, "critical")
        self.assertEqual(len(self.notifications()), 2)
        self.assertIn("critical", self.notifications()[-1]["argv"])
        self.run_cli(now=NOW + 3600, no_notify=False)
        self.assertEqual(len(self.notifications()), 2)
        self.run_cli(now=NOW + 3601, no_notify=False)
        self.assertEqual(len(self.notifications()), 3)

    def test_failed_notify_does_not_advance_cooldown_and_next_sample_retries(self):
        self.write_metadata(bytes_used=170 * GIB)
        self.write_scenario(**{"notify-send_rc": 1})
        proc, result = self.run_cli(no_notify=False)
        self.assert_failure(proc, result, "notify")
        self.assertIsNone(self.state()["last_alert"])
        self.assertEqual(len(self.state()["history"]), 1)
        self.write_scenario(**{"notify-send_rc": 0})
        proc, result = self.run_cli(now=NOW + 1, no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual(len(self.notifications()), 2)
        self.assertEqual(self.state()["last_alert"]["timestamp"], NOW + 1)

    def test_invalid_notification_id_is_failure_and_does_not_advance_cooldown(self):
        self.write_metadata(bytes_used=170 * GIB)
        self.write_scenario(notify_raw="not an id")
        proc, result = self.run_cli(no_notify=False)
        self.assert_failure(proc, result, "notification ID")
        self.assertIsNone(self.state()["last_alert"])

    def test_no_notify_samples_and_writes_without_advancing_alerts(self):
        self.write_metadata(bytes_used=190 * GIB)
        proc, result = self.run_cli()
        self.assert_ok(proc, result, "critical")
        self.assertTrue(result["state_published"])
        self.assertIsNone(self.state()["last_alert"])
        self.assertEqual(result["notification"]["status"], "disabled")
        self.assertEqual(self.notifications(), [])

    def test_healthy_does_not_notify(self):
        proc, result = self.run_cli(no_notify=False)
        self.assert_ok(proc, result, "healthy")
        self.assertEqual(result["notification"]["status"], "not-needed")
        self.assertEqual(self.notifications(), [])

    def test_file_fsync_failure_preserves_previous_state_and_reports_failure(self):
        self.run_cli()
        before = (self.state_dir / "state.json").read_bytes()
        inject = "os.fsync = lambda fd: (_ for _ in ()).throw(OSError('injected file fsync failure')); "
        proc, result = self.run_cli(now=NOW + 1, inject=inject, no_notify=False)
        self.assert_failure(proc, result, "fsync")
        self.assertFalse(result["state_published"])
        self.assertEqual((self.state_dir / "state.json").read_bytes(), before)
        self.assertEqual(self.notifications()[-1]["argv"][-2], "Btrfs Watch monitor failure")

    def test_post_replace_directory_fsync_failure_is_not_false_success(self):
        self.run_cli()
        inject = ("original_fsync = os.fsync; "
                  "os.fsync = lambda fd: (_ for _ in ()).throw(OSError('injected directory fsync failure')) "
                  "if stat.S_ISDIR(os.fstat(fd).st_mode) else original_fsync(fd); ")
        proc, result = self.run_cli(now=NOW + 1, inject=inject)
        self.assert_failure(proc, result, "fsync")
        self.assertFalse(result["state_published"])
        self.assertEqual(self.state()["current"]["timestamp"], NOW + 1)
        self.assertEqual({p.name for p in self.state_dir.iterdir()}, {"state.json", "lock"})

    def test_replace_failure_preserves_previous_state(self):
        self.run_cli()
        before = (self.state_dir / "state.json").read_bytes()
        inject = "os.replace = lambda *a, **k: (_ for _ in ()).throw(OSError('injected replace failure')); "
        proc, result = self.run_cli(now=NOW + 1, inject=inject)
        self.assert_failure(proc, result, "replace")
        self.assertEqual((self.state_dir / "state.json").read_bytes(), before)

    def test_notification_receipt_publication_failure_returns_nonzero(self):
        self.write_metadata(bytes_used=170 * GIB)
        # Two publications: measured state, then accepted notification receipt.
        inject = ("original_fsync = os.fsync; fsync_count = [0]; "
                  "exec('def fail_second_directory(fd):\\n "
                  "fsync_count[0] += int(stat.S_ISDIR(os.fstat(fd).st_mode))\\n "
                  "if fsync_count[0] == 2: raise OSError(\\\"injected alert receipt fsync failure\\\")\\n "
                  "return original_fsync(fd)'); os.fsync = fail_second_directory; ")
        proc, result = self.run_cli(inject=inject, no_notify=False)
        self.assert_failure(proc, result, "fsync")
        self.assertFalse(result["state_published"])
        self.assertEqual(result["notification"]["id"], "42")

    def test_external_command_timeout_is_finite_and_visible(self):
        self.write_scenario(btrfs_sleep=0.4)
        inject = ("original_run = subprocess.run; "
                  "subprocess.run = lambda *a, **k: original_run(*a, **dict(k, timeout=0.05)); ")
        proc, result = self.run_cli(inject=inject)
        self.assert_failure(proc, result, "timed out")
        self.assertFalse((self.state_dir / "state.json").exists())

    def test_escalation_after_deescalation_bypasses_prior_critical_cooldown(self):
        self.write_metadata(bytes_used=190 * GIB)
        self.run_cli(no_notify=False)
        self.write_metadata(bytes_used=170 * GIB)
        self.run_cli(now=NOW + 1, no_notify=False)
        self.assertEqual(len(self.notifications()), 1)
        self.write_metadata(bytes_used=190 * GIB)
        proc, result = self.run_cli(now=NOW + 2, no_notify=False)
        self.assert_ok(proc, result, "critical")
        self.assertEqual(len(self.notifications()), 2)

    def test_failed_escalation_after_recovery_remains_pending_for_retry(self):
        self.write_metadata(bytes_used=170 * GIB)
        self.run_cli(no_notify=False)
        self.write_metadata(bytes_used=140 * GIB)
        self.run_cli(now=NOW + 1, no_notify=False)
        self.write_metadata(bytes_used=170 * GIB)
        self.write_scenario(**{"notify-send_rc": 1})
        proc, result = self.run_cli(now=NOW + 2, no_notify=False)
        self.assert_failure(proc, result, "notify")
        self.assertEqual(self.state()["last_alert"]["timestamp"], NOW)
        self.assertTrue(self.state()["alert_pending"])
        self.write_scenario(**{"notify-send_rc": 0})
        proc, result = self.run_cli(now=NOW + 3, no_notify=False)
        self.assert_ok(proc, result, "warning")
        self.assertEqual(len(self.notifications()), 3)
        self.assertFalse(self.state()["alert_pending"])

    def test_temporary_name_collision_never_unlinks_preexisting_file(self):
        self.run_cli()
        target = self.state_dir / ".state-999-fixed.json"
        target.write_text("preexisting private file")
        inject = "import secrets; os.getpid = lambda: 999; secrets.token_hex = lambda n: 'fixed'; "
        proc, result = self.run_cli(now=NOW + 1, inject=inject)
        self.assert_failure(proc, result, "state")
        self.assertTrue(target.exists(), "exclusive-create failure must not delete another file")
        self.assertEqual(target.read_text(), "preexisting private file")

    def test_unreadable_metadata_and_device_errors_fail_visibly(self):
        for path in (self.metadata / "bytes_reserved", self.devinfo / "1" / "error_stats"):
            with self.subTest(path=path):
                path.chmod(0)
                try:
                    proc, result = self.run_cli()
                    self.assert_failure(proc, result, path.name)
                finally:
                    path.chmod(0o600)

    def test_unreadable_state_fails_without_wiping(self):
        self.run_cli()
        path = self.state_dir / "state.json"
        before = path.read_bytes()
        path.chmod(0)
        try:
            proc, result = self.run_cli()
            self.assert_failure(proc, result, "state")
        finally:
            path.chmod(0o600)
        self.assertEqual(path.read_bytes(), before)

    def test_symlink_lock_and_symlink_directory_are_rejected(self):
        self.state_dir.mkdir(mode=0o700)
        target = self.root / "precious"
        target.write_text("untouched")
        (self.state_dir / "lock").symlink_to(target)
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "state")
        self.assertEqual(target.read_text(), "untouched")
        linked_dir = self.root / "linked-state"
        linked_dir.symlink_to(self.state_dir, target_is_directory=True)
        proc, result = self.run_cli(state_dir=linked_dir)
        self.assert_failure(proc, result, "state")

    def test_growth_window_endpoints_are_inclusive(self):
        self.run_cli(now=NOW - 1)
        good = self.state()
        for span in (2700, 4500):
            with self.subTest(span=span):
                state = json.loads(json.dumps(good))
                state["history"].insert(0, {"timestamp": NOW - span,
                                            "metadata_used_bytes": 138 * GIB})
                self.save_state(state)
                proc, result = self.run_cli()
                self.assert_ok(proc, result, "warning")
                self.assertEqual(result["measurement"]["growth"]["span_seconds"], span)

    def test_failure_alert_failure_is_reported_not_hidden(self):
        self.write_scenario(btrfs_rc=1, **{"notify-send_rc": 1})
        proc, result = self.run_cli(no_notify=False)
        self.assert_failure(proc, result, "btrfs")
        self.assertEqual(result["failure_notification"]["status"], "failed")
        self.assertIn("notify-send", result["failure_notification"]["error"])

    def test_command_executable_missing_fails_visibly(self):
        (self.root / "btrfs").unlink()
        proc, result = self.run_cli()
        self.assert_failure(proc, result, "btrfs")


if __name__ == "__main__":
    unittest.main()

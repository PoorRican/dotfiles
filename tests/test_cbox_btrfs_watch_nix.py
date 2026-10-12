"""Verify the actual cbox Home Manager units without activation."""
import json
import os
from pathlib import Path
import subprocess
import unittest

REPO = Path(__file__).resolve().parents[1]
MODULE = REPO / "nix/modules/btrfs-watch.nix"


class BtrfsWatchNixTests(unittest.TestCase):
    def test_module_exists_separately_from_cleanup(self):
        self.assertTrue(MODULE.is_file(), "alert-only module has not been implemented")
        source = MODULE.read_text()
        self.assertNotIn("storage-retention.py", source)
        self.assertNotIn("--apply", source)

    def test_host_imports_monitor(self):
        self.assertIn("../modules/btrfs-watch.nix", (REPO / "nix/hosts/cbox.nix").read_text())

    def test_host_excludes_suspended_retention(self):
        self.assertNotIn("../modules/storage-retention.nix", (REPO / "nix/hosts/cbox.nix").read_text())

    def test_actual_home_manager_units(self):
        self.assertTrue(MODULE.is_file(), "alert-only module has not been implemented")
        expression = '''let
          f = builtins.getFlake "path:%s";
          c = f.homeConfigurations.cbox.config;
        in {
          service = c.systemd.user.services.cbox-btrfs-watch;
          timer = c.systemd.user.timers.cbox-btrfs-watch;
          serviceFile = toString c.home.file."${c.xdg.configHome}/systemd/user/cbox-btrfs-watch.service".source;
          timerFile = toString c.home.file."${c.xdg.configHome}/systemd/user/cbox-btrfs-watch.timer".source;
          retentionServices = builtins.filter (n: builtins.match "cbox-retention-.*" n != null) (builtins.attrNames c.systemd.user.services);
          retentionTimers = builtins.filter (n: builtins.match "cbox-retention-.*" n != null) (builtins.attrNames c.systemd.user.timers);
          retentionFiles = builtins.filter (n: builtins.match ".*cbox-retention-.*" n != null) (builtins.attrNames c.home.file);
        }''' % REPO
        result = subprocess.run(
            ["nix", "eval", "--offline", "--impure", "--no-write-lock-file", "--json", "--expr", expression],
            cwd=REPO, capture_output=True, text=True, timeout=120, env=os.environ.copy(),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        units = json.loads(result.stdout)
        service = units["service"]["Service"]
        command = service["ExecStart"]
        if isinstance(command, list):
            self.assertEqual(len(command), 1)
            command = command[0]
        self.assertIn("/nix/store/", command)
        self.assertIn("cbox-btrfs-watch.py", command)
        self.assertIn("--uuid 12019150-ad54-405b-b8e7-ffa3a112ed02", command)
        self.assertIn("--state-dir %h/.local/state/btrfs-watch", command)
        for flag in ("--btrfs", "--findmnt", "--notify-send"):
            self.assertIn(flag, command)
        for forbidden in ("--apply", "balance", "snapshot", "prune", "retention"):
            self.assertNotIn(forbidden, command)
        self.assertEqual(service["Type"], "oneshot")
        self.assertTrue(service["NoNewPrivileges"])
        self.assertEqual(service["UMask"], "0077")
        timer = units["timer"]
        self.assertEqual(timer["Timer"]["OnUnitActiveSec"], "5min")
        self.assertEqual(timer["Timer"]["RandomizedDelaySec"], "20s")
        self.assertEqual(timer["Timer"]["AccuracySec"], "10s")
        self.assertEqual(timer["Timer"]["Unit"], "cbox-btrfs-watch.service")
        self.assertIn("timers.target", timer["Install"]["WantedBy"])
        self.assertTrue(units["serviceFile"].startswith("/nix/store/"))
        self.assertTrue(units["timerFile"].startswith("/nix/store/"))
        self.assertEqual(units["retentionServices"], [], "Suspended cleanup services must not be installed")
        self.assertEqual(units["retentionTimers"], [], "Suspended cleanup timers must not be installed")
        self.assertEqual(units["retentionFiles"], [], "Suspended cleanup unit links must not be installed")


if __name__ == "__main__":
    unittest.main()

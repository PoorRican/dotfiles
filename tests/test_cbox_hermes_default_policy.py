"""Preserve cbox's explicitly approved live default-profile settings."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CboxDefaultPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expression = r'''f: builtins.mapAttrs (_: h:
          let s = h.config.programs.hermes.profiles.default.settings; in {
            multiplex = s.gateway.multiplex_profiles or null;
            destructive_confirm = s.approvals.destructive_slash_confirm or null;
            busy_input = s.display.busy_input_mode or null;
          }) f'''
        result = subprocess.run(
            ["nix", "eval", "--json", "--no-write-lock-file",
             "git+file://" + str(ROOT) + "#homeConfigurations", "--apply", expression],
            capture_output=True, text=True, check=True, timeout=180)
        cls.hosts = json.loads(result.stdout)

    def test_cbox_retains_per_profile_gateways(self):
        self.assertIs(self.hosts["cbox"]["multiplex"], False)

    def test_cbox_retains_disabled_destructive_slash_confirmation(self):
        self.assertIs(self.hosts["cbox"]["destructive_confirm"], False)

    def test_cbox_retains_interrupt_busy_input(self):
        self.assertEqual(self.hosts["cbox"]["busy_input"], "interrupt")

    def test_preservation_override_does_not_change_other_hosts(self):
        for host, settings in self.hosts.items():
            if host != "cbox":
                with self.subTest(host=host):
                    self.assertIsNone(settings["multiplex"])
                    self.assertIsNone(settings["destructive_confirm"])
                    self.assertEqual(settings["busy_input"], "steer")


if __name__ == "__main__":
    unittest.main()

"""Evaluate the real cbox profile; run with python3 -m unittest discover -s scripts/hermes -p test_hindsight_config.py."""
import json
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]


class HindsightConfigTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        uri = "git+file://" + str(ROOT)
        expression = """
        let
          f = builtins.getFlake %s;
          c = f.homeConfigurations.cbox.config;
          p = c.programs.hermes.profiles.k-research-agent;
        in {
          memory = p.settings.memory or {};
          files = builtins.attrNames p.files;
          connection = if p.files ? "hindsight/config.json"
            then builtins.fromJSON p.files."hindsight/config.json" else {};
          defaultMemory = c.programs.hermes.profiles.default.settings.memory or {};
          defaultFiles = builtins.attrNames c.programs.hermes.profiles.default.files;
          tunnel = c.systemd.user.services.hindsight-tunnel-k-research-agent or {};
          gatewayUnit = c.systemd.user.services.hermes-gateway-k-research-agent.Unit;
          extras = c.programs.hermes.package.hindsightDependencyNames or [];
          packageVersion = c.programs.hermes.package.version;
        }
        """ % json.dumps(uri)
        result = subprocess.run(
            ["nix", "eval", "--json", "--impure", "--no-write-lock-file", "--expr", expression],
            check=True, capture_output=True, text=True, timeout=120,
        )
        cls.config = json.loads(result.stdout)

    def test_package_identity_meets_plugin_minimum(self):
        # 0.0.0 is a packaging fallback, not the release lineage of this pin.
        self.assertEqual(self.config["packageVersion"], "0.21.5")

    def test_hindsight_replaces_flat_store_without_changing_default_profile(self):
        self.assertEqual(self.config["memory"].get("provider"), "hindsight")
        self.assertFalse(self.config["memory"]["memory_enabled"])
        self.assertFalse(self.config["memory"]["user_profile_enabled"])
        self.assertNotEqual(self.config["defaultMemory"].get("provider"), "hindsight")
        self.assertFalse(any(path.startswith("plugins/hindsight/") or path == "hindsight/config.json"
                             for path in self.config["defaultFiles"]))

    def test_encrypted_tunnel_is_required_by_target_gateway(self):
        tunnel = self.config["tunnel"].get("Service", {})
        command = tunnel.get("ExecStart", "")
        if isinstance(command, list):
            self.assertEqual(len(command), 1)
            command = command[0]
        for argument in ["BatchMode=yes", "StrictHostKeyChecking=yes", "ExitOnForwardFailure=yes",
                         "127.0.0.1:18888:127.0.0.1:30520"]:
            self.assertIn(argument, command)
        self.assertTrue(command.endswith(" wst"))
        unit_name = "hindsight-tunnel-k-research-agent.service"
        self.assertIn(unit_name, self.config["gatewayUnit"].get("Requires", []))
        self.assertIn(unit_name, self.config["gatewayUnit"].get("After", []))

    def test_exact_existing_bank_and_same_turn_recall(self):
        connection = self.config["connection"]
        self.assertEqual(connection.get("mode"), "local_external")
        self.assertEqual(connection.get("api_url"), "http://127.0.0.1:18888")
        self.assertEqual(connection.get("bank_id"), "kairos-hindsight")
        self.assertEqual(connection.get("memory_mode"), "hybrid")
        self.assertTrue(connection.get("recall_sync"))
        self.assertTrue(connection.get("auto_retain"))
        self.assertTrue(connection.get("auto_recall"))
        self.assertEqual(set(connection.get("recall_types", [])), {"world", "experience", "observation"})
        for forbidden in ["api_key", "apiKey", "bank_mission", "bank_retain_mission", "bank_id_template"]:
            self.assertNotIn(forbidden, connection)

    def test_plugin_code_and_supplemental_packages_are_declared(self):
        for name in ["__init__.py", "embedded.py", "settings.py", "config_schema.py", "setup.py", "templates.py", "pyproject.toml", "plugin.yaml"]:
            self.assertIn("plugins/hindsight/" + name, self.config["files"])
        self.assertNotIn(".env", self.config["files"])
        self.assertEqual(set(self.config["extras"]), {"hindsight-client", "hindsight-embed", "aiohttp-retry"})


if __name__ == "__main__":
    unittest.main()

"""Verify anatomy's declarative target scope without activating Home Manager."""

import json
from pathlib import Path
import shutil
import subprocess
import unittest


REPO = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("nix"), "Nix is required for distribution checks")
class AnatomySkillAssignmentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expression = r'''let
          f = builtins.getFlake "path:REPO_PATH";
          prefix = ".omp/agent/skills/";
        in builtins.mapAttrs (_: home:
          let
            c = home.config;
            lib = f.inputs.nixpkgs.lib;
            keys = builtins.attrNames c.home.file;
          in {
            ompEnabled = c.programs.agent-skills.enable && c.programs.agent-skills.agents.omp;
            omp = map (key: lib.removePrefix prefix key)
              (builtins.filter (key: lib.hasPrefix prefix key) keys);
            managed = builtins.filter
              (key: lib.hasInfix ".omp/agent/managed-skills" key) keys;
          }
        ) f.homeConfigurations'''.replace("REPO_PATH", str(REPO))
        result = subprocess.run(
            [
                "nix", "eval", "--offline", "--no-write-lock-file", "--impure",
                "--json", "--expr", expression,
            ],
            cwd=REPO,
            check=True,
            capture_output=True,
            text=True,
            timeout=180,
        )
        cls.hosts = json.loads(result.stdout)

    def test_each_enabled_omp_receives_anatomy(self):
        for host, config in self.hosts.items():
            with self.subTest(host=host):
                if config["ompEnabled"]:
                    self.assertEqual(config["omp"].count("anatomy"), 1)

    def test_omp_managed_skill_root_is_not_owned(self):
        for host, config in self.hosts.items():
            with self.subTest(host=host):
                self.assertEqual(config["managed"], [])


if __name__ == "__main__":
    unittest.main()

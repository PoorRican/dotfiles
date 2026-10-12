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
          targets = {
            claude = ".claude/skills/";
            codex = ".codex/skills/";
            pi = ".pi/agent/skills/";
            omp = ".omp/agent/skills/";
            opencode = ".config/opencode/skills/";
          };
        in builtins.mapAttrs (_: home:
          let
            c = home.config;
            lib = f.inputs.nixpkgs.lib;
            keys = builtins.attrNames c.home.file;
          in {
            ompEnabled = c.programs.agent-skills.enable && c.programs.agent-skills.agents.omp;
            agents = builtins.mapAttrs (_: prefix:
              map (key: lib.removePrefix prefix key)
                (builtins.filter (key: lib.hasPrefix prefix key) keys)
            ) targets;
            managed = builtins.filter
              (key: lib.hasInfix ".omp/agent/managed-skills" key) keys;
            profiles = builtins.mapAttrs (_: profile: {
              inherit (profile) enable;
              inherit (profile.skills) names;
            }) c.programs.hermes.profiles;
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

    def test_research_profile_selects_anatomy(self):
        profile = self.hosts["cbox"]["profiles"]["k-research-agent"]
        self.assertTrue(profile["enable"])
        self.assertEqual(profile["names"].count("anatomy"), 1)

    def test_each_enabled_omp_receives_anatomy(self):
        for host, config in self.hosts.items():
            with self.subTest(host=host):
                if config["ompEnabled"]:
                    self.assertEqual(config["agents"]["omp"].count("anatomy"), 1)

    def test_other_agents_and_profiles_do_not_receive_anatomy(self):
        for host, config in self.hosts.items():
            for agent, names in config["agents"].items():
                if agent != "omp":
                    with self.subTest(host=host, agent=agent):
                        self.assertNotIn("anatomy", names)
            for profile, settings in config["profiles"].items():
                if profile != "k-research-agent":
                    with self.subTest(host=host, profile=profile):
                        self.assertNotIn("anatomy", settings["names"])

    def test_existing_shared_coding_selection_is_preserved(self):
        for host, config in self.hosts.items():
            if not config["ompEnabled"]:
                continue
            omp_shared = set(config["agents"]["omp"]) - {"anatomy"}
            for agent, names in config["agents"].items():
                if agent != "omp" and names:
                    with self.subTest(host=host, agent=agent):
                        self.assertEqual(omp_shared, set(names))

    def test_omp_managed_skill_root_is_not_owned(self):
        for host, config in self.hosts.items():
            with self.subTest(host=host):
                self.assertEqual(config["managed"], [])


if __name__ == "__main__":
    unittest.main()

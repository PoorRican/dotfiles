"""Run with: python3 -m unittest scripts.hermes.test_capture_profile."""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "capture_profile", Path(__file__).with_name("capture-profile.py")
)
capture = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(capture)


class CaptureProfileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.home = self.root / "profile"
        self.home.mkdir()
        self.deployed = self.root / "deployed-skills"
        skill = self.deployed / "research" / "example-skill"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("# Example\n", encoding="utf-8")
        (skill / "guide.txt").write_text("guide\n", encoding="utf-8")
        self.declared_config = self.root / "declared-config.yaml"
        self.live_config = self.home / "config.yaml"
        self.write_config(self.declared_config, [self.deployed])
        self.write_config(self.live_config, [self.deployed])
        self.info_path = self.root / "deployment-info.json"
        self.write_deployment_info()
        self.output = self.root / "capture-output"

    def write_config(self, path, external_dirs, *, config_version=49):
        import hermes_yaml

        path.write_text(
            hermes_yaml.safe_dump(
                {
                    "_config_version": config_version,
                    "skills": {"external_dirs": external_dirs if isinstance(external_dirs, str) else [str(item) for item in external_dirs]},
                    "private_value": "must not enter manifest",
                },
                sort_keys=False,
            ),
            encoding="utf-8",
        )

    def write_deployment_info(self, *, skill_directory=None):
        self.info_path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "package": "/nix/store/hermes-agent",
                    "hermes_revision": "hermes-revision",
                    "agent_profiles_revision": "profiles-revision",
                    "source_revisions": {"private_skills": "source-revision", "dotfiles": None},
                    "profiles": {
                        "default": {
                            "home": str(self.home),
                            "config_file": str(self.declared_config),
                            "skills_directory": str(skill_directory or self.deployed),
                        }
                    },
                }
            ),
            encoding="utf-8",
        )

    def write_ledger(self, entries=None, *, raw=None):
        ledger = self.home / "skills" / ".curator_ledger.jsonl"
        ledger.parent.mkdir(parents=True, exist_ok=True)
        content = raw if raw is not None else "".join(
            json.dumps(entry, separators=(",", ":")) + "\n" for entry in entries
        )
        ledger.write_bytes(content.encode("utf-8") if isinstance(content, str) else content)
        return ledger

    @staticmethod
    def ledger_record(identifier, skill, *, before=(), after=()):
        return {
            "id": f"{identifier:012x}",
            "ts": "2026-10-05T12:00:00+00:00",
            "actor": "user",
            "action": "edit",
            "skill": skill,
            "evidence": {},
            "before": list(before),
            "after": list(after),
        }

    @staticmethod
    def ledger_file(path, digest):
        return {"path": str(path), "sha256": digest}

    def run_capture(self, *, sources=(), output=None):
        return capture.capture_profile(
            self.info_path,
            profile="default",
            source_specs=list(sources),
            output=output or self.output,
            hostname="test-host",
        )

    def new_git_repo(self, name):
        repo = self.root / name
        repo.mkdir()
        self.git(repo, "init", "-q")
        return repo

    def commit_git(self, repo):
        self.git(repo, "add", "-A")
        self.git(
            repo,
            "-c", "user.name=Test",
            "-c", "user.email=test@example.invalid",
            "commit", "-qm", "fixture",
        )

    def test_git_snapshot_includes_untracked_but_not_ignored_or_deleted_files(self):
        repo = self.root / "repo"
        repo.mkdir()
        self.git(repo, "init", "-q")
        (repo / "tracked.txt").write_text("tracked\n", encoding="utf-8")
        (repo / "to-delete.txt").write_text("gone\n", encoding="utf-8")
        (repo / ".gitignore").write_text("ignored.txt\n", encoding="utf-8")
        self.git(repo, "add", ".")
        self.git(repo, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture")
        (repo / "to-delete.txt").unlink()
        (repo / "untracked\nname.txt").write_text("new\n", encoding="utf-8")
        (repo / "ignored.txt").write_text("ignored\n", encoding="utf-8")
        (repo / ".env").write_text("credential-value\n", encoding="utf-8")

        index = repo / ".git" / "index"
        index_before = index.stat()
        manifest = self.run_capture(sources=[f"checkout={repo}"])

        copied = self.output / "sources" / "checkout"
        self.assertEqual((copied / "tracked.txt").read_text(), "tracked\n")
        self.assertEqual((copied / "untracked\nname.txt").read_text(), "new\n")
        self.assertFalse((copied / "ignored.txt").exists())
        self.assertFalse((copied / ".env").exists())
        self.assertFalse((copied / ".git").exists())
        self.assertFalse((copied / "to-delete.txt").exists())
        git = manifest["sources"][0]["git"]
        self.assertIn("to-delete.txt", git["deleted_tracked_paths"])
        self.assertTrue(any(item["path"] == "untracked\nname.txt" for item in git["status"]))
        index_after = index.stat()
        self.assertEqual(
            (index_after.st_ino, index_after.st_size, index_after.st_mtime_ns),
            (index_before.st_ino, index_before.st_size, index_before.st_mtime_ns),
        )
        self.assertNotIn("credential-value", (self.output / "manifest.json").read_text())

    def test_deleted_and_renamed_tracked_parent_directories_are_reported(self):
        repo = self.new_git_repo("directory-changes")
        removed = repo / "skills" / "old"
        removed.mkdir(parents=True)
        (removed / "SKILL.md").write_text("# removed\n", encoding="utf-8")
        renamed = repo / "skills" / "before"
        renamed.mkdir()
        (renamed / "SKILL.md").write_text("# moved\n", encoding="utf-8")
        (repo / "keep.txt").write_text("keep\n", encoding="utf-8")
        self.commit_git(repo)

        shutil.rmtree(removed)
        renamed.rename(repo / "skills" / "after")

        manifest = self.run_capture(sources=[f"checkout={repo}"])

        git = manifest["sources"][0]["git"]
        self.assertIn("skills/old/SKILL.md", git["deleted_tracked_paths"])
        self.assertIn("skills/before/SKILL.md", git["deleted_tracked_paths"])
        copied = self.output / "sources/checkout"
        self.assertEqual((copied / "skills/after/SKILL.md").read_text(), "# moved\n")
        self.assertFalse((copied / "skills/old/SKILL.md").exists())
        self.assertEqual((copied / "keep.txt").read_text(), "keep\n")

    def test_git_single_file_source_has_a_verifiable_destination(self):
        repo = self.new_git_repo("single-file")
        (repo / "notes.md").write_text("notes\n", encoding="utf-8")
        self.commit_git(repo)

        manifest = self.run_capture(sources=[f"note={repo / 'notes.md'}"])

        destination = self.output / "sources/note/notes.md"
        self.assertEqual(destination.read_text(encoding="utf-8"), "notes\n")
        record = next(item for item in manifest["files"] if item["scope"] == "source:note")
        self.assertEqual(record["path"], "sources/note/notes.md")
        for item in manifest["files"]:
            copied = self.output / item["path"]
            with copied.open("rb") as source:
                self.assertEqual(hashlib.sha256(source.read()).hexdigest(), item["sha256"])

    def test_explicit_gitignored_file_is_reported_but_never_copied(self):
        repo = self.new_git_repo("ignored-file")
        (repo / ".gitignore").write_text("local.yaml\n", encoding="utf-8")
        self.commit_git(repo)
        (repo / "local.yaml").write_text("private config\n", encoding="utf-8")

        manifest = self.run_capture(sources=[f"cfg={repo / 'local.yaml'}"])

        self.assertFalse((self.output / "sources/cfg").exists())
        self.assertFalse(any(item["scope"] == "source:cfg" for item in manifest["files"]))
        self.assertTrue(any(
            item["scope"] == "source:cfg"
            and item["path"] == "local.yaml"
            and item["reason"] == "gitignored"
            for item in manifest["skipped"]
        ))

    def test_broken_git_metadata_fails_closed_and_git_locale_is_deterministic(self):
        broken = self.root / "broken-worktree"
        broken.mkdir()
        (broken / ".git").write_text("gitdir: /nonexistent/worktrees/broken\n", encoding="utf-8")
        (broken / "notes.txt").write_text("must not be copied as non-Git\n", encoding="utf-8")
        with self.assertRaises(capture.CaptureError):
            self.run_capture(sources=[f"broken={broken}"])
        self.assertFalse(self.output.exists())
        broken_head = self.new_git_repo("missing-head")
        (broken_head / ".git" / "HEAD").unlink()
        (broken_head / "notes.txt").write_text("not a valid unborn repository\n", encoding="utf-8")
        with self.assertRaises(capture.CaptureError):
            self.run_capture(sources=[f"broken-head={broken_head}"])
        self.assertFalse(self.output.exists())

        plain = self.root / "plain-tree"
        plain.mkdir()
        (plain / "notes.txt").write_text("plain\n", encoding="utf-8")
        unborn = self.new_git_repo("unborn")
        locale_output = self.root / "locale-capture"
        with patch.dict(os.environ, {"LANG": "fr_FR.UTF-8", "LANGUAGE": "fr"}):
            manifest = self.run_capture(
                sources=[f"plain={plain}", f"unborn={unborn}"],
                output=locale_output,
            )

        self.assertEqual((locale_output / "sources/plain/notes.txt").read_text(), "plain\n")
        self.assertIsNone(manifest["sources"][1]["git"]["head"])

    def test_credentials_are_excluded_in_git_non_git_and_selected_descendants(self):
        repo = self.new_git_repo("credential-git")
        git_dotenv = repo / "config" / ".env.d" / "production"
        git_dotenv.parent.mkdir(parents=True)
        git_dotenv.write_text("secret\n", encoding="utf-8")
        git_credentials = repo / "credentials.d" / "token"
        git_credentials.parent.mkdir()
        git_credentials.write_text("token\n", encoding="utf-8")
        nested = repo / "config" / ".env.d" / "subdir"
        nested.mkdir()
        (nested / "local.yaml").write_text("secret\n", encoding="utf-8")

        plain = self.root / "credential-plain"
        (plain / "config" / ".env.d").mkdir(parents=True)
        (plain / "config" / ".env.d" / "production").write_text("secret\n", encoding="utf-8")
        (plain / "credentials.d").mkdir()
        (plain / "credentials.d" / "token").write_text("token\n", encoding="utf-8")

        manifest = self.run_capture(sources=[
            f"git={repo}",
            f"plain={plain}",
            f"nested={nested}",
        ])

        for label in ("git", "plain", "nested"):
            source_dir = self.output / f"sources/{label}"
            self.assertFalse(source_dir.exists() and any(path.is_file() for path in source_dir.rglob("*")))
        skipped = manifest["skipped"]
        self.assertTrue(any(
            item["scope"] == "source:git"
            and item["path"] == "config/.env.d/production"
            and item["reason"] == "credential-excluded"
            for item in skipped
        ))
        self.assertTrue(any(
            item["scope"] == "source:git"
            and item["path"] == "credentials.d/token"
            and item["reason"] == "credential-excluded"
            for item in skipped
        ))
        self.assertTrue(any(
            item["scope"] == "source:plain"
            and item["path"] == "sources/plain/config/.env.d"
            and item["reason"] == "credential-excluded"
            for item in skipped
        ))
        self.assertTrue(any(
            item["scope"] == "source:plain"
            and item["path"] == "sources/plain/credentials.d"
            and item["reason"] == "credential-excluded"
            for item in skipped
        ))
        self.assertTrue(any(
            item["scope"] == "source:nested"
            and item["reason"] == "credential-excluded"
            for item in skipped
        ))

    def test_single_bundle_source_root_is_compared_with_deployed_skill(self):
        source_bundle = self.root / "one" / "example-skill"
        source_bundle.parent.mkdir()
        shutil.copytree(self.deployed / "research/example-skill", source_bundle)
        (source_bundle / "guide.txt").write_text("edited at source\n", encoding="utf-8")

        manifest = self.run_capture(sources=[f"one={source_bundle}"])

        self.assertEqual(len(manifest["source_vs_deployed"]), 1)
        comparison = manifest["source_vs_deployed"][0]
        self.assertEqual(comparison["match"], "matched")
        self.assertEqual(comparison["name"], "example-skill")
        self.assertIn(
            {"path": "guide.txt", "status": "changed"},
            [
                {"path": item["path"], "status": item["status"]}
                for item in comparison["differences"]
            ],
        )
        self.assertGreaterEqual(manifest["summary"]["source_skill_difference_count"], 1)

    def test_runtime_noise_names_are_preserved_in_git_sources(self):
        repo = self.new_git_repo("source-noise-names")
        (repo / "flake.lock").write_text('{"nodes":{}}\n', encoding="utf-8")
        cache = repo / "cache"
        cache.mkdir()
        (cache / "data.txt").write_text("reviewed source\n", encoding="utf-8")
        self.commit_git(repo)

        manifest = self.run_capture(sources=[f"profiles={repo}"])

        copied = self.output / "sources/profiles"
        self.assertEqual((copied / "flake.lock").read_text(), '{"nodes":{}}\n')
        self.assertEqual((copied / "cache/data.txt").read_text(), "reviewed source\n")
        paths = {item["path"] for item in manifest["files"] if item["scope"] == "source:profiles"}
        self.assertIn("sources/profiles/flake.lock", paths)
        self.assertIn("sources/profiles/cache/data.txt", paths)

    def test_ignored_directory_is_one_skipped_manifest_entry(self):
        repo = self.new_git_repo("ignored-directory")
        (repo / ".gitignore").write_text("build/\n", encoding="utf-8")
        build = repo / "build"
        build.mkdir()
        for index in range(50):
            (build / f"artifact-{index}.bin").write_bytes(b"x")
        self.commit_git(repo)

        manifest = self.run_capture(sources=[f"build={repo}"])

        ignored = [
            item for item in manifest["skipped"]
            if item["scope"] == "source:build" and item["reason"] == "gitignored"
        ]
        self.assertEqual([item["path"] for item in ignored], ["build/"])
        self.assertFalse((self.output / "sources/build/build").exists())

    def test_runtime_learning_history_and_deployed_skill_inventory_are_distinct(self):
        (self.home / "memories").mkdir()
        (self.home / "memories" / "USER.md").write_text("learned\n", encoding="utf-8")
        (self.home / "memories" / "session.lock").write_text("lock\n", encoding="utf-8")
        overlay = self.home / "skills" / "personal"
        overlay.mkdir(parents=True)
        (overlay / "SKILL.md").write_text("runtime overlay\n", encoding="utf-8")
        runtime_cache = self.home / "skills" / "cache"
        runtime_cache.mkdir()
        (runtime_cache / "content.bin").write_text("cache\n", encoding="utf-8")
        old_backups = self.home / "skills" / ".curator_backups"
        old_backups.mkdir()
        (old_backups / "old-snapshot").write_text("exclude\n", encoding="utf-8")
        history = self.home / ".curator_backups" / "blobs"
        history.mkdir(parents=True)
        history_bytes = b"history\n"
        history_hash = hashlib.sha256(history_bytes).hexdigest()
        (history / history_hash).write_bytes(history_bytes)
        self.write_ledger([
            self.ledger_record(
                1,
                "personal",
                before=[self.ledger_file(overlay / "SKILL.md", history_hash)],
            )
        ])
        (self.home / "SOUL.md").write_text("runtime soul\n", encoding="utf-8")

        manifest = self.run_capture()

        self.assertEqual((self.output / "runtime/memories/USER.md").read_text(), "learned\n")
        self.assertEqual((self.output / "runtime/skills/personal/SKILL.md").read_text(), "runtime overlay\n")
        self.assertEqual(
            (self.output / "runtime" / "skill-history" / history_hash).read_bytes(),
            history_bytes,
        )
        self.assertEqual((self.output / "runtime/SOUL.md").read_text(), "runtime soul\n")
        self.assertFalse((self.output / "runtime/skills/.curator_backups/old-snapshot").exists())
        self.assertFalse((self.output / "runtime/skills/cache").exists())
        self.assertFalse((self.output / "runtime/memories/session.lock").exists())
        self.assertTrue(any(item["reason"] == "cache-or-temporary-directory-excluded" for item in manifest["skipped"]))
        self.assertTrue(any(item["reason"] == "lock-or-temporary-file-excluded" for item in manifest["skipped"]))
        bundles = manifest["deployed_skills"]["bundles"]
        self.assertEqual(len(bundles), 1)
        self.assertEqual(bundles[0]["name"], "example-skill")
        expected = hashlib.sha256((self.deployed / "research/example-skill/guide.txt").read_bytes()).hexdigest()
        self.assertEqual(bundles[0]["files"]["guide.txt"]["sha256"], expected)
        for record in manifest["files"]:
            copied = self.output / record["path"]
            self.assertEqual(hashlib.sha256(copied.read_bytes()).hexdigest(), record["sha256"])
        self.assertFalse((self.output / "deployed").exists())



    def test_history_copies_only_safe_referenced_and_verified_blobs(self):
        blobs = self.home / ".curator_backups" / "blobs"
        blobs.mkdir(parents=True)
        payloads = {
            "safe": b"safe historical skill bytes\n",
            "env": b"SYNTHETIC_ENV_SECRET",
            "credentials": b"SYNTHETIC_CREDENTIALS_SECRET",
            "pem": b"SYNTHETIC_PRIVATE_KEY",
            "mixed": b"SYNTHETIC_MIXED_SECRET",
            "skill-name": b"SYNTHETIC_SECRET_SKILL",
            "nested-cache-mixed": b"SYNTHETIC_NESTED_CACHE_ENV",
            "orphan": b"SYNTHETIC_ORPHAN",
        }
        hashes = {
            name: hashlib.sha256(content).hexdigest()
            for name, content in payloads.items()
        }
        for name, content in payloads.items():
            (blobs / hashes[name]).write_bytes(content)
        safe_path = self.home / "skills" / "safe-skill" / "README.md"
        env_path = self.home / "skills" / ".env"
        credentials_path = self.home / "skills" / "account" / "credentials.json"
        pem_path = self.home / "skills" / "private.pem"
        mixed_safe_path = self.home / "skills" / "safe-skill" / "notes.txt"
        cache_env_path = self.home / "skills" / "cache" / ".env"
        self.write_ledger([
            self.ledger_record(1, "safe-skill", before=[self.ledger_file(safe_path, hashes["safe"])]),
            self.ledger_record(2, "safe-skill", before=[self.ledger_file(env_path, hashes["env"])]),
            self.ledger_record(3, "safe-skill", after=[self.ledger_file(credentials_path, hashes["credentials"])]),
            self.ledger_record(4, "safe-skill", before=[self.ledger_file(pem_path, hashes["pem"])]),
            self.ledger_record(
                5,
                "safe-skill",
                before=[self.ledger_file(env_path, hashes["mixed"])],
                after=[self.ledger_file(mixed_safe_path, hashes["mixed"])],
            ),
            self.ledger_record(
                6,
                ".env",
                after=[self.ledger_file(mixed_safe_path, hashes["skill-name"])],
            ),
            self.ledger_record(
                7,
                "safe-skill",
                before=[self.ledger_file(cache_env_path, hashes["nested-cache-mixed"])],
                after=[self.ledger_file(mixed_safe_path, hashes["nested-cache-mixed"])],
            ),
        ])

        manifest = self.run_capture()

        copied_hashes = {
            path.name
            for path in (self.output / "runtime" / "skill-history").glob("*")
        }
        self.assertEqual(copied_hashes, {hashes["safe"]})
        self.assertEqual(
            (self.output / "runtime" / "skill-history" / hashes["safe"]).read_bytes(),
            payloads["safe"],
        )
        history_skips = [
            item for item in manifest["skipped"]
            if item["scope"] == "runtime:skill-history"
        ]
        reasons = {item["path"].rsplit("/", 1)[-1]: item["reason"] for item in history_skips}
        for name in ("env", "credentials", "pem", "mixed", "skill-name", "nested-cache-mixed"):
            self.assertEqual(reasons[hashes[name]], "credential-referenced-history-blob")
        self.assertEqual(reasons[hashes["orphan"]], "unreferenced-history-blob")
        text = (self.output / "manifest.json").read_text(encoding="utf-8")
        for content in payloads.values():
            try:
                marker = content.decode("utf-8")
            except UnicodeDecodeError:
                continue
            self.assertNotIn(marker, text)

    def test_missing_ledger_omits_unverifiable_history(self):
        blob = self.home / ".curator_backups" / "blobs" / ("a" * 64)
        blob.parent.mkdir(parents=True)
        blob.write_bytes(b"unverifiable historical bytes")

        manifest = self.run_capture()

        self.assertFalse((self.output / "runtime" / "skill-history" / ("a" * 64)).exists())
        self.assertTrue(any(
            item["scope"] == "runtime:skill-history"
            and item["reason"] == "ledger-missing-unverifiable-history"
            for item in manifest["skipped"]
        ))
        self.assertEqual(manifest["skill_history"]["ledger_status"], "missing")

    def test_malformed_ledger_fails_closed_without_parser_details(self):
        self.write_ledger(raw='{"untrusted":"PARSER_SECRET')

        with self.assertRaises(capture.CaptureError) as error:
            self.run_capture()

        self.assertNotIn("PARSER_SECRET", str(error.exception))
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.root.glob(".hermes-capture-*")), [])

    def test_malformed_ledger_hash_and_path_are_rejected(self):
        invalid_references = [
            {"path": str(self.home / "skills" / "skill" / "README.md"), "sha256": "not-a-hash"},
            {"path": str(self.home / "skills" / ".." / "outside.txt"), "sha256": "a" * 64},
            {"path": str(self.root / "outside.txt"), "sha256": "a" * 64},
        ]
        for index, reference in enumerate(invalid_references, start=1):
            with self.subTest(index=index):
                output = self.root / f"invalid-ledger-{index}"
                self.write_ledger([
                    self.ledger_record(index, "safe-skill", before=[reference])
                ])

                with self.assertRaises(capture.CaptureError):
                    self.run_capture(output=output)

                self.assertFalse(output.exists())
                self.assertEqual(list(self.root.glob(".hermes-capture-*")), [])

    def test_history_blob_checksum_mismatch_fails_closed(self):
        expected_content = b"known original historical bytes"
        digest = hashlib.sha256(expected_content).hexdigest()
        self.write_ledger([
            self.ledger_record(
                1,
                "safe-skill",
                before=[self.ledger_file(self.home / "skills" / "safe-skill" / "README.md", digest)],
            )
        ])
        blob = self.home / ".curator_backups" / "blobs" / digest
        blob.parent.mkdir(parents=True)
        blob.write_bytes(b"replacement bytes must not be accepted")

        with self.assertRaises(capture.CaptureError):
            self.run_capture()

        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.root.glob(".hermes-capture-*")), [])

    def test_external_skill_dirs_match_hermes_normalization_and_record_drift(self):
        env_skills = self.root / "env-skills"
        tilde_skills = self.root / "tilde-skills"
        relative_skills = self.home / "relative-skills"
        stale_skills = self.root / "stale-skills"
        unsafe_alias = self.root / "mutable-symlink"
        for directory, name in (
            (env_skills, "environment"),
            (tilde_skills, "tilde"),
            (relative_skills, "relative"),
        ):
            bundle = directory / name
            bundle.mkdir(parents=True)
            (bundle / "SKILL.md").write_text(f"# {name}\n", encoding="utf-8")
        local_skills = self.home / "skills"
        local_skills.mkdir()
        unsafe_alias.symlink_to(env_skills, target_is_directory=True)
        environment = {"HOME": str(self.root), "CAPTURE_SKILLS": str(env_skills)}

        self.write_config(self.live_config, "$CAPTURE_SKILLS")
        scalar_output = self.root / "scalar-capture"
        with patch.dict(os.environ, environment):
            scalar_manifest = self.run_capture(output=scalar_output)
        self.assertEqual(scalar_manifest["actual_skill_directories"], [str(env_skills)])

        self.write_config(
            self.live_config,
            [
                "$CAPTURE_SKILLS",
                str(env_skills),
                "~/tilde-skills",
                "relative-skills",
                str(local_skills),
                str(stale_skills),
                str(unsafe_alias),
            ],
        )
        with patch.dict(os.environ, environment):
            manifest = self.run_capture()

        self.assertEqual(
            manifest["actual_skill_directories"],
            [str(env_skills), str(tilde_skills), str(relative_skills)],
        )
        self.assertIn(str(stale_skills), manifest["configured_skill_directories"])
        discrepancies = manifest["drift"]["deployed_skill_discrepancies"]
        self.assertTrue(any("missing" in item and str(stale_skills) in item for item in discrepancies))
        self.assertTrue(any("symlink" in item and str(unsafe_alias) in item for item in discrepancies))
        self.assertTrue(any(
            item["reason"] == "configured-skill-directory-missing"
            and item["original_path"] == str(stale_skills)
            for item in manifest["skipped"]
        ))
        self.assertTrue(any(
            item["reason"] == "unsafe-symlink-skill-directory"
            and item["original_path"] == str(unsafe_alias)
            for item in manifest["skipped"]
        ))
    def test_source_skill_file_differences_match_deployed_bundle_identity(self):
        source_root = self.root / "source-skills"
        source_skill = source_root / "example-skill"
        source_skill.mkdir(parents=True)
        (source_skill / "SKILL.md").write_text("# Example source\n", encoding="utf-8")
        (source_skill / "guide.txt").write_text("edited guide\n", encoding="utf-8")
        (source_skill / "references").mkdir()
        (source_skill / "references" / "new.txt").write_text("new source file\n", encoding="utf-8")

        manifest = self.run_capture(sources=[f"kairos-skills={source_root}"])

        comparison = manifest["source_vs_deployed"][0]
        self.assertEqual(comparison["match"], "matched")
        self.assertEqual(comparison["name"], "example-skill")
        statuses = {item["path"]: item["status"] for item in comparison["differences"]}
        self.assertEqual(statuses["SKILL.md"], "changed")
        self.assertEqual(statuses["guide.txt"], "changed")
        self.assertEqual(statuses["references/new.txt"], "missing-from-deployed")
        self.assertEqual(manifest["provenance"]["source_revisions"]["private_skills"], "source-revision")

    def test_cli_publishes_review_only_manifest_and_reports_actual_path_and_counts(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            status = capture.main([
                "--deployment-info", str(self.info_path),
                "--profile", "default",
                "--output", str(self.output),
            ])

        self.assertEqual(status, 0)
        self.assertIn(str(self.output), output.getvalue())
        self.assertIn("files=", output.getvalue())
        self.assertIn("drift_mismatches=", output.getvalue())
        manifest = json.loads((self.output / "manifest.json").read_text(encoding="utf-8"))
        self.assertTrue(manifest["review_only"])
        self.assertFalse(manifest["promotion"])
        self.assertEqual(manifest["snapshot_path"], str(self.output))
        self.assertTrue((self.output.stat().st_mode & 0o777) == 0o700)
        for record in manifest["files"]:
            copied = self.output / record["path"]
            self.assertEqual(hashlib.sha256(copied.read_bytes()).hexdigest(), record["sha256"])
            self.assertEqual(copied.stat().st_mode & 0o777, 0o600)

    def test_live_config_and_skill_directory_drift_are_recorded_without_config_contents(self):
        actual = self.root / "actual-skills"
        (actual / "creative" / "other-skill").mkdir(parents=True)
        (actual / "creative" / "other-skill" / "SKILL.md").write_text("# Other\n", encoding="utf-8")
        self.write_config(self.live_config, [actual])

        manifest = self.run_capture()

        drift = manifest["drift"]
        self.assertFalse(drift["config_matches_declared"])
        self.assertFalse(drift["skill_directories_match_declared"])
        text = (self.output / "manifest.json").read_text(encoding="utf-8")
        self.assertNotIn("must not enter manifest", text)
        self.assertEqual(manifest["configured_skill_directory"], str(self.deployed))
        self.assertEqual(manifest["actual_skill_directories"], [str(actual)])

    def test_live_config_version_metadata_only_keeps_integers(self):
        valid_output = self.root / "valid-capture"
        valid_manifest = self.run_capture(output=valid_output)
        self.assertEqual(valid_manifest["live_config_version"], 49)

        marker = "API_KEY_MARKER_must_not_escape"
        self.write_config(
            self.live_config,
            [self.deployed],
            config_version={"api_key": marker},
        )
        config_hash = hashlib.sha256(self.live_config.read_bytes()).hexdigest()

        manifest = self.run_capture()
        manifest_path = self.output / "manifest.json"
        manifest_text = manifest_path.read_text(encoding="utf-8")

        self.assertIsNone(manifest["live_config_version"])
        self.assertEqual(manifest["drift"]["configured_live_config_sha256"], config_hash)
        self.assertFalse(manifest["drift"]["config_matches_declared"])
        self.assertNotIn(marker, manifest_text)
        for path in self.output.rglob("*"):
            if path.is_file():
                self.assertNotIn(marker.encode(), path.read_bytes())
        self.write_config(self.live_config, [self.deployed], config_version=True)
        bool_manifest = self.run_capture(output=self.root / "bool-capture")
        self.assertIsNone(bool_manifest["live_config_version"])

    def test_symlinks_and_recognized_credentials_are_not_captured(self):
        source = self.root / "outside-git"
        source.mkdir()
        target = self.root / "secret-target"
        target.write_text("outside secret\n", encoding="utf-8")
        (source / "safe.txt").write_text("safe\n", encoding="utf-8")
        (source / ".ENV.production").write_text("credential\n", encoding="utf-8")
        (source / "client.PEM").write_text("private key\n", encoding="utf-8")
        (source / "escape.txt").symlink_to(target)

        self.run_capture(sources=[f"review={source}"])

        copied = self.output / "sources/review"
        self.assertEqual((copied / "safe.txt").read_text(), "safe\n")
        self.assertFalse((copied / ".ENV.production").exists())
        self.assertFalse((copied / "client.PEM").exists())
        self.assertFalse((copied / "escape.txt").exists())
        manifest = json.loads((self.output / "manifest.json").read_text())
        self.assertTrue(any(item["reason"] == "symlink-not-followed" for item in manifest["skipped"]))

    def test_output_overlap_and_existing_destination_are_refused_without_overwrite(self):
        existing = self.root / "existing"
        existing.mkdir()
        sentinel = existing / "sentinel"
        sentinel.write_text("preserve\n", encoding="utf-8")
        with self.assertRaises(capture.CaptureError):
            self.run_capture(output=existing)
        self.assertEqual(sentinel.read_text(), "preserve\n")

        with self.assertRaises(capture.CaptureError):
            self.run_capture(output=self.home / "inside-profile")
        self.assertFalse((self.home / "inside-profile").exists())
        with self.assertRaises(capture.CaptureError):
            self.run_capture(output=self.root)
        source = self.root / "source-input"
        source.mkdir()
        with self.assertRaises(capture.CaptureError):
            self.run_capture(sources=[f"source={source}"], output=source / "snapshot")
        self.assertFalse((source / "snapshot").exists())
        outside = self.root / "outside"
        outside.mkdir()
        link = self.root / "output-link"
        link.symlink_to(outside, target_is_directory=True)
        with self.assertRaises(OSError):
            self.run_capture(output=link / "nested" / "capture")
        self.assertEqual(list(outside.iterdir()), [])


    def test_failed_source_mutation_leaves_no_output_or_owned_staging(self):
        source = self.root / "mutating-source"
        source.mkdir()
        changing = source / "content.txt"
        changing.write_text("before\n", encoding="utf-8")
        source_stat = changing.stat()
        real_read = os.read
        changed = False

        def mutate_after_read(fd, size):
            nonlocal changed
            data = real_read(fd, size)
            opened_stat = os.fstat(fd)
            if (
                data
                and not changed
                and (opened_stat.st_dev, opened_stat.st_ino) == (source_stat.st_dev, source_stat.st_ino)
            ):
                changing.write_text("after with a different length\n", encoding="utf-8")
                changed = True
            return data

        with patch.object(capture.os, "read", side_effect=mutate_after_read):
            with self.assertRaises(capture.CaptureError):
                self.run_capture(sources=[f"changing={source}"])

        self.assertTrue(changed)
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.root.glob(".hermes-capture-*")), [])
    def test_failed_capture_preserves_staging_directory_replaced_during_cleanup(self):
        source = self.root / "changing"
        source.mkdir()
        changing = source / "content.txt"
        changing.write_text("before\n", encoding="utf-8")
        real_read = os.read
        real_open = os.open
        changed = False
        stage_name = None
        stage_open_count = 0
        swapped = False
        source_stat = changing.stat()

        def mutate_after_read(fd, size):
            nonlocal changed
            data = real_read(fd, size)
            opened_stat = os.fstat(fd)
            if (
                data
                and not changed
                and (opened_stat.st_dev, opened_stat.st_ino) == (source_stat.st_dev, source_stat.st_ino)
            ):
                changing.write_text("after with a different length\n", encoding="utf-8")
                changed = True
            return data

        def swap_before_cleanup_open(name, flags, *args, **kwargs):
            nonlocal stage_name, stage_open_count, swapped
            if (
                isinstance(name, str)
                and name.startswith(".hermes-capture-")
                and flags & getattr(os, "O_DIRECTORY", 0)
            ):
                if stage_name is None:
                    stage_name = name
                if name == stage_name:
                    stage_open_count += 1
                    if stage_open_count == 2:
                        parent_fd = kwargs["dir_fd"]
                        displaced_name = name + "-displaced"
                        os.rename(name, displaced_name, src_dir_fd=parent_fd, dst_dir_fd=parent_fd)
                        os.mkdir(name, dir_fd=parent_fd)
                        (self.root / name / "unrelated.txt").write_text(
                            "preserve me\n", encoding="utf-8"
                        )
                        swapped = True
            return real_open(name, flags, *args, **kwargs)

        with (
            patch.object(capture.os, "open", side_effect=swap_before_cleanup_open),
            patch.object(capture.os, "read", side_effect=mutate_after_read),
        ):
            with self.assertRaises(capture.CaptureError):
                self.run_capture(sources=[f"moving={source}"])

        self.assertTrue(changed)
        self.assertTrue(swapped)
        self.assertIsNotNone(stage_name)
        self.assertFalse(self.output.exists())
        self.assertEqual(
            (self.root / stage_name / "unrelated.txt").read_text(encoding="utf-8"),
            "preserve me\n",
        )
        self.assertTrue((self.root / f"{stage_name}-displaced").is_dir())

    def git(self, cwd, *args):
        env = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
        subprocess.run(
            ["git", "--no-optional-locks", "-C", str(cwd), "-c", "core.fsmonitor=false", *args],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )


if __name__ == "__main__":
    unittest.main()

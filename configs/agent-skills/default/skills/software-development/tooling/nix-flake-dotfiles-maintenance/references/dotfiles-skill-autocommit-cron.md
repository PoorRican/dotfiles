# Dotfiles skill autocommit cron pattern

Use this pattern when the user wants local-only automation that periodically snapshots skill-library changes from `~/dotfiles` without touching unrelated work.

## Goal

Create a Hermes cron job that commits only skill/references/templates/scripts changes from the dotfiles repo, and delays whenever the git index is already in use.

## Durable pattern

1. Put the deterministic logic in a local script under `~/.hermes/scripts/`.
   - Prefer `no_agent=true` cron jobs for commit/watchdog automation where the script can emit the exact message.
   - Use `deliver='local'` if the user says the job should be local-only.
2. Make the script repository-root-aware and path allowlist-based.
   - Resolve `~/dotfiles` and verify `git rev-parse --show-toplevel` matches.
   - Only allow repo-relative skill prefixes such as:
     - `configs/hermes/default/skills/`
     - `configs/claude-code/skills/`
     - future agent skill dirs, e.g. `configs/codex/agent/skills/`, `configs/pi/agent/skills/`, `configs/omp/agent/skills/`.
3. Exclude runtime bookkeeping that is not skill content.
   - Example: `configs/hermes/default/skills/.usage.json`
   - Example: `configs/hermes/default/skills/.curator_backups/`
4. Delay rather than mutate if the index is already staged.
   - Check `git diff --cached --quiet` before staging anything.
   - If staged changes exist, print a delay message and leave the index untouched.
5. Stage only the allowlisted paths.
   - Use porcelain status to discover tracked/untracked skill-path changes.
   - `git add -A -- <allowlisted paths>`.
   - After staging, validate `git diff --cached --name-only` still contains only allowlisted paths.
   - If validation fails, unstage the attempted paths and abort.
6. Commit with a conventional commit subject such as:
   - `chore(skills): snapshot local skill changes`
7. Stay quiet on no-op.
   - For `no_agent=true`, empty stdout means silent success.

## Verification without side effects

- Add a `--dry-run` mode that reports the skill paths that would be committed.
- Simulate an occupied index with a temporary index file rather than touching the real one:

```bash
tmp_index=$(mktemp)
cp .git/index "$tmp_index"
GIT_INDEX_FILE="$tmp_index" git -C ~/dotfiles add -- path/to/some/non-skill-change
GIT_INDEX_FILE="$tmp_index" ~/.hermes/scripts/dotfiles-skill-autocommit.py --dry-run
rm -f "$tmp_index"
```

The expected result is a delay message, and the real index remains unchanged.

## Hermes cron shape

```python
cronjob(
    action="create",
    name="dotfiles-skill-autocommit",
    schedule="0 0,12 * * *",
    script="dotfiles-skill-autocommit.py",
    no_agent=True,
    deliver="local",
    prompt="Run the local dotfiles skill autocommit script...",
)
```

Use a 5-field cron expression for exact local-time midnight/noon scheduling.
# Sub-agent brief templates

Concrete templates for the implementer and reviewer agents. Fill in the `<placeholder>` slots from the plan. The exact wording matters less than the structure: every brief must be self-contained, name the worktree path explicitly, and state the boundaries (what NOT to touch, no push, no PR).

---

## Implementer template

Use `Agent` with `subagent_type: general-purpose` and `description: "Implement gh issue #<N>"`. Paste this prompt:

```
You are implementing GitHub issue #<N> in this monorepo. <one-sentence goal restated from the issue>.

## Worktree

Work in this exact directory (do NOT cd elsewhere): <absolute-worktree-path>

The current branch is `<branch-name>`<, branched off `<parent-branch>` if applicable>. Make all changes on this branch. At the end, commit your work (do NOT push, do NOT open a PR).

## Issue text (verbatim from gh)

<paste full output of `gh issue view <N>` — title, body, acceptance criteria>

## Plan (already approved by user)

<the relevant section of the plan: files to create, files to move, files to edit, files NOT to touch>

### Untangling decisions (confirmed with user)

<each architectural decision the user resolved, e.g. "DatabaseSettings moves to valido_db.config — backend re-exports">

### Files to move (use `git mv` to preserve history)

<table of from → to>

### Files to edit

<list with one-line summary each>

## Verification

Run these from the worktree root and report each result:

<verification commands appropriate to the repo — pytest, ruff, mypy, docker compose build, alembic, etc.>

## Constraints (must hold at end)

<bullet list of invariants from the plan, e.g.:>
- `apps/agent-runner/pyproject.toml` is unchanged.
- No file under `<package>/` imports `backend.*`.
- Alembic config remains in `apps/backend/`.

## Commit

After verification passes, commit with conventional-commits style. Repo convention: <e.g. `feat(scope): ...`>. Suggested:

```
<type>(<scope>): <one-line summary>

Closes #<N>. <one-paragraph why>

Note: automated commit
```

Use a HEREDOC for the commit message. Do NOT use `--amend`. Do NOT push. Do NOT open a PR.

## Report back

Concise structured report:
1. Files created (list)
2. Files moved (count + spot-check that git tracks renames)
3. Files edited (list)
4. Verification results: each command + pass/fail + key error excerpt if failed
5. Constraint checks: each one + PASS/FAIL
6. Commit SHA
7. Deviations from the plan — flag explicitly

Keep under 500 lines. If blocked, stop and report rather than improvise.
```

### Notes on the implementer brief

- **Paste the issue text verbatim.** Don't paraphrase — you might drop the exact wording of an acceptance criterion.
- **List files NOT to touch.** Constraints like "agent-runner must not gain a DB dependency" are easy for an agent to violate while making "obvious cleanup" edits. Make them explicit.
- **Use `git mv`, not `mv` + `git add`.** Preserves rename detection so reviewers see clean rename entries instead of full delete + add diffs.
- **HEREDOC for commit messages.** Multi-line commit messages get mangled if passed via `-m "..."`.
- **Forbid `--amend`.** If a hook fails, the commit didn't happen — amend would modify the *previous* commit and silently mangle work.
- **No push, no PR.** The skill stops at branches; the user decides when to publish.

---

## Reviewer template

Use a **fresh `Agent` call** — never continue the implementer agent. `subagent_type: general-purpose` so the reviewer can run shell commands. `description: "Independent review of #<N>"`. Paste this prompt:

```
You are an independent reviewer for GitHub issue #<N>. Another agent claims to have implemented it on branch `<branch-name>` at commit `<commit-sha>`. Verify the claim against acceptance criteria from scratch — do NOT assume the implementer's report is accurate. You have Bash, Grep, Glob, Read access — use them.

## Worktree

Operate in `<absolute-worktree-path>`. Do NOT cd elsewhere. Read-only verification: do not make code changes; you may run commands.

The parent commit of `<commit-sha>` is `<previous-tip-sha>`. When comparing against the pre-issue state, use `git diff <previous-tip-sha>..HEAD` from inside the worktree.

## Issue text (verbatim)

<paste full output of `gh issue view <N>`>

## Verification checklist — produce evidence for each

For every check, run a concrete command and quote the output (excerpt is fine — show the part that supports the verdict). Do not say "verified" without evidence.

### A. <Acceptance criterion 1 phrased as a check>
- [ ] <specific command + expected outcome>
- [ ] <specific command + expected outcome>

### B. <Acceptance criterion 2>
- [ ] <...>

<...one section per acceptance criterion, plus sections for:>

### <X>. Tests / lint / types pass
Run from the worktree root:
```
<the project's verification commands>
```
Report exact pass count, failures (quote test names), and any error excerpts.

### <Y>. Commit hygiene
- [ ] `git log --oneline <previous-tip-sha>..HEAD` shows exactly one commit. Quote its message.
- [ ] `git status` is clean (no uncommitted changes).
- [ ] `git diff <previous-tip-sha>..HEAD --stat` summary fits the scope. Flag any edits to files outside the planned scope.

## Output

Return one of:

**VERIFIED** — every checklist item has supporting evidence. Include a one-paragraph summary, evidence inline, and any non-blocking observations.

**GAPS_FOUND** — at least one acceptance criterion is unmet. List each gap with:
- The criterion that fails
- The command output / file content showing the failure
- A specific suggestion for what the implementer should fix

Be precise. Quote actual command outputs. Do not skim. The orchestrator trusts your verdict.
```

### Notes on the reviewer brief

- **Never paste the implementer's report.** The whole point is independence. The reviewer should diff and grep on their own.
- **One section per acceptance criterion.** Mapping checklist sections directly to the issue's acceptance criteria makes gaps unambiguous.
- **Demand evidence, not assertions.** "Verified" is worthless without a quoted command output. Bake this into the brief.
- **Read-only.** The reviewer can *run* commands (tests, builds) but should not modify files. If they find a tiny fix, flag it as a gap — don't let the reviewer become a second implementer.
- **The diff scope is `<previous-tip>..HEAD`, not `main..HEAD`.** Stacked branches mean main is far behind; diffing against it floods the review with unrelated history.

---

## Common variants

### Reviewer reports stale IDE diagnostics

Pyright/Pylance LSPs cache state per workspace and can be stale across worktrees. If the reviewer flags imports as unresolvable but the implementer's mypy + runtime checks passed, run the check yourself in the new worktree before treating it as a real gap:

```
cd <new-worktree>
uv run python -c "from <package> import ..."
uv run mypy --config-file=mypy.ini <paths>
```

If runtime + CLI mypy succeed, the IDE LSP is stale. Note it as a non-blocking observation and proceed.

### Reviewer agent has no Bash access

Some `subagent_type` values (e.g., `feature-dev:code-reviewer`) are read-only and can't run `pytest` or `docker compose build`. They can still verify structurally: file existence, grep for forbidden imports, diff scope, commit message. Pair them with an orchestrator-side run of the verification commands when needed, or just use `general-purpose` for the reviewer.

### A gap is found

Read the reviewer's `GAPS_FOUND` carefully. Decide:

1. **Trivial gap** (one missed import, a typo in a config) — fix it yourself in the worktree, create a follow-up commit (don't amend), re-run the reviewer.
2. **Substantive gap** (the implementer's design diverged from the plan) — surface to the user before re-implementing. The plan may need adjustment.
3. **Mid-issue scope creep** — the implementer may have edited files outside scope. Decide whether to revert those edits or accept them as in-spirit additions; ask the user if uncertain.

Always re-run the reviewer after a fix — fresh evidence, not "I'm sure I got it this time."

### Verifying that a worktree is correctly stacked

Before spawning the next implementer, confirm:

```
git -C <next-worktree> log --oneline -3
```

The most recent commit should be the *previous* issue's commit. If it's some other commit (e.g., main's tip), the worktree was created with the wrong base — recreate it with `git worktree remove` + `git worktree add ... <correct-base-branch>`.

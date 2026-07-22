---
name: stacked-issues
description: Implement multiple GitHub issues sequentially as stacked branches in separate worktrees, with an implementer sub-agent and an independent reviewer sub-agent per issue. Use when the user gives you two or more dependent issues and asks for them to be implemented in order, or says "stacked branches", "sequential issues", "issue chain", "do these in worktrees", or describes a parent epic with child issues that build on each other. Also reach for this whenever the user wants implementation and verification done by separate agents.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, TodoWrite, AskUserQuestion, ExitPlanMode
---

# Stacked Issues

Run a chain of dependent GitHub issues end to end. Each issue gets its own git worktree, its branch is stacked on the previous issue's branch, an **implementer** sub-agent does the work, and a separate **reviewer** sub-agent verifies acceptance criteria from scratch. The orchestrator (you) plans, dispatches, and sanity-checks but does not write the implementation code itself.

## Why this exists

- Sub-agents have fresh context. An independent reviewer reading only the acceptance criteria catches things the implementer rationalized.
- Worktrees keep each issue's diff isolated. Reviewers diff against the previous issue's tip, not main, so they only see the change in scope.
- Stacking branches means later issues build on the *implementation* of earlier ones (not just the specs). Refactors that span multiple issues compose cleanly.

## When to use

Trigger on requests like:
- "Implement #74 and #75 — they have to be done in order, separate worktrees"
- "Work through these child issues of #73 sequentially"
- "Do these as stacked branches with implementer + verifier agents"
- Any time the user describes a parent epic with multiple ordered child issues

If only one issue is given, this skill is overkill — just plan and implement directly.

## Workflow

### Phase 1 — Plan

If plan mode is available, use it. Don't dispatch sub-agents until the plan is approved.

1. **Fetch every issue text**, including the parent epic if there is one:
   ```
   gh issue view <N>
   ```
   Read all of them at once (parallel `gh` calls). The parent issue is your source of truth for cross-issue constraints (e.g., "package X must not depend on Y").

2. **Explore the codebase** before planning. Spawn `Explore` sub-agents for the areas each issue touches. Map current state: file paths, imports, test fixtures, build config, Dockerfiles, CI. Hand the exploration agents specific questions, not vague briefs — see `references/agent-briefs.md`.

3. **Identify untanglings**. Refactor-style issues often hit hidden coupling (e.g., a class in module A is inherited by module B's table model). Surface every coupling that crosses the move boundary as a decision point. Use `AskUserQuestion` for each one with: "where should X live?" and 2-3 concrete options with tradeoffs. Don't guess on architecture choices — the user has context you don't.

4. **Write the plan**. Per issue: what gets implemented, files to create/move/edit, files NOT to touch (constraints — usually agent-runner-style "must not depend on X" boundaries), and concrete verification commands (tests, lints, types, docker, db migrations). Include a sequencing table:

   | Step | Worktree | Branch | Sub-agent role |
   |------|----------|--------|----------------|
   | 1 | current | current | Implementer for #N |
   | 2 | same | same | Reviewer for #N |
   | 3 | NEW | new branch off step-1 branch | Implementer for #N+1 |
   | 4 | same | same | Reviewer for #N+1 |

5. **Get the plan approved** before executing. In plan mode, this means `ExitPlanMode`.

### Phase 2 — Execute (per issue)

Track progress with `TodoWrite`: one todo per (implement, validate, create-worktree-for-next) step.

For each issue:

#### 2a. Set up the worktree

- **First issue**: usually the current worktree, or create one off `main` if you're on main:
  ```
  git worktree add /path/to/.claude/worktrees/<name> -b claude/<name> main
  ```
- **Each subsequent issue**: branch off the *previous* issue's branch, not main:
  ```
  git worktree add /path/to/.claude/worktrees/<next-name> \
    -b claude/<next-name> claude/<previous-name>
  ```
  Verify with `git worktree list` that the new worktree's HEAD is the previous issue's commit SHA.

#### 2b. Spawn the implementer

Use `Agent` with `subagent_type: general-purpose` (it needs Bash for tests, lint, git). Brief it as a self-contained colleague who hasn't seen this conversation. The brief must include:

- The issue text **verbatim** (paste from `gh issue view`)
- The exact worktree path
- The relevant section of the plan (files to create/move/edit, files NOT to touch, untangling decisions)
- Verification commands appropriate to the language/repo (the plan should already list these)
- Commit message conventions for the repo (check `git log` for style)
- Explicit instructions: **do NOT push**, **do NOT open a PR**, **do NOT use `--amend`**

See `references/agent-briefs.md` for a complete implementer prompt template.

The implementer reports back with: files changed, verification results, commit SHA, deviations.

#### 2c. Spawn the independent reviewer

Use a **fresh `Agent` call** — do not continue the implementer agent. Use `subagent_type: general-purpose` so the reviewer can run `pytest`/`mypy`/`docker compose build` itself. (`feature-dev:code-reviewer` works for read-only structural checks but cannot run shell commands.)

Critical constraint: **the reviewer must not be told what the implementer did.** Brief it with only:

- The issue text verbatim (from gh)
- The branch + commit SHA range to inspect (`git diff <previous-tip>..HEAD`)
- The acceptance criteria as a checklist, one bullet per criterion
- An instruction to **verify from scratch** — produce evidence (command output, file content) for every checklist item
- The expected return: **VERIFIED** or **GAPS_FOUND** with specific failures

See `references/agent-briefs.md` for the reviewer prompt template.

#### 2d. Sanity-check yourself

Trust but verify. After the reviewer reports, you (the orchestrator) run a quick check:

```
git -C <worktree> log --oneline <previous-tip>..HEAD
git -C <worktree> show --stat <commit-sha>
git -C <worktree> status
```

This catches the rare case where both agents agree something passed but reality disagrees (e.g., the implementer's commit didn't include all the expected files, or `git status` is dirty).

#### 2e. Decide based on reviewer verdict

- **VERIFIED**: mark the todo complete, move to the next issue.
- **GAPS_FOUND**: read the gaps. Two paths:
  - Small fix (1-2 files): make it yourself in the worktree, amend or create a follow-up commit, re-run the reviewer.
  - Larger gap: spawn a follow-up implementer with the gap list as the new brief. Then re-run the reviewer.
- **Reviewer reports diagnostics that conflict with mypy/runtime checks**: IDE LSP (pyright, etc.) state can be stale across worktrees. Run the check yourself in the new worktree (`uv run mypy ...`, `uv run python -c "import ..."`) before treating it as a real gap.

### Phase 3 — Hand off

Stop at branches. Do NOT push, do NOT open PRs unless the user explicitly asks. Final summary to the user lists:

- Each worktree path and branch name
- Each commit SHA and one-line message
- Verification results
- Any non-blocking observations the reviewers flagged

The user opens PRs themselves (or invokes the `stacked-prs` skill).

## Key principles

- **Brief sub-agents like cold colleagues.** Include exact paths, full issue text, files NOT to touch (constraints are easy for an agent to violate), and explicit "do not push" boundaries. Vague prompts produce surprising work.
- **The reviewer's value is independence.** Never paste the implementer's report into the reviewer's brief. The reviewer should rediscover what was changed by reading the diff.
- **Plan-mode pairs naturally with this skill.** The plan is the durable artifact; the sub-agent briefs are derived from it.
- **Don't auto-fix gaps.** Surface non-trivial gaps to the user before re-implementing — they may want to adjust the plan.
- **One commit per issue.** Easier to revert, easier for `stacked-prs` later. The implementer commits and stops.
- **Worktrees are the unit of isolation.** Don't try to do two issues in one worktree even if they're "obviously" stackable.

## References

- `references/agent-briefs.md` — full prompt templates for implementer and reviewer sub-agents, with placeholder slots and worked examples.

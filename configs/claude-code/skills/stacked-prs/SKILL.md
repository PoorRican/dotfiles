---
name: stacked-prs
description: Push local branches and create stacked PRs. Analyzes branch topology, pushes, creates PRs with correct base branches, and resolves merge conflicts. Use when you have a chain of local branches to turn into stacked PRs.
allowed-tools: Bash(git *), Bash(gh *), Read, Glob, Grep, Agent
---

# Stacked PRs

Create stacked PRs for a chain of local branches. Follow the steps below precisely.

## Arguments

If arguments are passed via `args`, interpret them as:

- Branch names or glob patterns to include
- A qualifier prefix (e.g., `nix-refactor`) to use in PR titles
- A stack letter override (default: `n`)

If no arguments are given, infer the branch stack from the current branch's ancestry.

## Step 0: Gather context

Before anything else, run these to understand repo state:

- `git branch --show-current` — current branch
- `git branch --list` — all local branches
- `git log --oneline --graph --all --decorate -30` — recent log across branches
- `git branch -r` — remote branches
- `gh repo view --json nameWithOwner -q '.nameWithOwner'` — owner/repo

## Step 1: Determine the branch stack

Identify the linear chain of branches from the main branch (usually `master` or `main`) to the current or specified branch tip. Use `git merge-base` to confirm parent-child relationships. Exclude branches with no unique commits vs their parent.

Output the stack as an ordered list before proceeding.

## Step 2: Determine the qualifier and stack letter

- If the branch names share a common prefix (e.g., `nix-refactor/1-...`, `nix-refactor/2-...`), extract it as the qualifier.
- If no common prefix exists, ask the user for a qualifier or skip it.
- Default stack letter is `n`. If the user specifies a letter, use that instead.

## Step 3: Push all branches

Push all branches in the stack to `origin` with `-u` in a single command.

## Step 4: Create PRs

For each branch in order (bottom of stack first):

1. **Base branch**: The previous branch in the stack, or the main branch for the first PR.
2. **Title format**: `[qualifier][x/letter] conventional-commit-style-title` where the title is derived from the branch name or commit content. If no qualifier, omit that prefix.
3. **Body format**:

```markdown
# Description

<1-2 sentences or bullet-only description of the FINAL STATE this PR achieves>
<Additional bullets as needed>

# Test

- [ ] <test checklist items>
```

**Description rules:**

- A PR body is **not a regurgitation of the diff**. It is a high-level explainer that helps the reviewer understand *what the PR delivers and why*, framed around intent and final state.
- Describe the final state, NOT the commit history. Do NOT mention commits that were overwritten or reversed within the PR.
- Top-level bullets carry the high-level outcomes (one bullet per major theme/outcome). Keep them short — a reviewer should be able to skim them and understand the shape of the change.
- Use **nested bullets sparingly** for low-level details that genuinely help the reviewer (e.g., a non-obvious side effect, a migration adding a column, a behavior change a reviewer might miss). Do not nest details that are self-evident from the top-level bullet or from filenames.
- For commits/areas with **many line changes**, take extra care: collapse them into a single intent-level bullet rather than enumerating subsystems. If the breadth itself matters (e.g., a rename across many files), say so in one sentence — do not list the files.
- **Never paste raw identifiers from the codebase that only mean something to the implementer**, including but not limited to: Alembic migration revision hashes, commit SHAs, internal task IDs, randomly-generated names. Reference the artifact by purpose ("a migration adds the column", "a new background task") instead.
- Sub-sections (`## Foo`) are allowed when the PR genuinely spans distinct concerns (see PR #23 / `[v1][18/n]` in `mycustomai/valido-backend` as the canonical example for a multi-area PR). For a single-theme PR, skip sub-sections.
- Use an exploration agent (sonnet model) to validate claims and understand changes before writing the description. Read the actual diff, not just commit messages.

**Anti-patterns to avoid (taken from real revisions):**

- Long top-level bullets that pack 4+ subsystems and several class names into one sentence — split or hoist to nested bullets.
- Including migration revision strings like `f1a2b3c4d5e6` or chain references like "chained off `d7e8f9a0b1c2`". The reviewer does not need these; the migration file does.
- Restating filenames as if they were features ("Adds `services/analysis/mocks.py`"). Describe the *capability*, mention the path only if it aids navigation.
- Bullets that read like a changelog of internal symbol moves with no user-visible effect. Either omit, or compress into a single "supporting refactors" line.

## Step 5: Resolve merge conflicts

After creating PRs, check each PR's mergeable status via `gh pr view N --json mergeable`. If any PR is `CONFLICTING`:

1. Checkout the conflicting branch.
2. Merge its base branch with `git merge --no-commit --no-ff <base>`.
3. Resolve conflicts (prefer the feature branch's version for intentional changes).
4. Commit the merge resolution.
5. Push the updated branch.
6. Cascade: merge the updated branch into any downstream branches in the stack, commit, and push each.
7. Re-check all PRs for mergeable status.

## Step 6: Report

Output a summary table:

```
| # | PR | Title | Status |
|---|---|---|---|
| 1 | owner/repo#N | [qualifier][1/n] title | MERGEABLE |
| ...
```

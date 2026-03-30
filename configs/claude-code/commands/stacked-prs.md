---
allowed-tools: Bash(git *), Bash(gh *), Read, Glob, Grep, Agent
description: Push local branches and create stacked PRs. Analyzes branch topology, pushes, creates PRs with correct base branches, and resolves merge conflicts. Use when you have a chain of local branches to turn into stacked PRs.
---

## Context

- Current branch: !`git branch --show-current`
- All local branches: !`git branch --list`
- Recent log (all branches): !`git log --oneline --graph --all --decorate -30`
- Remote branches: !`git branch -r`
- Repo: !`gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null`

## Arguments

$ARGUMENTS

If arguments are provided, interpret them as:
- Branch names or glob patterns to include
- A qualifier prefix (e.g., `nix-refactor`) to use in PR titles
- A stack letter override (default: `n`)

If no arguments are given, infer the branch stack from the current branch's ancestry.

## Your task

Create stacked PRs for a chain of local branches. Follow these steps precisely.

### Step 1: Determine the branch stack

Identify the linear chain of branches from the main branch (usually `master` or `main`) to the current or specified branch tip. Use `git merge-base` to confirm parent-child relationships. Exclude branches with no unique commits vs their parent.

Output the stack as an ordered list before proceeding.

### Step 2: Determine the qualifier and stack letter

- If the branch names share a common prefix (e.g., `nix-refactor/1-...`, `nix-refactor/2-...`), extract it as the qualifier.
- If no common prefix exists, ask the user for a qualifier or skip it.
- Default stack letter is `n`. If the user specifies a letter, use that instead.

### Step 3: Push all branches

Push all branches in the stack to `origin` with `-u` in a single command.

### Step 4: Create PRs

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
- Describe the final state, NOT the commit history.
- Do NOT mention commits that were overwritten or reversed within the PR.
- Sub-sections are allowed but not required.
- Use an exploration agent (sonnet model) to validate claims and understand changes before writing the description. Read the actual diff, not just commit messages.

### Step 5: Resolve merge conflicts

After creating PRs, check each PR's mergeable status via `gh pr view N --json mergeable`. If any PR is `CONFLICTING`:

1. Checkout the conflicting branch.
2. Merge its base branch with `git merge --no-commit --no-ff <base>`.
3. Resolve conflicts (prefer the feature branch's version for intentional changes).
4. Commit the merge resolution.
5. Push the updated branch.
6. Cascade: merge the updated branch into any downstream branches in the stack, commit, and push each.
7. Re-check all PRs for mergeable status.

### Step 6: Report

Output a summary table:

```
| # | PR | Title | Status |
|---|---|---|---|
| 1 | owner/repo#N | [qualifier][1/n] title | MERGEABLE |
| ...
```

---
name: git-and-github
description: "Use for costly Git and GitHub work: shared or concurrently edited checkouts, commit splitting and hooks, index-isolated commits, rebases and squash-merge landings with tree proof, dirty-checkout updates, worktree retirement and loss audits, history purges, stacked or overlapping pull requests, review threads and issue APIs, and recovering lost or misattributed work, and auditing conflict-resolved or delegated merges for silently dropped default-branch content."
---

# Git and GitHub

Shared checkouts, history rewrites and PR stacks fail in ways that a clean status, successful rebase or green individual checks can hide. These references preserve the mechanics behind those traps; open the one for branch and content reconciliation, hook-aware commits, ownership and index isolation, landing proof, dirty-checkout updates, worktree retirement, GitHub feedback surfaces, or PR topology and merge policy.

| When you are… | Open |
|---|---|
| Reconciling stale branches, squash history, rebases, artifact purges or branch retention | [references/branch-history-and-landing.md](references/branch-history-and-landing.md) |
| Splitting a moving working tree into commits, or reasoning about commit hooks and hook failures caused by other actors' files | [references/commit-splitting-and-hooks.md](references/commit-splitting-and-hooks.md) |
| Working in a shared checkout: ownership, concurrent writers, branch switching, formatter recovery or protecting staged work | [references/shared-checkouts-and-recovery.md](references/shared-checkouts-and-recovery.md) |
| Committing only your own lines or paths when the file also holds another actor's uncommitted edits | [references/isolated-index-commit.md](references/isolated-index-commit.md) |
| Updating a dirty or diverged checkout to a fetched target, or fast-forwarding it over foreign edits, with a preservation proof | [references/dirty-checkout-update.md](references/dirty-checkout-update.md) |
| Landing PR batches or chains of local branches and proving the merged tree is what was tested | [references/landing-proof.md](references/landing-proof.md) |
| Deciding what could be lost before deleting branches, worktrees or scratch, or removing worktrees other actors may use | [references/worktree-retirement-and-loss-audit.md](references/worktree-retirement-and-loss-audit.md) |
| Reading or posting GitHub issues, PR comments, formal reviews or inline threads, or judging CI and issue-closure evidence | [references/github-api-reviews-and-issues.md](references/github-api-reviews-and-issues.md) |
| Choosing branch topology, merge order or policy for stacked and overlapping PRs, splitting a dirty tree into a stack, or sweeping review comments across a stack | [references/pr-stacks-merges-and-reviews.md](references/pr-stacks-merges-and-reviews.md) |
| Auditing a conflict-resolved or delegated merge for default-branch lines it silently dropped, and repairing them with 3-way merges | [references/merge-drop-audit.md](references/merge-drop-audit.md) |


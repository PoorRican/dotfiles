# Shared checkouts and recovery

Scope: Ownership and preservation when branches, working files or index state may belong to another actor.

## Attribution before recovery

- A path modified at task start is shared or unknown until its changes are attributed; filenames, generated status or small diffs do not establish ownership of its hunks. A path observed dirty and later clean does not establish who changed it. (src: safe-agent-change-rollback, 2026-08-06; shared-repo-artifact-cleanup, 2026-08-04)
- A generated lockfile can contain another actor's dependency changes; being regenerable is not evidence that it is safe to revert. (src: safe-agent-change-rollback, 2026-08-06)
- Branch identity can change between calls in a shared working tree. An expected-branch check bound to the staging/commit mutation is stronger than an earlier observation. (src: shared-checkout-commit-safety, 2026-08-23)
- When `HEAD` is a known, owned stray commit atop a recorded original tip, `git reset --keep <original-tip>` resets the branch and index to that commit and updates the working tree except where non-conflicting tracked work is preserved; it refuses if tracked work would be overwritten. This recovery applies only when the stray commit is identified and the tree is clean or its work has a verified checkpoint; it is safer than `--hard`, not a substitute for recording what should be restored. (src: shared-checkout-commit-safety, 2026-08-23)

## Index isolation

- An alternate `GIT_INDEX_FILE` can isolate an owned-only commit from another actor's staged entries, but every command in that operation must use the same alternate index. A mixed worktree path needs an owned-only blob; staging the whole path absorbs foreign hunks. (src: shared-index-isolated-commit, 2026-08-25)
- After an alternate-index commit advances `HEAD`, the real index still describes the previous tree. Realignment is limited to paths proven unstaged before the commit; the foreign staged entries remain the preservation check. (src: shared-index-isolated-commit, 2026-08-25)
- A lock on the main index does not prevent a concurrent branch-ref advance; isolated index promotion also depends on checking the expected-old ref. (src: batch-commit-project-mode-hooks, 2026-09-23)

## Formatter attribution

- Formatter-only edits are identified by applying the same formatter to the indexed blob (`git show :<path>`) and comparing bytes with the working file; a relative path in the temporary copy preserves path-specific ignore behavior. After `git mv`, the index path holds the original blob even if `HEAD:<newpath>` does not exist. (src: accidental-repo-wide-format-recovery, 2026-08-17)
- Non-source files and files the formatter failed to parse cannot be attributed to that formatter. Quoted or octal-escaped status paths can also defeat naïve extension checks. (src: accidental-repo-wide-format-recovery, 2026-08-17)
- Reconstructing another actor's format-only edits depends on that actor's formatter configuration being in place first; otherwise line-length or per-file rules can change the output. A large mostly-mechanical diff still needs a full residual diff to distinguish semantic edits. (src: concurrent-actor-commit-split, 2026-08-17)

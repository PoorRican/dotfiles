# Commit splitting and hooks

Scope: Commit boundaries, mutable batching plans, staging scope and hook input models.

## Splitting a moving tree

- A commit plan is a snapshot: concurrent commits can absorb planned files, while new paths can appear. Its base, current status and intervening commit range can therefore differ at execution time. (src: commit-plan-drift-rescope, 2026-08-18; shared-tree-commit-batching, 2026-08-18)
- Reliable coverage means every live in-scope path is assigned exactly once, no planned path is absent, and no out-of-scope path is included; one-way path comparisons can miss omissions or additions. (src: commit-plan-drift-rescope, 2026-08-18; shared-tree-commit-batching, 2026-08-18)
- Explicit path-scoped staging keeps mid-execution additions outside a fixed plan. `git add -u` is appropriate only for an exact, verified formatter-only pass over intended tracked files, not as a general shared-tree staging strategy. (src: commit-plan-drift-rescope, 2026-08-18; concurrent-actor-commit-split, 2026-08-17)
- File modification times are weak evidence for work attribution; content dates and explicit intent are stronger. (src: shared-tree-commit-batching, 2026-08-18)
- An independently gated intermediate version of a mixed file can be constructed from the base plus only the earlier layer's edit; the saved final formatted version supplies the later layer. (src: backfill-working-tree-commits, 2026-09-07)
- FFI bindings, benches, examples and integration tests can consume changed signatures even when their files appear to belong to a later layer. A prebuilt native extension from another tree does not validate the split; the build and loaded module must come from the scratch source. Exact final path-and-content equality establishes that reconstruction dropped nothing; tests alone do not. (src: verified-commit-split, 2026-08-02)
- Piping `git commit` through `tail` can hide the hook's nonzero status because the pipeline reports the last command's exit code. (src: backfill-working-tree-commits, 2026-09-07)
- Conventional Commit breaking changes use `!` after the type or scope, or a `BREAKING CHANGE:` footer. (src: conventional-commits, 2026-03-29)

## Hook placement and visibility

- For newly designed commit-stage hooks, the staged-change invariant favors file-scoped checks; whole-project suites fit a pre-push gate. This design advice is distinct from working with an existing project-wide hook. (src: precommit-gate-introduction, 2026-08-17)
- An existing whole-project pre-commit hook can see `HEAD` plus staged changes and untracked files: it hides unstaged tracked edits, but not untracked consumers. A green full working tree therefore does not prove a partial commit is self-contained. (src: batch-commit-project-mode-hooks, 2026-09-23; backfill-working-tree-commits, 2026-09-07)
- Under a whole-project hook, an unstaged `.gitignore` change can expose newly ignored source files as untracked inputs to earlier commits; the hook's input set changes when that ignore rule lands. (src: batch-commit-project-mode-hooks, 2026-09-23)
- A worktree shares the repository's common hooks directory. A commit hook installed from a temporary worktree can leave the main checkout's hook pointing at that worktree's interpreter. (src: precommit-gate-introduction, 2026-08-17)

# Shared checkouts and recovery

- Treat pre-existing changes and staged entries as another writer's work until attributed. Generated files, including lockfiles, can contain foreign changes. Do not reset, stash, reformat or overwrite them to create a clean baseline.
- Branch identity can change between calls. Bind expected branch and HEAD checks to a staging or commit mutation and stop if they drift; owning files does not imply owning the checked-out branch.
- A file that is untracked at HEAD but exists upstream is not compared correctly by a normal tree diff as a working file. Compare its bytes with the upstream blob directly before calling it unique or disposable.
- If a path disappears or unexpected changes recur, inspect status and staged renames and coordinate with concurrent writers. Do not revert changes merely because their author is unknown; formatting can be attributed by comparing the formatter's output on the indexed blob with the working file.
- `git switch -m` can leave unmerged entries even when the switch succeeds. Checkpoint first and inspect HEAD, status and the unmerged index afterward; see [dirty checkout update](dirty-checkout-update.md).
- Build or publish from an isolated worktree at the intended commit when a shared checkout contains unrelated edits: build contexts and hooks may consume them.
- A nested repository added to an outer repository can become a mode-160000 gitlink rather than ordinary files. Inspect the index mode before correcting it; do not remove another writer's entry.
- Captured diffs may omit new untracked files and a trailing newline. Include intended new files separately (`git diff --no-index` returns 1 for differences); `git apply --check` establishes applicability, not completeness.

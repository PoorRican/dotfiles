# Worktree retirement and loss audit

## What could be lost

- Branch ancestry proves history, not content: an `ours` merge or conflict resolution can drop a branch's changes. Compare changed paths and blobs with the target and inspect substantive differences; line-set comparisons are triage, not proof of semantic equivalence.
- Inventory local and remote refs, all stashes, registered worktrees and detached HEADs. Include untracked and ignored files, nested or orphaned worktrees, and other VCS refs; status alone does not show ignored data. A remote branch preserves committed history, not working files.
- Record worktree path, branch or detached HEAD, lock and dirty state outside the deletion scope. Confirm exact remote ref and commit rather than relying solely on cached remote-tracking refs. Gitlinks may point to commits not reachable from the outer repository.
- Treat unknown ownership, incomplete discovery, inaccessible sources and uncertain remote associations as holds, not proof of safety. Respect restrictions on reading sensitive content.

## Preservation and removal

- Audit or preservation authorization does not authorize deletion or pushing. Agree on exact targets and exceptions; do not commit another actor's dirty work merely because the worktree appears stale.
- A clean status, remote commit, no process cwd, or a quiet interval does not prove a session has abandoned its worktree. Coordinate with its owner and recheck identity and activity immediately before removal. A process survey is only a point-in-time observation.
- `git worktree remove` can delete ignored data even without force. Verify unique ignored files are preserved or leave the tree intact; keep locked, active and uncertain trees. Record detached HEADs before removal because worktree administrative data and its reflog disappear.
- Use `git --no-optional-locks -C <worktree> status --porcelain` for observational status where index refresh could interfere with a writer. Do not override a worktree lock to force removal.
- A recovery ref protects Git reachability, not untracked files or disk failure. Verify any selected backup by reading back its intended members; Git does not preserve all filesystem metadata. Report what was preserved, held, removed or remains unknown.

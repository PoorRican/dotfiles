# Branch history and landing

Scope: Content identity, rewrite hazards, artifact removal and branch-retention evidence.

## Content identity and append-only files

- A working-tree file can match the intended remote target while differing from local `HEAD`; local difference alone does not make it new work. (src: divergent-checkout-master-sync, 2026-09-19)
- Append-only conflicts are positional: the combined file preserves distinct entries in their intended order, shared entries once, and the original body of each entry. (src: divergent-checkout-master-sync, 2026-09-19)
- A merge retains the identities of commits made by other actors; rebasing can rewrite those identities. (src: divergent-checkout-master-sync, 2026-09-19)

## Squash history and rebases

- On a branch based before squash merges, a three-dot diff starts at the old merge base and can include already-landed content; the two-dot diff from the current target to the branch measures the remaining content delta. Path content, rather than subjects or hashes, establishes whether suspect changes are already upstream. (src: stale-branch-squash-rebase-landing, 2026-08-23; land-commits-and-capture-image-digest, 2026-08-23)
- A commit skipped by patch ID is safe to omit only when its changed paths are proven to match upstream; matching subjects or hashes do not prove equivalent content. (src: stale-branch-squash-rebase-landing, 2026-08-23)
- `rerere` can remove a path from the unmerged-index list while leaving conflict markers unstaged, so an unmerged-path-only scan can miss marker text. Changed files and newly created commits remain relevant to detecting it. (src: safe-git-rebase-with-guards, 2026-07-12; stale-branch-squash-rebase-landing, 2026-08-23)
- Rebase success or a green build alone does not show that replay preserved reviewed output. The saved pre-rebase tree is the comparison point for output equality, and replayed commits can still contain conflict markers. (src: safe-git-rebase-with-guards, 2026-07-12)
- With `rebase.updateRefs`, rebasing one branch can move other local branch refs pointing into the rewritten range, including refs owned by other actors. (src: safe-git-rebase-with-guards, 2026-07-12; stale-branch-squash-rebase-landing, 2026-08-23)
- A history rewrite is scoped to commits owned by the current actor and not yet published; the working tree is clean or separately checkpointed, and the pre-rewrite tip/tree is recorded. The preservation target is the saved content, not old commit IDs. Published or shared history calls for coordination or a non-rewriting alternative. (src: safe-git-rebase-with-guards, 2026-07-12; stale-branch-squash-rebase-landing, 2026-08-23; purge-committed-artifact, 2026-09-19)

## Artifact removal and branch retention

- A history rewrite to remove a blob is appropriate only for unpublished commits owned by the actor. For pushed history or work another actor may depend on, a normal removal commit avoids rewriting that history, although the old blob remains reachable. (src: purge-committed-artifact, 2026-09-19)
- An autosquash fixup depends on the exact `amend! <original target subject>` marker; changing its subject can let rebase report success without changing the history or removing the artifact. (src: purge-committed-artifact, 2026-09-19)
- `git rm --cached` changes only the index, so a stash of worktree edits does not preserve that index-only removal. The artifact's absence from reachable objects—not only from the current tree—is the relevant purge evidence. (src: purge-committed-artifact, 2026-09-19)
- Ignoring a committed artifact is reliable only when the builder and fresh-checkout setup order are documented; `.dockerignore` can still include an on-disk artifact in an image context. (src: purge-committed-artifact, 2026-09-19)
- A squash-merged branch is usually not an ancestor of the target. A merged PR alone does not establish that a local branch is disposable: its tip can contain post-merge work, so the local tip and PR's recorded last commit matter. (src: squash-merge-safe-branch-pruning, 2026-08-14)
- A clean status does not make a worktree disposable when it is locked, active, primary, external, or operationally uncertain. (src: squash-merge-safe-branch-pruning, 2026-08-14)

## Build publication evidence

- A successful pull-request image build need not publish an image when workflow pushes are disabled for pull-request events. A local build-manifest digest differs from the registry digest; the push-step evidence identifies the published image. (src: land-commits-and-capture-image-digest, 2026-08-23)

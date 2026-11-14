# Branch history and landing

## Content identity and rebases

- A working file differing from local HEAD may already match the intended remote target; compare content before calling it new work.
- After squash merges, a three-dot diff from an old merge base can include landed changes. Compare the target and branch trees and the affected paths, not commit subjects, to establish remaining content. If the historical PR head tree equals its squash commit tree, replaying its component commits is redundant.
- A merge retains commit identities; rebase rewrites them. Coordinate before rewriting published or shared history; record the original tip and tree and preserve unrelated work. With `rebase.updateRefs`, a rebase may move other local refs pointing into the rewritten range.
- `rerere` can clear an unmerged index entry while conflict markers remain in a file. Inspect changed files and replayed commits for markers and compare the resulting tree with the intended pre-rebase content; a successful rebase or build is not preservation proof.
- `git checkout --ours` or `--theirs` on a path selects the entire file and can discard the other side's non-conflicting edits. Inspect both sides; use a whole-file choice only for an explicitly selected variant.

## Artifacts and retention

- Removing a file from the current tree does not remove its blob from history. Rewrite only history you are authorized to rewrite; a removal commit preserves published history but does not purge reachable objects. Verify object reachability when a purge is required.
- `git rm --cached` changes the index; a stash of working-tree edits does not preserve an index-only removal.
- Git ignore rules do not exclude files from a Docker build context; check the build context and `.dockerignore` separately.
- A squash-merged branch need not be an ancestor of its target, and may have new commits after the PR merged. Compare its actual tip and content before deletion.

# Landing proof

## Authority and ordering

- Opening a PR does not authorize merging it. Merging does not authorize deployment; report merged and live separately.
- Merge providers before consumers. Merge stacked bases first, then open or retarget the next PR so its diff holds only its own commits. Read the actual base and head before each merge.
- Landing another session's uncommitted worktree: read its authoring session's final report for intent, verification and outstanding work; coordinate ownership and preserve unrelated files before committing.
- Check required reviews, checks, protections and the exact head and base. A missing check is not a passing check, and push-only publication is not PR validation.

## Prove the merged tree

- Use a merge commit when an external record cites branch commits: squash and rebase merges rewrite identities. Check the cited commits are ancestors of the resulting base.
- In a repository with no CI, pin the tested head, for example `gh pr merge <n> --merge --match-head-commit <tested-sha>`. The author's local gates are the only evidence, so make the tested tree and the merged tree the same tree.
- Qualify the exact head/base pair. If the head already contains the current base, its tested tree can be the merge tree; otherwise construct the conflict-free prospective merge tree, test that tree in an isolated worktree, and compare it with the eventual merge commit's tree. A merge-tree preview is not itself a test.
- The head pin does not pin the base. If the base moves, reassess and requalify the resulting tree as needed, including changes to build configuration and dependencies, not just source and tests. Read back the merged commit and its parents.
- Never hand-merge generated files (lockfiles, tag manifests, rendered schemas): regenerate from the merged tree with the repository's generator and run its check. Hooks triggered only by changed paths may not regenerate them automatically.
- For overlapping changes, inspect the resolved content and test the combination; separately green branches do not prove the merge result works. A whole-file side selection can discard unrelated changes.

For a conflict-free prospective merge, compute `T=$(git merge-tree --write-tree origin/<base> <head>)`, create a temporary commit with `git commit-tree "$T" -p origin/<base> -p <head> -m scratch`, and test it in a detached worktree with the required ignored inputs and frozen dependencies. After the pinned merge, compare `git rev-parse <merge>^{tree}` with `T`. If the base changes, qualify the new pair rather than treating the old preview as proof.

## Publication and cleanup

- When a PR is described as already applied to a running system, prove live equals merged using an appropriate read-only comparison or applied evidence; a merge alone does not establish activation.
- A PR build may not publish an artifact. Identify the published digest from the applicable push and registry evidence, distinguishing image index and platform manifest digests.
- Delete a merged branch (remote and local) only if no worktree has it checked out and it is already in the base. A squash merge requires content or patch equivalence and a check for post-merge branch commits, not just an ancestry test. Leave other sessions' branches and worktrees alone.
- Report a table of repository, PR, merge commit, base CI result and published digests; distinguish not run, failed and unavailable evidence. Report merged versus live and any dependent actions separately.

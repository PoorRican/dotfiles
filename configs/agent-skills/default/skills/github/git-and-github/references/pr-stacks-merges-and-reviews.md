# PR stacks, merges and reviews

- Stack PRs when a change genuinely depends on an earlier branch; touching related files alone does not imply dependency. Independent fixes can branch from the base separately.
- Read each PR's actual base. A higher PR still targeting a lower branch can merge into that branch without reaching the intended default branch. Merge bases first, retarget as needed and verify the resulting diff and base.
- Choose merge strategy for repository policy and history requirements. Conflict resolution on a lower branch may need propagation and renewed checks on downstream branches.
- A clean mergeability badge against an obsolete stack base does not establish a clean or relevant diff against the default branch. When splitting a bundled prerequisite, verify its ancestry, publish a base PR, retarget the dependent PR and inspect both diffs.
- Separate green PR checks do not validate their conflict-resolved combination. Additive conflict sides can still produce invalid syntax when delimiters lie outside the conflict block; inspect the surrounding construct and test the combined state.
- If `gh pr merge --delete-branch` reports an error, re-read the PR before retrying: remote merge may have succeeded while local branch deletion failed. Retarget dependent PRs before deleting their base.
- Classify review feedback against both its original revision and the current stack tip; a later branch may already address it. Check thread state separately from conversation comments.

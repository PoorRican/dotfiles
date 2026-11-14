# Merge drop audit

Audit a conflict-resolved or delegated merge when there is reason to suspect a wholesale side selection or lost changes. A green build can coexist with silently discarded content. Audit is read-only; a repair, PR or merge requires its own authorization.

- Inspect internal merges between the original base and PR tip, not only the final PR merge: conflict resolution may have happened earlier.
- For files changed on both sides since their merge base, compare each parent's changes with the merge result. Missing added lines are leads, not proof: renames, reflow, duplicates and deliberate replacements can mislead exact-line checks. Inspect the surrounding content and subsequent commits before calling a change lost.
- Compare lineage by content and fixes, not timestamps alone. A branch may contain the other's fixes plus further work even when history is complicated.
- Repair in an isolated worktree from the current base. Use a three-way file merge with the appropriate common ancestor and inspect conflicts rather than selecting a whole side. Preserve changes landed since the faulty merge, test the affected behavior, and verify the repaired tip against both inputs.

For each two-parent merge in `git rev-list --merges <default-before>..<pr-tip>`, identify the parent that is an ancestor of the pre-landing default, and compute its merge base with the other parent. Intersect the paths changed from that base on both sides. For each path, compare the nonblank added lines in `git diff -U0 <base> <default-parent> -- <path>` with the merge result. Inspect missing lines and subsequent history; exact-line comparison is triage, not proof.

For an authorized repair, extract the older common version and newer version with `git show <rev>:<path>`, then run `git merge-file -L current -L older -L newer <file> <older-version> <newer-version>` in the isolated worktree. The arguments are current, base, other; the first file is rewritten. Capture nonzero status explicitly, resolve conflict markers, and retain subsequent default-branch edits. Repeat the audit against the repaired tip, not just the original merge, and inspect the residual differences.

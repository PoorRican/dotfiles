# PR stacks, merges and reviews

Scope: Branch topology, merge policy, overlap cost and combined-state validation.

## Stack shape and merge policy

- A stacked PR series has each PR based on the preceding branch, with the chain created bottom-up. Touching related files is not itself a dependency when a change does not need the earlier branch's code. (src: stacked-prs, 2026-05-04; stacked-independent-fix-set-landing, 2026-08-18)
- GitHub does not necessarily retarget a stacked PR after its base merges. A higher PR left on a lower branch can merge successfully into that literal base without putting its change on the main branch. (src: github-linear-stack-merge-cascade, 2026-09-04)
- Merge strategy depends on repository policy and desired history: in some linear stacks, merge commits preserve stack history and avoid a post-merge rebase cascade; squash and rebase strategies have different history and retargeting consequences. No strategy is universal. (src: github-linear-stack-merge-cascade, 2026-09-04; land-commits-and-capture-image-digest, 2026-08-23)
- Stacked-PR descriptions are clearest when they describe delivered state rather than internal commit history or identifiers. (src: stacked-prs, 2026-05-04)
- A conflict-resolution change to a lower branch may require propagation through downstream branches and renewed mergeability checks. Before branch pruning, equality between remote main's tree and the recorded original stack-tip tree is landing evidence. (src: stacked-prs, 2026-05-04; github-linear-stack-merge-cascade, 2026-09-04)

## Overlapping changes and CI

- Merge order can account for predicted file overlap: stacked bases come first, then lower-overlap PRs, with the heaviest-overlap PR last when that reduces repeated conflict work. (src: overlapping-pr-fan-merge, 2026-08-19)
- Union-merging additive conflict sides can break syntax when a shared closing delimiter sits after the conflict block. The text following the markers is part of the construct; green CI on each PR separately does not validate the conflict-resolved combination. (src: overlapping-pr-fan-merge, 2026-08-19)
- Opening a PR can cancel a push-triggered CI run for the same SHA when repository concurrency settings replace push runs with PR-event runs; that cancellation alone is not evidence of code failure. (src: stacked-independent-fix-set-landing, 2026-08-18)

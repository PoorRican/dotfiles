# Review Dispatch

Scope: portable context and partitioning principles for independent diff review and correctness assessment.

## Reviewer context and scope

- A three-dot Git diff (`base...head`) scopes branch-owned changes from the merge base; a two-dot comparison can include base-branch drift. (src: parallel-diff-review-dispatch; source 2026-07-24)
- Line counts do not describe a change's structural risk; reviewer context is more useful when it reflects representative modules and the actual shape rather than only a stat summary. (src: parallel-diff-review-dispatch; source 2026-07-24)
- A useful independent-review brief states what changed, the requirements, and the exact base/head range, so the reviewer can use the original problem and acceptance criteria rather than the implementer's accumulated session history or report. (src: requesting-code-review; src: stacked-issues)
- Implementation and its tests usually belong in the same review slice unless the test surface merits separate coverage review. A separate slice can focus scrutiny on the highest-risk path; domain invariants and accepted pre-existing gaps help distinguish inherited risks from new regressions. (src: parallel-diff-review-dispatch; source 2026-07-24)
- Useful review questions establish whether the specified failure can occur and what evidence bears on it. Reviewer findings are separate from implementation decisions: technically grounded pushback merits assessment, not automatic acceptance or rejection. (src: parallel-diff-review-dispatch; src: requesting-code-review)
- For implementation handoffs with a separate reviewer, spec compliance and code quality are distinct questions; polish cannot compensate for a missing acceptance criterion, and the reviewer can derive findings from original requirements and inspect independently. (src: subagent-driven-development; src: stacked-issues)

## Finding quality

- A useful finding connects a concrete mechanism to the affected consumer and consequence; distinguish a branch regression from an inherited hazard that the change exposes. (src: parallel-correctness-audit-with-proving-tests; src: parallel-diff-review-dispatch)
- For confirmed, unit-testable defects in an audit, a proving test should fail while pinning the correct behavior; a passing test that merely echoes an implementation constant does not prove it. Refuted hypotheses can also be recorded as controls against a future incorrect “fix.” (src: parallel-correctness-audit-with-proving-tests; source 2026-08-06)

This reference focuses on reviewer scope, independence, and briefing rather than on how to evaluate code generally.

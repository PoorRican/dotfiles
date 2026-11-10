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

## Materializing the review surface

- A review of "uncommitted changes" built from `git diff` omits untracked files. Run `git status --short` first and stage the hunks to local files for read-only reviewers. (src: uncommitted-review-surface, 2026-07-24)
- To delegate classification of a mixed working tree to read-only scouts, materialize the immutable `HEAD` bytes, a frozen candidate snapshot, and per-file diffs; require hunk-level scope decisions; and include retired-API caller migrations (one module's tests failed until its caller migration was included). (src: mixed-tree-classification, 2026-09-22)

## Paired numbers and claims reviewers

- For a results draft that cites receipts, spawn a read-only numbers reviewer and a claims reviewer in one batch with one output schema, `{findings: [{severity: error|overclaim|unclear|nit, draft_text, problem, evidence, correction}], verified: [...]}`; asking for `verified` makes coverage visible. The numbers reviewer recomputes every cell and prose number from the receipts at full precision, checks run identifiers, checks that each named commit exists on the named branch and touches the cited file, and checks values quoted from earlier notes. The claims reviewer checks definitions against the code and the frozen text, confirms or refutes each mechanism claim with `file:line`, checks registered decisions against the receipts, and flags unlabeled inference. A quote check has to match the item's own row, not merely occur verbatim elsewhere in the study. (src: numbers-and-claims-review, 2026-10-04..2026-11-02)
- Verify each finding against its cited evidence before applying it; reviewers are sometimes wrong. A reviewer's own computation is not a receipt: use it to drop or soften a claim, and publish its numbers only after recomputing them in your own audited script. (src: numbers-and-claims-review)
- After a large revision send both idle reviewers the revised path and the list of what changed for a delta round limited to new or changed text plus regressions. Count findings from the reviewers' JSON via the session transcript, never from their prose summaries, which can disagree with the list; archive each round's JSON verbatim with the evidence. (src: numbers-and-claims-review)
- Revisions after the reviews never pass through the reviewers, so gate the final text against the receipts yourself: extract every number with a regex and confirm each appears in the reviewed draft or the generator output, recompute each table cell (or assert byte identity with a final-form table generator), open every `file:line` cite, run `git show --stat` on every named commit, and trace every number that appears in neither the last reviewed draft nor the generator output to its source. Apply the gated blocks programmatically and assert the result equals the base text plus exactly the inserted blocks. (src: numbers-and-claims-review)
- Generate every table cell and derived number from receipts with a script, formatting each value once at its final precision (re-rounding a printed value is the commonest error), and generate tables in their final published form so the gate can assert byte identity. Sort before writing any "largest" or "helps most" sentence. (src: numbers-and-claims-review)
- For relational (no-threshold) results give each effect with its interval, avoid intensifiers and equality words ("barely", "flat", "agree"), keep ratios within one comparator set and unit, and leave the decision-maker's interpretation to them. Report to the owner from the committed text, not from memory of drafts: grep the committed record before saying what it does or does not contain. (src: numbers-and-claims-review)

## Dialectic investigation swarm

- For a contested, evidence-heavy question, the orchestrator builds a write-protected evidence pack plus a brief of first-pass facts to challenge, then runs waves. Wave 1: specialist investigators each state falsifiable claims and what they tried to falsify. Wave 2: a prosecutor and a defender with opposite theses, a framer who attacks the premise itself, and auditors who recompute from raw sources without reusing the audited scripts. Wave 3: targeted follow-ups sent to the idle agents rather than fresh spawns.
- Bound each analysis with `systemd-run --user --scope -p MemoryMax=<n>G` and have each agent copy its reports out of its scratch area at the end. Reviewer briefing, output schema and finding verification are as above. (src: dialectic-swarm-recipe, 2026-11-10; the memory-cap flags not re-run)

This reference focuses on reviewer scope, independence, and briefing rather than on how to evaluate code generally.

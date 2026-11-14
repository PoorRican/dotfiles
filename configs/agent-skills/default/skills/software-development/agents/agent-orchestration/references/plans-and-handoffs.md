# Plans, handoffs, and reviews

## Briefing and review

A handoff needs the original requirements, exact workspace and scope, neighboring interfaces, constraints, and evidence expected for acceptance. A fresh reviewer can independently assess the requirements and specified revision range without relying on the implementer's account. Separate specification compliance from code quality; implementation and tests generally belong in the same review slice.

For a branch review, `base...head` selects changes since the merge base; a direct comparison may include base-branch drift. For uncommitted work, `git diff` omits untracked files: inventory the working tree and materialize a complete, frozen review surface, including relevant caller migrations. Findings should identify the mechanism, affected consumer and consequence, and distinguish newly introduced regressions from inherited hazards. Verify findings against their evidence before acting.

For evidence-heavy drafts, independent reviewers can check numerical derivations and substantive claims separately. Check source identity and definitions, distinguish inference, and recompute material numbers from the underlying evidence. After changes, review the changed text and check any final additions against their sources.

For a results draft citing receipts, dispatch a read-only numbers reviewer and a claims reviewer in one batch with a shared output schema: `{findings: [{severity: error|overclaim|unclear|nit, draft_text, problem, evidence, correction}], verified: [...]}`. The numbers reviewer recomputes cells and prose numbers from receipts at full precision, checks identifiers, named commits and quoted values. The claims reviewer checks definitions against code and frozen text, confirms or refutes mechanisms with `file:line`, checks decisions against receipts, and flags unlabeled inference.

Verify each finding against its cited evidence before applying it. A reviewer's computation is not a receipt: use it to drop or soften a claim, and publish its numbers only after recomputing them in an audited script. After a large revision, give both reviewers the revised path and changes for a delta round covering changed text and regressions; preserve their structured findings. Gate final additions yourself: check numbers against receipts or final-form generator output, recompute table cells, and open cited lines and named commits. Generate derived values at final precision rather than re-rounding printed numbers.

For a contested, evidence-heavy question, build a write-protected evidence pack and first-pass facts to challenge. Have specialist investigators state falsifiable claims and what they tried to falsify; then use opposing theses, a reviewer challenging the premise, and auditors recomputing from raw sources without reusing the audited scripts. Send targeted follow-ups to existing investigators.

## Dependent issue chains

Read the issues and parent constraints together and identify the interfaces and dependencies that actually require sequencing. Later work must start from the preceding issue's implementation, not merely its specification. Before dispatching the next implementer, compare the new worktree's HEAD with the previous issue's tip; an incorrect base makes the stack misleading. Review each issue against that preceding tip rather than the common base.

For each issue:

1. Read the issue text and parent epic, explore affected code and cross-boundary coupling, and plan the files to create, move, edit, or leave untouched. Include concrete verification commands and sequence dependencies before dispatch.
2. Create the next worktree and branch from the previous issue's branch. Check its HEAD against the previous issue's commit before dispatch; if wrong, correct the base before starting work. Record the previous tip for the review range.
3. Give the implementer the full issue text, exact worktree and branch, relevant plan, architectural decisions, files not to touch, verification commands, and applicable commit conventions. State publication boundaries. Request changed files, command results, commit SHA when applicable, and deviations.
   If committing, forbid `--amend` after a failed commit hook: the commit may not have happened, so amending can silently change the previous issue's commit. Use a follow-up commit for review fixes.
4. Brief a fresh independent reviewer with the issue text, worktree, preceding tip and head, and one checklist section per acceptance criterion. Do not include the implementer's report. Ask for concrete evidence per criterion, test results, scope and working-tree status, and a verdict of VERIFIED or GAPS_FOUND with specific failures.
5. Sanity-check the reported change and worktree yourself, including `git -C <worktree> log --oneline <previous-tip>..HEAD`, `git -C <worktree> show --stat <commit-sha>`, and `git -C <worktree> status`. Proceed to the next issue only after addressing review gaps.
6. Hand off each worktree and branch, commit SHA where applicable, verification results, and non-blocking observations. Do not push or open a pull request without authorization.

After independent review, triage gaps: correct a small, unambiguous omission directly; delegate a larger repair; surface a substantive design divergence or uncertain scope change for a decision. Re-review the affected work after fixes. Conflicting IDE and command-line diagnostics need investigation in the correct workspace and configuration; a passing different analyzer does not by itself prove an IDE result stale. A local branch handoff does not authorize publishing it.

For apparently stale IDE import diagnostics across worktrees, run the relevant runtime import and configured CLI type checker in the new worktree, for example `uv run python -c "from <package> import <symbol>"` and `uv run mypy --config-file=mypy.ini <paths>`. If both pass, investigate the IDE's workspace and configuration; matching configuration and refreshed diagnostics can establish a stale IDE result. Record a confirmed stale diagnostic as non-blocking rather than treating it as an implementation gap.

For a confirmed unit-testable defect, a proving test should fail before the fix while pinning the intended behavior. A passing test that merely echoes an implementation constant does not prove the fix; record refuted hypotheses where they prevent an incorrect future change.

Keep blockers attached to the work they actually affect. Trace a real input through the smallest complete path to an inspectable output, and report unsupported or unverified capabilities rather than presenting a partial slice as the whole acceptance sequence.

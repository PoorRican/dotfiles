# Pinned-tree boundary audits

Use a pinned-tree audit for compatibility across repository boundaries, including producer and consumer shapes, contracts, and pins. Dirty or differently branched checkouts can otherwise produce false findings.

1. Fetch the relevant revisions and give scouts detached, pinned worktrees; clean up the audit worktrees afterwards.
2. Gather ground truth scouts cannot reach, such as remote storage listings, orchestrator state, open pull requests, and configuration key names without values, into a shared file before dispatch.
3. Fan out one scout per boundary in a single batch with shared context. Ask for file-and-line evidence, the affected owner, a minimal fix, open questions, and explicit inference labels. Distinguish current breakage, drift risk, unfinished cutover, and compatible boundaries.
4. Re-verify every BREAKS-NOW finding and every lead claim yourself at the pinned revision. For `git grep`, place the revision before `--`; otherwise the search can inspect the working tree instead.
5. Mark scout-only claims in the report. Separate data not yet published in the required shape from a code mismatch, and distinguish current blockers from future risks.

## Scout brief and report

Give each scout its boundary, the pinned worktree paths and revision identities, and the shared ground-truth file. Request a boundary map with `file:line` evidence, findings tagged **BREAKS-NOW**, **DRIFT-RISK**, **UNFINISHED-CUTOVER**, or **OK**, the owning repository and minimal fix for each finding, and open questions. Require `[INFERENCE]` on unverified claims. Configuration evidence should include key names, not secret values.

For example, check a claim against the actual pinned revision with `git grep <pattern> <revision> -- <path>`. Do not substitute the working checkout or assume a scout's tree matches the audited revision. Put the verdict first in the final report, then distinguish blocking today, works today but risks a quiet break, cutover status per goal, already-compatible boundaries, housekeeping, and order of work.

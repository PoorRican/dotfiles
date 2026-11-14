# Recovery and session evidence

Loss of an orchestration process or job identifier does not prove its work was lost or that remote work stopped. Check for running work, partial reports, scripts, outputs, and persisted transcripts before relaunching; otherwise expensive or unsafe work may run twice. Pass recovered partial results into a relaunch and compare its scope with the original acceptance criteria. A steering message may not interrupt a long-running call; cancel it if continued execution is unsafe.

Transcripts can retain full edit or write arguments even when rendered output is truncated, but only if the session read or wrote the file. Concurrent human edits need not appear in the transcript; a later read snapshot, editor backup, or dangling version-control object may preserve them. Distinguish verbatim recovery from reconstruction constrained by callers and tests. Restoring a path to its committed version can erase uncommitted edits; preserve a pre-edit copy or reverse only the intended change.

Before parallel semantic refactors in a shared uncommitted tree, preserve snapshots of owned files and an inventory of existing tests. Compare recovered coverage with the original inventory; matching a test count alone does not establish restored behavior.

When reconstructing a session, inspect relevant prompts, agent reports, plans, and artifacts as well as summaries. Historical recommendations are leads, not current evidence: recheck open threads against current source or live state.

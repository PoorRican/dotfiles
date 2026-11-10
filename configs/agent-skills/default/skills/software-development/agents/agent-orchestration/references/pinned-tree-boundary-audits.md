# Pinned-tree boundary audits

Scope: a read-only audit of compatibility across several repositories (producer/consumer data shapes, contracts, pins) done by fanning out one scout per boundary against trees that are pinned and fetched, not whatever the working checkouts hold.

## Pin the trees the scouts read

- Fetch each repository and add detached audit worktrees at the fetched upstream main branch. Main checkouts are often dirty or sit on another session's branch, and scouts without a shell read whatever tree they are given. Remove the worktrees afterwards. (src: cross-repo-audit-method; 2026-10-27)
- Gather ground truth that scouts cannot reach (remote storage listings, orchestrator state, open pull requests, configuration key names without their values) yourself into a shared file before dispatch. (src: cross-repo-audit-method; 2026-10-27)

## Dispatch

- Fan out one scout per boundary in a single batch with a shared context and a report of at most about 700 words: boundary map with `file:line`, findings tagged BREAKS-NOW / DRIFT-RISK / UNFINISHED-CUTOVER / OK with the minimal fix and the owning repository, open questions, and `[INFERENCE]` on unverified claims. (src: cross-repo-audit-method; 2026-10-27)
- Re-verify every BREAKS-NOW finding and every lead claim yourself at the pinned revision with `git grep <pattern> origin/main -- <path>`. The revision must come before `--`, or git silently greps the working tree. Stale trees have already produced false findings. (src: cross-repo-audit-method; 2026-10-27)

## Report

- Verdict first, then: blocking today, works today but breaks quietly, cutover table per goal, already compatible, housekeeping, order of work. Mark scout-only claims, and separate "data not yet published in the required shape" from "code mismatch". (src: cross-repo-audit-method; 2026-10-27)

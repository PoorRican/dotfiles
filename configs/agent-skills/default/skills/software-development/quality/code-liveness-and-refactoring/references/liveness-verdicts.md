# Liveness verdicts

Scope: separating implementation, data flow, active integration, and observed execution.

## Data and call paths

- A name search sees named uses, not wholesale carry-through such as wildcard projections, joins, or dynamic column iteration. Could a field reach a durable intermediate artifact and then be dropped by an explicit downstream allowlist? These are distinct boundaries, not a single “used” or “unused” verdict. (src: code-liveness-triage, 2026-08-31; staleness-and-dead-code-investigation, 2026-08-31; staleness-liveness-audit, 2026-08-31; verify-pipeline-code-liveness, 2026-08-31; verifying-wired-vs-stale-code, 2026-08-31)
- Does the real caller pass a newly added optional argument? A helper can be implemented and thoroughly tested while that option remains unwired at production call sites. (src: verifying-wired-vs-stale-code, 2026-08-31)
- Do module headers describe stage ownership, and does the current orchestrator confirm that boundary? These can be more authoritative than stale per-file assumptions or old comments about downstream consumers. (src: refactor-aware-pipeline-rederivation, 2026-09-11; verifying-wired-vs-stale-code, 2026-08-31)
- Passing tests support implementation correctness, not integration into the active pipeline or execution of its caller. Does the production path, its prerequisites, and any documented successor confirm current integration separately? (src: staleness-and-dead-code-investigation, 2026-08-31; staleness-liveness-audit, 2026-08-31; verify-pipeline-code-liveness, 2026-08-31)
- Could a parked or legacy output area hold the consumer or attempt that explains apparent orphaned work? Such a match may explain intent without making the old attempt part of the current production path. (src: code-liveness-triage, 2026-08-31)

## Execution evidence and limits

- Local receipt or output absence is not proof that execution was never attempted: caller-supplied paths may be outside the checkout, in another worktree, or later deleted. An empty success-only tracker query establishes no successful run was logged there, not that no earlier failed attempt occurred. (src: code-liveness-triage, 2026-08-31; staleness-and-dead-code-investigation, 2026-08-31; verify-before-staleness-verdict, 2026-08-31; verify-pipeline-code-liveness, 2026-08-31)
- Does the observed run inventory match the expected campaign shape, not just a similar name or a plausible count? Smoke, profiling, or ad hoc runs do not establish that the intended workload completed. (src: verify-pipeline-code-liveness, 2026-08-31)
- A fixed model offset or base margin sets an initial prediction; learned residuals can still underperform that value on held-out data. What does the measured held-out metric show? (src: code-liveness-triage, 2026-08-31; verify-before-staleness-verdict, 2026-08-31; verify-pipeline-code-liveness, 2026-08-31)
- A plain exclusive-create marker is deletable and human-reversible: does the description match the protection it actually provides rather than calling it an irreversible lock? (src: code-liveness-triage, 2026-08-31; staleness-and-dead-code-investigation, 2026-08-31; verifying-wired-vs-stale-code, 2026-08-31)
- Do old and new comparator specifications match in state-key granularity, target statistic, shrinkage, and as-of discipline? Superficially similar names can hide a weaker baseline. (src: verify-pipeline-code-liveness, 2026-08-31)

# Partitioning and fan-out

Scope: determine what partitioning or fan-out changes actually prove, and expose assumptions hidden by a single instance.

## Evidence for partitioning

- What code defines one failure's or repair's blast-radius unit? Configured partition count alone does not establish what one failure costs. Evidence from one run can compare partition totals with the full population, the min/median/max and largest-share against the `1/N` ideal, and distinct live metric labels against configured partitions; mixed label namespaces such as `0` and `00` can distort naïve counts. (src: partitioning-change-evidence, 2026-08-04)
- Does a reduced-load soak show routing correctness only, or the claimed peak-load improvement too? Different cardinalities confound cross-run ratios; cumulative counters do not establish causality. Interval deltas and a case where the proposed cause is absent distinguish association from cause. A result's tested load/population is part of its scope. (src: partitioning-change-evidence, 2026-08-04)

## Fan-out assumptions

- What scope mints each identifier? Per-connection/session IDs can restart at the same value, so shared maps and journals need an instance discriminator as well as channel/stream identity. (src: singleton-to-fanout-audit, 2026-08-05)
- Is readiness derived from all expected work-bearing instances, or written as a shared boolean by each instance? Last-writer-wins can let one healthy instance mask many dead ones. Observed connection state is distinct from a changing expected-work set: pruning state for temporarily empty work can wedge a still-open connection that will not emit another connect event. (src: singleton-to-fanout-audit, 2026-08-05)
- Is the sequence counter per stream or per instance? Adding instances does not multiply detection when the upstream cursor is stream-wide. Fan-out-one observations cannot reveal these collisions or aggregation errors; evidence from multiple distinct identities and actual live partition labels is more discriminating. (src: singleton-to-fanout-audit, 2026-08-05)

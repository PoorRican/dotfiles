# Denominators, Grains, and Boundaries

Questions and facts for deciding what a grouped value, funnel count, or evaluation window actually measures.

## Aggregation grain

- A child-to-parent aggregation that picks one scalar is safe only when that value is constant within each parent group on the exact production-filtered population; checking another population says nothing about the shipped one. (src: grain-aggregation-determinism-audit)
- An ordering-based first/last picker is deterministic only with a unique total ordering key within each group; timestamps or indices that tie merely replace one arbitrary pick with another. (src: grain-aggregation-determinism-audit)
- Where do non-constant groups fall? A small share of them can still distort a label severely if they concentrate in the positive class. (src: grain-aggregation-determinism-audit)
- Where else does the selected value flow? The same arbitrary value can feed targets, derived features, kernels, or normalization, so impact follows its consumers rather than its first use. (src: grain-aggregation-determinism-audit)
- A base-rate discrepancy is not evidence of a defect until both constructions are compared on the same rows; different filters or cohorts can legitimately yield different rates. (src: grain-aggregation-determinism-audit)

## Short-circuit funnels

- With short-circuit checks, rejection buckets partition check order, not the candidate population. Each rate is conditional on the candidates that reached that check; raw counts cannot fairly rank gates. (src: short-circuit-funnel-denominator-audit)
- Removing an upstream gate exposes its candidates to downstream gates. Expected gain depends on the unblocked count multiplied by downstream conditional pass rates, not the raw skip count. (src: short-circuit-funnel-denominator-audit)
- A downstream gate never reached because of an earlier rejection is unmeasured, not demonstrated harmless. Reordering checks can change bucket counts without changing behavior. (src: short-circuit-funnel-denominator-audit)

## Data and release boundaries

- For a GitOps-deployed service, the deployed image pin—not the source tag date—marks when a release began affecting captured data; the relevant data signature must be derived from that release’s actual changes, not guessed from a neighboring release. (src: release-boundary-data-cutoff, 2026-08-19)
- Schema changes can show up as a field moving from null to populated; behavioral changes require a distributional signature. Rows per distinct timestamp can miss cadence changes when timestamps are effectively unique per row. (src: release-boundary-data-cutoff, 2026-08-19)
- Per-entity inter-arrival distributions can reveal behavioral shifts that a median or count misses; in the documented scheduler example the median stayed near nominal while lower-tail gaps and dispersion shifted. (src: release-boundary-data-cutoff, 2026-08-19)
- A deployment partway through a UTC day leaves that date mixed-regime; the following UTC date is generally the first clean day. A local-time cohort lookback can pull the mixed day back into a nominally post-release window. (src: release-boundary-data-cutoff, 2026-08-19)
- A declared evaluation window is not load-bearing if artifact admission checks source and configuration identity but not the cohort window. A later release inside the window creates another regime to account for. (src: release-boundary-data-cutoff, 2026-08-19)
- How many independent units support a short post-release window? A mechanism measurement can be informative even when its sample ceiling does not support a performance or promotion claim. (src: release-boundary-data-cutoff, 2026-08-19)

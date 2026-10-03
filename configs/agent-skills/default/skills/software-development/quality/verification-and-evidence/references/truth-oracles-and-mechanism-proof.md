# Truth oracles and mechanism proof

Scope: distinguish structural validity, parity, diagnostics, and a mechanism that agrees with independent source truth.

## Semantic truth and reference implementations

- A validator can prove endpoint/cardinality/dedup/finite-value invariants while the representation describes an event that never happened. Semantic truth depends on hand-checkable, source-derived expectations compared with the representation's assertions; a population census can size the defect. (src: semantic-graph-truth-audit, 2026-09-01; source-truth-audit, 2026-09-01)
- Full parity can encode known legacy defects. A safe characterization surface follows from the stores/fields each defect touches, plus coupled outputs; a match on the remainder means only “matches legacy,” not “correct.” (src: semantic-graph-truth-audit, 2026-09-01; source-truth-audit, 2026-09-01)
- A diagnostic count matching the affected population proves observation, not handling. The emitted or stored value still needs to agree with source truth. A specification's “unfixable” premise can also fail if relevant source fields are present. (src: semantic-graph-truth-audit, 2026-09-01; source-truth-audit, 2026-09-01)
- When a category vocabulary evolves, could stable-prefix or pattern routing handle unseen variants more safely than an exact-value allowlist that silently sends them to a default? (src: source-truth-audit, 2026-09-01)

## Mechanism and corruption signatures

- Does the hypothesized failure mechanism predict a computable per-record signature? Evaluating it over a read-only snapshot of the whole retained population, rather than incident examples alone, can test the hypothesis. Even a perfect signature does not alone exclude every competing cause; unobserved inputs or records remain outside the evidence. (src: embedded-store-corruption-signature-proof, 2026-08-15)
- “Corrupt” records and records dangerous now are different populations. The trigger subset is most informative when the danger filter is an over-inclusive superset, so that a zero count is meaningful. If the store evicts old records, the earliest surviving timestamp is only a lower bound on when the defect began. (src: embedded-store-corruption-signature-proof, 2026-08-15)
- Are decoded values essential, or do key tuples already test the hypothesis? Value decoding must match the production record layout and codec configuration exactly; a plausible local decoder can turn layout mismatch into false evidence. (src: embedded-store-corruption-signature-proof, 2026-08-15)
- A plausible-size file consisting entirely of NUL bytes from offset zero is consistent with interrupted content writing, but copies and timestamps are needed to date and attribute it; same-sized corrupted copies can mean corruption was propagated. (src: post-crash-artifact-integrity-sweep, 2026-08-09)

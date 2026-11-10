# Result Audits and Residuals

Interpretation traps when findings are corrected by another analysis or several mechanisms are used to explain one measured gap.

## Reading results and corrections

- An independent auditor can find real errors and also make an incorrect correction. Before changing a finding, do the population, denominator, and reference definitions agree? A discrepancy across different populations is not itself a contradiction. (src: layered-result-audit-ladder, 2026-08-18)
- A concentration share over a statistically near-zero aggregate is not meaningful; a meaningful share can be recalculated within a significant stratum or omitted. (src: layered-result-audit-ladder, 2026-08-18)
- When a confirm-half point estimate has the search-half direction but its confidence interval crosses zero, that can indicate limited power rather than a sign reversal. A post-hoc split remains descriptive. (src: layered-result-audit-ladder, 2026-08-18)
- A “beats a constant” comparison is directionally informative when the constant was estimated on data inside the scored sample, but is not independent of that sample. Degenerate intervals from small-cluster bootstrap machinery are directional evidence, not precise uncertainty bounds. (src: layered-result-audit-ladder, 2026-08-18)
- On priced instruments, hit rate can merely restate average price; the price-implied null is a more relevant baseline than a coin-flip comparison. (src: layered-result-audit-ladder, 2026-08-18)
- Distinguish native model capability from the identity of a qualified scored law, its trained and evaluated targets, archive vocabulary, and what the consumer supports. A missing named endpoint alone does not prove native incapacity; inspect shared trajectories and origin-specific suffix equivalence. Do not replace a frozen mixture with one component or infer joint dependence from separate marginals.
- In staged timing audits distinguish source receipt, computation readiness, scheduled eligibility, response, consumer receipt, and downstream action. Waiting can overlap computation, so summing both full durations double-counts time. Separate restart and catch-up observations from steady operation and state cross-clock assumptions.

## Attributing a residual

- What exact quantity, units, and population define the gap? A mechanism priced against a nearby quantity explains a different object. (src: residual-channel-ledger, 2026-08-09)
- A wrong-signed correction was propping the system up, so removing it widens the gap and correctly signed channels must explain more than the headline deficit. (src: residual-channel-ledger, 2026-08-09)
- Do two named channels price the same physical defect? Different labels do not make overlapping explanations additive; physical ownership matters before adding estimates. (src: residual-channel-ledger, 2026-08-09)
- Could a context-neutral conversion misprice a context-specific effect? A delta on the target state space is preferable; if only a crude scalar conversion is feasible, its direction of bias and approximate status are worth stating. (src: residual-channel-ledger, 2026-08-09)
- Does the deployed system condition on the information used to price this channel, or marginalize it? Pricing should match the production information state; in a paired comparison with shared conditioning, that objection cancels in the difference. (src: residual-channel-ledger, 2026-08-09)
- Do candidate channels touch overlapping rows? Correctly priced estimates over overlapping populations still cannot be summed as if independent; the evidence supports a range rather than a false total. (src: residual-channel-ledger, 2026-08-09)
- Many small signed channels with no dominant mechanism can be a real finding. The largest channel may be a useful next target without accounting for the whole residual. (src: residual-channel-ledger, 2026-08-09)

## Reporting only what was verified

- Claim only what was verified and label mechanisms and bounds as inference. Flagged repeatedly (2026-10-04): "nothing was lost" after an out-of-memory kill when only restart timestamps had been seen (a restart timestamp is not evidence of no loss); "the service survives crashes" asserted from its unit definition rather than from an observed crash; a linear-screen result reported as a ceiling when it is a proxy; a causal story ("units were removed because they were hit") that is only plausible. (src: verified-claims-discipline, 2026-10-04)
- Audit scripts that emit a report can hard-code their conclusions and define a "clean" subset circularly: one audit claimed 100% inclusion by dropping the late additions from the subset it measured. Grep the generator's literals for universal claims ("100%", "always", "none"), and run a numbers review before the record. (src: generated-audit-circularity, 2026-10)
- Report a ratio compared with a registered stop threshold unrounded (at least three decimals, with every plausible denominator and both median- and mean-based variants) and test each class against the threshold in code before writing "no class exceeds X". A rounded column displayed exactly the threshold for a class that was slightly above it, "no class is over the threshold" was relied on, and the stop had to be re-asked and waived afterwards (2026-10-25). Receipts bound by hash in a freeze record are never edited: add an erratum beside them, and correct narrative in place with a marked "(Corrected on ...)" note plus a dated correction entry in the log. (src: threshold-ratio-rounding, 2026-10-25)

## Overclaims that independent reviews keep finding

- A linear oracle screen registered as a "bound" measures a proxy gain, not a ceiling; say which column carries the gain. A realized-outcome oracle with all its weight on the branch that happened measures how faithfully the laws show the event: it does not bound attainable Brier (a calibrated probability can beat a realized indicator) and does not locate the bottleneck.
- A reproduction gate covers only the arrays it re-scored, not every array a readout reads. A claim such as "every report binds its pack" must hold for every split; check each receipt.
- Single-fit caveats must include the baseline model and every fitted component the candidate reuses. A contrast named after one factor (say, width) can carry others (hardware, microbatching); check the training configs.
- Gains in teacher-forced factors locate a gain within the factorization; they do not measure behaviour at forecast time. Selection metrics can differ by model, so say which one each model used.
- Percentage shares of a decomposed contrast are order-dependent, and "X of N" claims need an intersection check.
- Deviations that are easy to omit from an audit: parity-scope amendments; stalls, out-of-memory kills, and owner-directed resumes; data gates that failed before a fix; the content (not just the timestamp) of a post-freeze design amendment; provenance notes about where forecasts came from; population extensions or validity gates added after a first reading; reader bug fixes made after a first reading, with values before and after; registered clauses that were never computed; comparators outside the registered population and the code each ran at; execution-mechanism or resource changes made in code without an amendment; and a selection rule applied on a different window than the specification names.
- Guard symmetry in A/B arms: if one arm applies N validity guards and the other M != N, the experiment measures the guard-count difference, not the treatment (for example, one arm revalidating an already-filled item while the other does not can alone produce a large gap). Audit that both arms apply the same guards before believing any A/B.
- A neutrality proof can shield the bug it reproduces: behavior-identity tests validate a refactor, but say nothing about whether the reproduced behavior is correct. When deliberately fixing a defect, "the neutrality proof would move" argues for re-baselining, not for preserving the defect; keep the pre-fix reference and the post-fix re-baseline as separate artifacts.

(src: numbers-and-claims-review, 2026-10-16..2026-11-02)

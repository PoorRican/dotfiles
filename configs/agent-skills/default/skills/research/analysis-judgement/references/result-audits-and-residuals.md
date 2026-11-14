# Result Audits and Residuals

## Reading results and corrections

- Before accepting a correction, compare the population, denominator, and reference definitions. Different populations can legitimately yield different results.
- A concentration share over a near-zero aggregate can be unstable or misleading; omit it or examine an appropriate stratum. A same-direction estimate whose interval crosses zero is not a sign reversal, and a post-hoc split is descriptive.
- A baseline fitted inside the scored sample is not independent of that sample. Degenerate small-cluster bootstrap intervals do not provide precise uncertainty bounds.
- In staged timing, distinguish receipt, readiness, eligibility, response, consumer receipt, and action. Waiting can overlap computation, so summing both full durations double-counts time; separate restart and catch-up from steady operation and state cross-clock assumptions.
- Inspect generated audit code for hard-coded conclusions or circular subsets: an omitted population cannot demonstrate its own inclusion. Derive expected membership independently of the output being audited.
- Review deviations that can change the result: failed data gates and subsequent fixes, reader fixes with values before and after, population or validity changes, uncomputed clauses, comparators outside the specified population, execution changes, and selection applied on a different window.
- Compare threshold values at sufficient precision before rounding for display. A value displayed at the threshold can actually exceed it.

## Comparison integrity

- Audit whether A/B arms apply behaviorally equivalent validity guards. An asymmetric guard can confound the treatment comparison; unequal guard counts alone neither establish behavioral asymmetry nor explain the measured effect.
- Behavior-identity tests establish refactor parity, not the correctness of the behavior reproduced. When fixing a defect, retain the pre-fix reference separately from the corrected baseline.
- A reproduction check covers only the inputs and outputs it actually re-scores. Shared fitted components, including the baseline, matter when describing single-fit uncertainty; a named contrast can also differ in other configuration dimensions.
- A proxy oracle is not necessarily a ceiling. Improvements in teacher-forced factors locate changes within that factorization but do not by themselves measure forecast-time behavior. Decomposition shares can depend on ordering.
- A claimed intersection requires checking the intersection, not just the individual counts. Clearly distinguish observed facts, plausible mechanisms, and bounds.

## Attributing a residual

- Define the gap's quantity, units, and population before pricing mechanisms against it. Removing a wrong-signed correction can widen the gap, leaving other mechanisms more than the headline deficit to explain.
- Check whether channels describe the same physical defect or touch overlapping rows before adding estimates. A collection of small signed effects need not have a single dominant mechanism.
- Match a channel's valuation to the target state space and the information available to the deployed system. If using a crude conversion, disclose its approximate nature and potential bias.

## Calibrating a claim rule

- To assess the size of a clustered interval rule, simulate under an explicit null and apply the complete rule to each simulated cohort. The rejection fraction estimates size under that null, not universal true size; preserve relevant dependence and the target cluster structure in the simulation.
- Choose simulation and resampling budgets for adequate Monte Carlo precision. With few or imbalanced clusters, the actual rejection rate can differ substantially from the nominal level, depending on the statistic and clustering method.

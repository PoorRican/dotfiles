# Diagnosing calibration drift

Join out-of-fold predictions by full row key and check label and row parity. Deduplicate metadata before joining; a duplicate can silently multiply observations. Aggregate observed outcomes `O` and predicted probabilities `E` by relevant independent units and dates, and examine `sum(O) / sum(E)` over time as well as pooled. A pooled ratio can hide temporal variation.

Shared-date shocks make row-level uncertainty misleading. Cluster contrasts on the unit that plausibly shares shocks; ignoring positive shared-date dependence can understate uncertainty, but its direction is not universal. Two models' observed/predicted ratios share the observed numerator, so correlated ratios alone do not establish a common shock, a shifted event rate or its cause.

Inspect whether excess outcomes concentrate in a few entities or dates and whether date-level patterns persist across heads. For entity effects, compare within-date residuals and their stability across splits. Overlapping positive labels may describe one episode rather than independent events; changes in row counts can also reflect changes in population mix. Retained rows alone cannot prove capture completeness.

For ratio `R = sum(O) / sum(E)`, a cluster SE is `sqrt(sum_g (O_g - R*E_g)^2 / (sum_g E_g)^2 * n/(n-1))`, with `n` clusters. Examine the share of positive excess `O-E` concentrated in the largest clusters and dates, then correlate date-level log ratios across heads as a descriptive coherence check. Compare date ratios with preceding dates and trailing means to assess persistence and motivate candidate window lengths.

For entity effects, subtract each date's mean log ratio before estimating entity means and SEs; compare extremes against chance and check split-half stability. Test candidate calendar or activity effects on held-out time blocks and against an intercept-plus-slope baseline, rather than attributing a pooled gap to them.

## Causal trailing recalibration

A trailing surprise feature can summarize resolved outcomes versus predictions as `log((O + a) / (E + a))`, using a window ending early enough that all labels have resolved by prediction time. Select smoothing, window and lag for the application. Compare a logistic recalibration with and without these features, fitting each on past data and scoring later data; report paired loss differences with appropriate clustered uncertainty and the covered population.

Odd/even time blocks can screen candidates, but do not replace a chronological evaluation when deployment uses the past to predict the future. Windows selected on evaluation dates need unseen dates for confirmation. An expanding-history intercept that fails does not establish that the calibration level is unpredictable: its memory or update schedule may be inappropriate.

When reporting relative improvements, state whether the denominator is raw loss or the comparator's loss. To distinguish training-window length from model staleness, compare windows refreshed at the same cadence on the same evaluation rows. A successful trailing feature can track capture artifacts as well as real behavior, so improved calibration alone does not identify a cause.

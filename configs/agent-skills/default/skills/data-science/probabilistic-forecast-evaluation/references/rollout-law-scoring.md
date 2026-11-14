# Scoring sampled rollout laws

A histogram built from finite simulator rollouts has noisy cell probabilities; applying log loss introduces upward expected loss even for a perfect simulator. The bias can favor a narrow sampled law over a broader one, or an analytic head over a sampled head. Its size depends on the law, sample count and floor, especially in rare cells.

A marginal proxy can illustrate the mechanism but does not estimate a fitted conditional model's bias. Use conditional proxy laws of comparable sharpness or rescore the fitted model across sample counts on a fixed grouped subsample. Compare residual scoring bias with the uncertainty of the actual contrast. The asymptotic `(K - 1) / (2N)` approximation can mislead when rare floor-dominated cells matter.

Build conditional proxy laws by nesting cell, parent and base levels and shrinking each toward the next; choose shrinkage by grouped cross-validation and include full backoff. Compare proxy held-out NLL with the incumbent forecast's NLL only as a sharpness check, not as a contrast when populations or splits differ.

For a perfect simulator, compute excess `KL(p || (1-f) * hist_N + f * p)` over repeated multinomial histograms. The truth floor is optimistic. Report origin-weighted excess and SE at selection and scoring sample counts, and inspect `N * excess`: a rising curve indicates that two-point `1/N` extrapolation understates bias. Examine excess against entropy; measure fitted-model bias separately because its rare-cell mass can differ.

Retain the scores of two half-samples as well as the full sample: mean half-sample NLL minus full-sample NLL estimates the full-sample bias only in the approximate `1/N` regime. Inspect the excess across sample counts; half-sample agreement alone does not prove bias is gone. For model selection, consider more rollouts or a lower-variance score when Monte Carlo uncertainty matters relative to the decision.

## Integrating draws and exact composition

Rao-Blackwellization accumulates conditional probabilities instead of sampling a draw. Analytic convolution is exact for a terminal draw that no later emission reads; if later state depends on it, branch and propagate its values or integrate only genuinely terminal draws. A shared clock couples outputs, so independent per-side generating functions need not represent the joint law.

Exact recursion can replace histograms when the changing rollout state is tractably discrete, other inputs are fixed per origin, and durations lie on the state grid. Continuous feedback or expanded state can make it impractical. With non-negative increments, a recursion for one realized outcome can discard mass outside its bounded outcome box because it cannot return. Full-support moments can instead be propagated as weighted sums; on a fixed output grid, track overflow separately.

Validate an exact implementation against brute-force short cases and Monte Carlo, compare nested grids and moments, and compare the fitted exact law with its sampled law across sample counts. State extensions multiply reachable states, and emission-network evaluation can dominate runtime; measure the actual implementation.

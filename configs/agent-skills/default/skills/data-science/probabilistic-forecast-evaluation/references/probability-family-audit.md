# Auditing a family of related probabilities

Scope: a model, or a pair of models, that emits several related probabilities (nested thresholds, nested horizons, two sides of an event) and must be judged beyond AUC or against a baseline. Use when someone asks how the outputs behave, whether they contradict each other, whether they are calibrated, or what a new model gains over a baseline.

## Order

1. **Same rows, same labels.** Join the models on the full row key. Assert equal row counts and that every label agrees (null-safe equality) before any comparison. Hold labels as int8 with -1 for undefined and score each head only where its label is defined.
2. **Label nesting.** Check the implied orderings in the labels wherever both are defined: a larger threshold implies a smaller one; an event within a shorter horizon implies one within a longer horizon. Only then do crossings in the predictions count as errors. Also check that definedness agrees across heads.
3. **Coherence of predictions.** Per row take the worst crossing per axis. Report the share of rows over 0.001, 0.01 and 0.05, the worst value and per-pair rates. Small crossings between events that can only co-occur are noise; locate where the crossings sit.
4. **Does incoherence cost anything?** Project each row onto coherent orderings with row-wise isotonic regression (alternating axes; one round or a PAV pass usually suffices) and rescore. A change near 1e-4 means the incoherence is cosmetic.
5. **Per-head scores.** Log loss, Brier and AUC, with a paired clustered SE for differences: `sqrt(sum_g (S_g - mean * N_g)^2) / sum_g N_g`, where `S_g` is the cluster sum of per-row differences and `N_g` its row count.
6. **Calibration per head.**
   - Observed over predicted in the large.
   - Logistic recalibration `y ~ sigmoid(a + b * logit p)` by Newton; `b < 1` means over-confident.
   - ECE over 50 equal-count bins, and Brier reliability and resolution.
   - If the in-sample Platt or isotonic gain is smaller than the model's log-loss lead over the baseline, calibration cannot explain the gap.
7. **Calibration over time.** Weekly observed over predicted and slope for a few heads. Weekly ratios that correlate at 0.9 or more across models mean the event rate shifted and neither model saw it: a shared gap, not one model's defect. A pooled ratio near 1 can hide weekly swings of several-fold; report both.
8. **Out-of-time recalibration.** Fit temperature (slope only, intercept 0) and Platt on earlier folds only, apply each to the next fold, and score folds 2..K with clustered SEs. This, not the in-sample gain, decides whether recalibration should ship; it can help one model in every head and hurt another in most.
9. **Strata.** Calibration and AUC within known regimes (deciding-event windows, trigger kind, price buckets). Look for blind spots both models share: a high observed rate with AUC near 0.5.
10. **Top of the ranking.** Average precision and hit rate in each model's top 1% and 5% per head. An AUC lead can coexist with the baseline winning at the very top.
11. **Complementarity.** Average the two models' log-odds with equal weight; report its AUC and clustered log-loss difference against the better model, with the weeks it leads. Where the gain concentrates shows where the baseline holds information the new model lacks.
12. **Disagreement quadrants.** For a key head take each model's top q%; report the share of rows, event rate and share of all events in both, only-A, only-B and neither.
13. **Structure.** PCA of standardized logits on a large sample, comparing within-group and between-group correlations (for example one side against the other) to see how many independent risk scores the heads really carry.
14. **Training dynamics.** From per-target monitor losses, count targets still improving at the last epoch and those that peaked earlier.

## Reading the results

- Comparisons at matched counts (the same number of flagged rows) use one head's ordering, so calibration and crossings between heads cannot change them. Calibration matters only for absolute thresholds, expected-loss calculations or combining heads.
- Under-prediction (observed over predicted above 1) and over-confidence (slope below 1) are different defects and can hold at once.
- Compute every paired difference before writing a range or "about the same", and scope claims to the heads measured.

## Practical

- Hold predictions as float64 arrays of shape `[N, heads]` and labels as int8; millions of rows by tens of heads fit in memory.
- Give interactive analysis cells a generous timeout; several stages take minutes at that size.
- Keep the cells as run in a scratch file as the record; analysis code needs no tests of its own, but its headline numbers should be recomputed independently once.

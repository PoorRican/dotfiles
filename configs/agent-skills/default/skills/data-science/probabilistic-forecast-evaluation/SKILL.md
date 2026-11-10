---
name: probabilistic-forecast-evaluation
description: "Use when judging probabilistic forecasts or simulator-scored laws: Monte Carlo histogram bias and exact scoring of rollout laws, why a model loses a registered gate to a cross-fitted lookup (calibration vs information vs branch weights), auditing a family of related probability heads, and diagnosing calibration drift by date."
---

# Probabilistic forecast evaluation

A log-loss or Brier comparison can be decided by the estimator, the split or the clustering unit rather than by the model. These references collect the checks that separate those effects from model skill: how a sampled law is scored, why a model loses to a lookup, how a family of nested probabilities should be audited, and whether a calibration gap is a date-level shock. Choose the one that matches the question; none is a fixed checklist.

| When you are… | Open |
|---|---|
| Scoring a Monte Carlo rollout or simulator law under log loss, selecting epochs on that score, or asking whether exact composition is feasible | [references/rollout-law-scoring.md](references/rollout-law-scoring.md) |
| Explaining why a model, branch tree or mixture lost a registered gate to a lookup cross-fitted on the evaluation split, or testing whether a model adds anything over a state lookup | [references/lookup-gate-loss-attribution.md](references/lookup-gate-loss-attribution.md) |
| Auditing a model's nested thresholds, horizons or sides beyond AUC: row and label parity, coherence, calibration, top-k, complementarity | [references/probability-family-audit.md](references/probability-family-audit.md) |
| Observed/predicted ratio swings by week or date, or a recalibration layer must beat Platt scaling walk-forward | [references/calibration-drift-diagnosis.md](references/calibration-drift-diagnosis.md) |

## Rules that hold across the references

- Compute every paired difference before writing a range or "about the same", and give it a standard error clustered on the unit that shares shocks (game, date, week), not on rows.
- Anything shared by every row on one date (calendar contrasts, market-wide features, a recalibration layer's gain) needs dates, preferably weeks, as clusters.
- State the denominator of every relative figure ("% over Platt" is relative to the uncalibrated loss or to Platt's own loss; the two differ).
- Join predictions from different models on the full row key and assert row counts and labels match; never align by row order.
- Post hoc diagnostics are exploratory: label them so, and do not let them change a pre-registered outcome.
- Scope every conclusion to the heads, populations and splits actually measured.

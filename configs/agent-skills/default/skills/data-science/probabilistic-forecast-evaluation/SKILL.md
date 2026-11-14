---
name: probabilistic-forecast-evaluation
description: Evaluate probabilistic forecasts and simulated laws, including lookup comparisons, calibration drift, related probability outputs, and Monte Carlo scoring bias.
---

# Probabilistic forecast evaluation

Probability scores can reflect leakage, sampling bias or dependence rather than forecast quality. These references distinguish those effects from predictive information and calibration.

| Task | Reference |
|---|---|
| Attribute a lookup comparison or test incremental information | [Lookup attribution](references/lookup-gate-loss-attribution.md) |
| Diagnose calibration changes over time | [Calibration drift](references/calibration-drift-diagnosis.md) |
| Audit related probability heads | [Probability families](references/probability-family-audit.md) |
| Score sampled simulator laws and consider exact composition | [Rollout scoring](references/rollout-law-scoring.md) |

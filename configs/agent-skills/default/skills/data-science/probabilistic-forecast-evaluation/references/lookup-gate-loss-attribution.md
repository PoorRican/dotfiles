# Attributing a loss to a cross-fitted lookup

A lookup cross-fitted on the evaluation population can differ from a model because of calibration, information, or, for mixtures, branch weights. Cross-fitting does not guarantee held-out calibration. Reproduce the compared predictions and outcomes, joining by keys and checking row and label parity before diagnosing a gap.

## Comparators

Compare the raw model with recalibration fitted outside the scored fold, and with a stack combining model and lookup. Binned rates and logistic recalibration can differ; measure both where useful. A realized-branch oracle assigns weight to the branch that actually occurred: it uses future information and is not a forecast. Its performance diagnoses the branch laws under that oracle, not proof that a deployable weighting model can achieve it. Read the laws actually used by the gated predictor; ungated branch exports can misstate the oracle.

For a stacker fitted on an outer training fold, do not use globally out-of-fold lookup values whose source includes the outer held-out outcomes. Build fit-fold cell rates without held-out labels, using the same minimum-cell rule and pooled fallback, then apply the appropriate held-out lookup rates. Use the nested construction below when cross-fitting training-row features.

Use paired scores and cluster uncertainty by the unit sharing shocks. Compare calibration, discrimination and resolution as well as the overall score; lookup cells create ties, so AUC must handle ties. Do not assess calibration in strata defined by a future successor. Similar AUC and a reduced gap after recalibration are consistent with calibration contributing to the gap, not proof that information is identical.

## Incremental information over a later-state lookup

- Fit cross-fitted outcome models with `logit(lookup)` both with and without `logit(model)`. Report the paired held-out log-loss difference with a clustered SE.
- Nest the lookup inside each outer split: held-out rows in fold f use a lookup excluding f, and training rows in fold g use a lookup excluding both f and g. A lookup that is merely globally out-of-fold leaks the held-out fold's labels into the training rows' features and the fitted recalibration.
- Fit the model's forecast at the later origin as the no-lag comparator.
- Shuffle model values within each lookup cell and fold to examine the cell-level contribution to a disagreement rule's payoff. Observed minus shuffled is a within-cell association diagnostic, not an edge, and has no SE because row shuffling ignores dependence between rows of one cluster.
- Report each side of a two-sided disagreement rule separately, and compare the model-lookup gap with the realised-lookup gap to expose overconfidence.

A finding on the evaluated folds does not automatically transfer to a new population or a deployable fit; assess candidate recalibration and stacking on independent data.

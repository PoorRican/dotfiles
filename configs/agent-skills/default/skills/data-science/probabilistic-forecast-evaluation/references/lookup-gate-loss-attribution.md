# Attributing a loss to a cross-fitted lookup

Scope: a model, branch tree or mixture forecaster that loses a registered Brier or CRPS gate to a state lookup or counting table cross-fitted on the evaluation split, and the related question of whether an earlier model probability adds anything over a lookup at a later state. Everything here is post hoc and exploratory; label it so and add it to a closed run record only as a dated addendum.

## What a loss can mean

The lookup's cell rates are cross-fitted on the evaluation split itself (for example on `id % 2` folds), so it is calibrated to the split by construction and the model is not. A loss can therefore be:

- miscalibration;
- missing information;
- for a tree or mixture, wrong branch weights even though the branch laws are right.

Each points to a different next step at a very different cost, so run this before proposing a rerun.

## 1. Reproduce first

- Rebuild the registered prediction from the registered inputs and assert its metric equals the receipt to every digit.
- Recompute the realized outcome and assert the maximum difference from the registered one is 0.
- Join every array on its keys with a one-to-one validation, never by row order.

## 2. Predictors to score

Pair each predictor against the lookup with the run's clustered bootstrap.

- **Raw model**, as registered.
- **Recalibrated model**, fitted on the other fold using exactly the lookup's folds. Quantile-binned event rates are the primary form; logistic regression on `logit q` (with a small floor) is the check.
- **Stack**: logistic regression on `logit q` and `logit lookup`, fitted on the other fold.
- **Realized-branch oracle** (trees and mixtures only): all branch-weight mass on the branch that happened. It sees the outcome, so it is not a forecast; its recall is the ceiling for any weight model with these branch laws and its false rate is branch-law noise.

Stack leak trap: the registered lookup prediction on a fit-fold row was computed from the held fold's outcomes. Fit the stacker on the fit fold's own cell rates, with the same minimum cell and pooled fallback, then apply it to the held fold with the registered rates.

## 3. Read-outs

- Mean prediction against the event rate.
- AUC with tie-averaged ranks (lookup cells tie heavily, so a plain rank AUC is wrong).
- Binned Brier reliability, resolution and uncertainty.
- Oracle recall and false rate, overall and by successor type. Strata defined by what happened next are for oracle recall only, never for calibration.

## 4. Reading the pattern

| Pattern | Reading | Next step |
|---|---|---|
| Equal AUC and recalibration closes most of the gap | Calibration, not information | A better weight model or a train-fitted recalibration could flip the gate; that needs a new registration |
| Stack beats the lookup with an interval excluding 0 | The model carries information the lookup lacks | A candidate for a registered combined predictor |
| Oracle recall high | Branch laws are fine, weights are the problem | Improve the weights, not the laws |
| Oracle recall low | The laws cannot show the jumps | Better weights cannot help |

## 5. Does a model probability add over a lookup at a later state?

- Fit a cross-fitted logistic of the open outcome on `logit(lookup)`, once with and once without `logit(model)`. Report the paired held-out log-loss difference with a clustered SE.
- Nest the lookup inside each outer split: held-out rows in fold f use a lookup that excludes f, and training rows in fold g use a lookup that excludes both f and g. A lookup that is merely globally out-of-fold leaks the held-out fold's labels into the training rows' features and the fitted recalibration.
- Fit the model's forecast at the later origin as the no-lag comparator.
- A within-cell shuffle of model values (permute within each cell and fold) gives the cell-level part of a disagreement rule's payoff: lookup noise plus the gap between this cohort's outcomes and the lookup. Observed minus shuffled is a within-cell association diagnostic, not an edge, and has no SE because row shuffling ignores dependence between rows of one cluster.
- Report each side of a two-sided disagreement rule separately, and compare the model-lookup gap with the realised-lookup gap to expose overconfidence.

## 6. Before paying for a rerun

- Name the gate and the arm that could flip the decision. An arm whose own contrast already controls the suspected confounder cannot.
- Reuse existing checkpoints to export the structure (for example branch weights) and rebuild the tree under the new reading before refitting under a new schedule.
- Confirm a pass maps to a registered outcome label. If the frozen outcome also needs a gate that already failed, register the rerun with the new reading defined up front.

## Pitfalls

- Mixing gated and ungated laws: in a gated branch table, per-origin branch probabilities may be the ungated law because the gate touches only enumerated branches. Read gated realized laws from the export that applied the gate, joined on keys, or the oracle's recall looks far lower than it is.
- Quantile-binned recalibration can beat logistic recalibration on `logit q`; report both.
- Using successor-type strata to judge calibration (they condition on the future).

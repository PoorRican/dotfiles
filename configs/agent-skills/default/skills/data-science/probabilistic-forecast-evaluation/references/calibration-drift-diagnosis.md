# Diagnosing week-to-week calibration drift

Scope: a probability model whose observed/predicted ratio drifts by date or week beyond noise, where someone proposes calendar, entity or market-activity explanations, or where an expanding-history intercept recalibration failed and you must not conclude the level is unpredictable.

## Procedure

1. **Rows.** Use out-of-fold predictions only, joined on the full row key with row-count and label-equality assertions. Deduplicate metadata before joining (a duplicated listing silently doubles rows) and assert the row count is unchanged after every join.
2. **Aggregate per game and per date.** `O = sum of labels`, `E = sum of predictions`; the ratio estimator is `R = sum O / sum E` with cluster SE `sqrt(sum (O - R*E)^2 / (sum E)^2 * n/(n-1))`.
3. **Outliers.** Find the share of positive excess `(O - E)` in the top 1, 5 and 10% of games and the top dates by excess; check whether the top games share dates.
4. **Decompose game `log(O/E)`** into within-date and between-date variance. Within-date: `sum (lr - date mean)^2 / (N - D)` minus the mean Poisson noise (about `mean(1/O)`). Between-date: variance of date means minus `mean(within/k)`. A date sd about equal to the game sd makes the date the primary unit.
5. **Cross-head coherence.** Correlate date-level `log(O/E)` across sides, sizes and horizons; a high correlation means one shared day state, not head-specific noise.
6. **Calendar contrasts need dates as clusters** (Welch SE on date log-ratios). Game-clustered SEs overstate these contrasts because every game on a date shares one shock. Then fit calendar one-hots as a recalibration layer on alternate weeks and score the held-out weeks.
7. **Entity effects net of the date.** Residual = game `log(O/E)` minus its date mean; per-entity mean and SE; count entities beyond 2 SE against the chance count; check split-half stability (a correlation near 0 means no usable effect).
8. **Activity.** `O/E` by quintile of a causal activity count, then whether it adds beyond intercept-plus-slope and beyond trailing surprise.
9. **Persistence.** Correlate date `log(O/E)` with the previous date and previous-3/7 means, and with within-date halves. Persistence over hours points to short trailing windows; over weeks, to expanding fits.

## Causal trailing-surprise layer

- **Features**: `log((O + a) / (E + a))` over resolved rows in `[t - W, t - lag]`. Use market-wide windows (hours to a day, `a` about 20) and a same-entity short window (`a` about 10).
- **Lag**: label horizon plus execution latency, rounded up, so every label used is resolved by `t`.
- **Model**: offset logistic, `logit q = logit p + X beta` with `X = [1, logit p, features]`; Newton/IRLS with a tiny ridge is enough.
- **Fitting**: strictly walk-forward (fit on all weeks before w, score week w), against Platt (`[1, logit p]`) fitted the same way. Odd/even-week swaps are a quick screen; confirm with strict walk-forward.
- **Report**: percent log-loss change with a clustered SE, weeks improved out of weeks scored, weekly sd of `log(O/E)` before and after, AUC, and the number of cells actually covered (count before writing "all N cells").
- **Denominator**: write `(LL_Platt - LL_layer) / LL_raw` (share of the uncalibrated model's log loss) or relative to Platt's own loss, and name the layer variant (feature windows, source rows) with each figure. The two denominators and different variants give different numbers.
- Windows chosen on the same weeks they are scored on need confirmation on unseen dates. Refit cadence (daily versus weekly layer coefficients) is its own small effect; measure it rather than assuming.

## Limits to state

- Trailing surprise tracks capture or replay artifacts as readily as real behaviour, so better calibration does not identify the cause.
- Participant identity is usually unobservable, so market-participant explanations cannot be tested.
- A retrospective layer evaluated on rows is not yet a model input.

## Related split and wording traps

- Span and refresh frequency are confounded in time-block splits: a long training window refreshed weekly can beat a short window refreshed on the same dates on nearly every head, so a month-block loss may be staleness, not span. Compare equal evaluated rows and measure a replicate-minus-canonical noise floor.
- Say "label-positive rows", not "calmer" or "fewer events": overlapping rows can label one episode, and per-game counts do not control contract or state mix.
- Track a fast-moving state online (the trailing layer) rather than with calendar or regime labels; one season cannot show calendar-linked spells recur.

## Pitfalls

- A failing expanding-history intercept shows its memory is too long, not that the level is unlearnable.
- Two models' `O/E` ratios share the observed numerator, inputs and training rows, so their correlation is not evidence of a market change.
- Volume-normalized diagnostics (mismatches per million messages) are not probabilities; state the denominator.
- Audits of retained rows cannot establish completeness: rows vanish where capture was lost. Inspect what quality control excluded, and do not claim completeness from retained rows.

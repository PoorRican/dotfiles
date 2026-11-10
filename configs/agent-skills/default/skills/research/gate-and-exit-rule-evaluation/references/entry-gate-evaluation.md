# Evaluating a gate on a strategy's entries

Scope: a veto, deferral, filter or entry-timing rule (adverse-move or path model, nowcast veto, patience rule) acting on a base strategy's proposed entries. With one entry per contract, a refused row usually leaves that contract's later proposals eligible, so the gate's value is the difference between the gated and the base entry sets. Settle the mechanics before reading a contrast.

## Procedure

1. **Reproduce the base first.** Rebuild the base and any existing arms from the same inputs and fail closed unless entries, per-contract totals and fixed-stake totals match the reference run exactly. A gate study on a drifted base measures the drift.
2. **Count before you contrast.** Per strategy report: proposal rows and contracts; the share of contracts with later proposals; the gate's firing rate on proposal rows; how many base entries it actually changes. If it changes only a few percent of entries the contrast is descriptive whatever the model knows; say so.
3. **Decompose every arm-minus-base difference** into contracts entered at the same row, contracts entered later (price change and delay) and contracts never entered (what they would have netted). Deferral gates usually lose by losing contracts, not by re-entering at a worse price.
4. **Compare with a placebo at a matched rate.** Each model-ranked arm faces random deferral at the model's deferral share among the rows the base accepts. All proposal rows is the wrong denominator: a model that defers rows the base refuses anyway would be matched by a placebo that defers real entries. Fix a seed per arm, report the model's percentile within the draws per contract and per stake, and unit-test the denominator with a case whose deferrals cluster in base-refused rows.
5. **Name benchmarks honestly.**
   - Perfect-label deferral (defer exactly the rows whose realised label was bad) measures perfect classification under the re-entry rule. It is not an upper bound: waiting for the next proposal can lose a profitable entry outright.
   - Hindsight timing bound: move each base entry to the cheapest allowed later entry for the same contract and side (price plus exact fee, payout unchanged). It needs hindsight on prices only. Report how many entries move, the quantiles of the saving and the delay.
   - A true upper bound over "enter later or skip" also needs hindsight on settlement. Label which bound you computed.
6. **Measure discrimination separately from economics.** Score the gate's own label with AUC (or the relevant loss) on proposal rows and on entries, against a market-only comparator, with clustered intervals. A model can rank its label well and be worthless as a gate, and the reverse.
7. **Treat post-entry timing as exposure only.** The first time the price crosses a threshold after the decision shows latency exposure; it does not show whether the move persisted or what a delayed fill would have netted. Measure persistence with delayed-fill backtests that fill at the touch 1, 2 and 5 seconds after the decision.
8. **Verify the numbers.** Recompute headline numbers (rates, thresholds, arm totals, the bound, the AUC through a library) with an independent row loop, and require local and cluster runs to agree at 1e-12 relative.

## Claim discipline

- Say only what was tested: "no tested arm resolved positive". Do not attribute a failure to the label or to the fit unless a label-versus-fit experiment was actually run.
- Hindsight headroom generates hypotheses, not limits: a long-horizon bound does not show a short-horizon model cannot anticipate those cases.
- Record the order of work. Thresholds chosen on the data being scored (top-k shares, bounds added after a first look) are exploratory.
- Scope every null to the learner, population, label and re-entry rule tested.
- When a reviewer flags a claim, correct the code docstring, the report, the log and the memory together.

## Report shape

Per strategy and base: the base summary; the fire rate and number of changed entries; per arm the change in stakes and in net with clustered intervals, the decomposition and the placebo percentile; the benchmarks; discrimination; timing exposure. Put proposals for a pre-registration last, separate from findings.

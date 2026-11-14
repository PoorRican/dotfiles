# Evaluating an entry gate

A veto or deferral can change a position's entry time or prevent entry entirely. Reproduce the base on the same inputs before attributing differences to the gate; reconcile entries and accounting at a tolerance appropriate to the computation.

- Count proposals, the gate's firing rate, base entries changed and later entry opportunities. A gate may frequently fire without changing many accepted entries.
- Decompose the arm-minus-base result into positions entered on the same row, entered later, and never entered. For later entries separate price and delay; for missed entries report their counterfactual base outcome.
- Compare with random deferral matched to the gate's firing rate on base-accepted rows. Matching on all proposals can make the placebo defer actual entries even when the model mostly defers rows the base would reject. Use multiple draws and report the model's position in their distribution.
- A perfect-label deferral is not necessarily an upper bound: the re-entry rule can turn a correctly deferred bad row into a missed profitable position. A hindsight cheapest-later-entry benchmark uses future prices; a bound that also permits skipping needs settlement hindsight. Name the information each benchmark uses.
- Measure discrimination on the relevant proposals and accepted entries separately from economic outcomes. Good ranking need not produce economic value and a weak label score does not by itself settle the policy question.
- A price crossing after a decision measures exposure to latency, not persistence or the outcome of a delayed fill. Evaluate delays and fill assumptions relevant to the execution setting.
- Cluster uncertainty at the unit sharing shocks, and scope conclusions to the tested policy, population, label and re-entry mechanics. Thresholds chosen on scored data require independent evaluation for a prospective claim.

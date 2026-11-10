---
name: gate-and-exit-rule-evaluation
description: "Use when judging whether a veto, deferral, filter, entry-timing gate, exit, stop or catch rule beats its base strategy, holding, or random timing in a backtest or on out-of-fold rows: base reproduction, matched-rate placebos, cost/information decomposition, detector coverage versus protection, and claim discipline."
---

# Gate and exit rule evaluation

A rule that acts on a strategy's entries or held positions is judged by the difference between the rule's outcome and the base, but mechanics (how often it fires, what happens after a refusal, what a failed exit leaves behind) dominate that difference before any model skill shows. These references settle the mechanics first and then fix what a result may claim.

| When you are… | Open |
|---|---|
| Judging a veto, deferral, filter or entry-timing gate on a base strategy's backtested entries | [references/entry-gate-evaluation.md](references/entry-gate-evaluation.md) |
| Deciding whether an exit, catch, stop or value-gated add on held binary-outcome positions beats holding or random timing | [references/exit-rule-decomposition.md](references/exit-rule-decomposition.md) |
| Answering risk questions from out-of-fold detector predictions (coverage, recovery of flagged falls, warning time, cutoffs) without overclaiming | [references/exit-detector-claims.md](references/exit-detector-claims.md) |

## Rules that hold across the references

- Reproduce the base from the same inputs first and fail closed unless it matches the reference run exactly.
- Count before contrasting: how often the rule fires and how many base decisions it actually changes.
- Compare against a random twin at a matched rate, with the denominator the rule actually acted on (rule evaluations or base-accepted rows, never every eligible instant).
- Decompose every difference into groups that move for different reasons (same-row, later, never-entered; cost versus information) before reading a model effect.
- Say only what was tested; scope every null to the learner, population, label and re-entry rule. Correct a reviewed claim at its source (docstring, report, log, memory) together.

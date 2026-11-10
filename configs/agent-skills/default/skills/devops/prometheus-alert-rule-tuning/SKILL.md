---
name: prometheus-alert-rule-tuning
description: "Use when changing when a Prometheus alert fires (a noisy alert, a missed incident, a threshold, for:, a label split or a gate) or adding an alert or recording rule: replay the current and candidate rules on history with for: semantics, split failure classes, write promtool boundary and mutation tests, then apply and verify rule loading and delivery."
---

# Prometheus alert rule tuning

An alert threshold picked by eye either keeps paging on a benign class or goes silent in the incident it was meant to catch. The method is: replay the rule on real history until the replay reproduces what actually fired, choose per-class thresholds from the surviving episodes, pin both sides of every boundary with promtool tests that a mutation check proves are sensitive, and only then apply and verify delivery.

| When you are… | Open |
|---|---|
| Reading the existing rule, replaying it on history, splitting failure classes or designing a threshold, `for:` or gate | [references/replay-and-rule-design.md](references/replay-and-rule-design.md) |
| Writing promtool tests for a threshold, label or `for:` and proving them with a mutation harness | [references/promtool-boundary-and-mutation-tests.md](references/promtool-boundary-and-mutation-tests.md) |
| Merging, applying the rules overlay and checking that rules load and alerts are delivered | [references/apply-and-verify.md](references/apply-and-verify.md) |

## Rules that hold across the references

- Replay the current rule first and require the replay to reproduce `ALERTS{alertstate="firing"}` history before trusting any candidate number.
- Do not raise a shared threshold to silence one benign class; split by class and give each its own bound.
- Prefer absolute error-class rates to ratios; ratios go undefined when backoff collapses attempts, which is exactly what starvation looks like.
- Put the backtest window, its numbers and the surviving episode in a comment above the rule.
- Satisfy whatever review gate the owner requires before merging; an analysis or a green test run authorizes no production apply by itself.

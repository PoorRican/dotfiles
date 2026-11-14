---
name: prometheus-alert-rule-tuning
description: "Use when tuning or adding Prometheus alert or recording rules: replay firing history, test thresholds and timing, and verify that deployed rules load and notifications reach their destination."
---

# Prometheus alert rule tuning

Thresholds, evaluation timing and missing metrics can turn a useful alert into noise or hide an incident. Compare proposed behavior with historical episodes and test the rule's boundaries before relying on it.

| Task | Reference |
|---|---|
| Replay alerts and choose thresholds, labels and gates | [Replay and design](references/replay-and-rule-design.md) |
| Test boundaries, apply and verify rules and delivery | [Tests and verification](references/promtool-boundary-and-mutation-tests.md) |

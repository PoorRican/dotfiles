# Logging and sparse telemetry

Scope: how `self.log` interacts with intermittent metrics, observed on Lightning 2.x (2.6.6, 2026-10); re-check behavior on other versions.

## Intermittent metrics are re-emitted

- Lightning 2.x re-emits every `self.log(..., on_step=True)` value at every later logger flush within the same epoch. A metric logged only every N steps (telemetry sampled every 50 steps, for example) therefore appears as byte-identical stale copies at the intervening steps instead of as sparse points. (src: lightning-sparse-logging; 2026-10)
- Send sparse samples directly through `logger.log_metrics(metrics, step=global_step)` instead of `self.log`. (src: lightning-sparse-logging; 2026-10)
- Test it with several optimizer steps inside one epoch. A test that logs once per epoch, or a single step, cannot show the repetition. (src: lightning-sparse-logging; 2026-10)

See the weights-and-biases skill's `references/metric-hygiene.md` for what to log and how to prove a restructure with a before/after key census.

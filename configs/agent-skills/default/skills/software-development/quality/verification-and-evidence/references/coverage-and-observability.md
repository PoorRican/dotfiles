# Coverage and observability

Scope: distinguish completed work and usable health signals from silent omissions and upstream activity.

## Work coverage

- Failure-only monitoring cannot detect work that was never proposed; an empty retry result means no failed work to retry, not an empty backlog. Coverage evidence is stronger when newest available and newest completed units are compared per stream, because aggregates can hide a dead stream; a stalled dependency may trace to the earliest frozen upstream stage. (src: automation-coverage-audit, 2026-08-09)
- Positional cache joins can pair values with the wrong identity; inner joins, missing keyed artifacts, and exact lookup fallbacks can silently drop new entities/periods or yield default values. Identity-keyed joins and post-join coverage by relevant partition/entity expose these cases. Smoke runs are comparable only when input roots remain fixed and the expensive output/work stage is narrowed; changing fitted priors or split boundaries changes the question. (src: long-running-pipeline-hardening, 2026-08-16)
- Is a green report independent of its own writer? An independent population census and a consumer-shaped readback outside the publishing harness establish more than a writer agreeing with its own summary. Provisioned headroom and measured-minimal capacity are distinct claims. (src: qualified-full-corpus-launch, 2026-09-14)
- Is the launchable population a frozen census minus named exclusions, with reasons preserved in run provenance? A recently added fail-closed guard can turn an excluded member into a late whole-run failure if the population is inferred only during execution. (src: qualified-full-corpus-launch, 2026-09-14)
- At low cohort sizes, not all workers may start; total resource use per unit can therefore imply a fictitious slope. Parent retention measured directly and a `parent + workers × per-worker` estimate are distinct quantities, as are provisioned headroom and proven-minimal capacity. (src: qualified-full-corpus-launch, 2026-09-14)

## Signal meaning

- A signal name alone does not establish useful observability. A signal that exists only on failure, sits behind a healthy-path early return, or fires only after qualification may be silent in both states; evidence depends on its emit site and control-flow reachability. (src: observability-claim-verification, 2026-08-06; observability-signal-verification, 2026-08-06)
- Opportunity and liveness are distinct: `evaluated=N, qualified=M` can separate a healthy quiet period from a path that never evaluated, while linked-versus-expected counts expose partial degradation. Upstream subscriptions or activity do not prove that the downstream decision/processing stage is alive, and one leg's freshness does not establish a multi-leg path's health. (src: observability-claim-verification, 2026-08-06; observability-signal-verification, 2026-08-06)

## Observation and freeze evidence

- A freeze rule that pauses a bounded drain or cleanup path can fill its buffer and exhaust disk, creating the outage it is intended to prevent. This secondary hazard belongs in the freeze-versus-alert judgment. Known alert-only cases are distinguishable by stable signatures; unknown causes remain fail-closed, and the same classification should cover new and in-flight failures. (src: supervised-observation-window, 2026-08-08)
- If the watcher dies while production continues, durable system records can reconstruct the gap; a truncated success page does not establish zero failures. A changing deployment stack prevents a steady-state window, so an interrupted or truncated observation is incomplete rather than a completed window. (src: supervised-observation-window, 2026-08-08)

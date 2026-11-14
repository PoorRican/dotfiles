# Coverage and observability

## Work and signals

- Failure-only monitoring cannot detect work never proposed; an empty retry queue does not prove an empty backlog. Compare newest available and completed units per stream; aggregates can hide a stalled stream.
- Positional joins can associate values with the wrong identities, while inner joins and missing keyed artifacts silently drop entities. Check keyed post-join coverage by relevant partition and entity against an independent census.
- A signal may be silent in both healthy and failed states if it emits only on failure or sits behind an early return. Inspect its emit site and reachability. Separate opportunity from qualification and upstream activity from downstream liveness.
- A freeze that pauses a bounded drain or cleanup can fill buffers and create an outage. Account for that secondary hazard when choosing the response. Interrupted observation or a truncated results page is not a completed healthy window.
- Overlapping time-series query chunks can double-count inclusive endpoints. Deduplicate by series identity and timestamp, verify overlaps agree, and compare against the expected time grid. Query lookback can reuse old samples, so a nonempty range is not proof of continuous fresh recording; an empty alert series during a coverage gap is not proof of no alerts.

## Partitioning and fan-out

- Configured partition count does not prove failure blast radius or balanced routing. Compare the full population, per-partition distribution and actual live labels; label namespace differences can distort counts. A reduced-load soak establishes only the behavior tested at that load.
- Identifiers or sequence counters may be per connection rather than global. Test multiple distinct instances: a singleton cannot reveal collisions or incorrect aggregation.
- A shared readiness boolean written by each instance can let the last healthy writer mask failed peers. Compare readiness against the expected work-bearing population; pruning state for temporarily empty work can wedge an open connection that will not emit another connect event.

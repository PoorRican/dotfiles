---
name: kairos-collector-performance-baseline
description: Capture and interpret a durable before/after performance baseline for Kairos collector workers and orchestrator
---

# Kairos collector performance baseline

Use this procedure before and after collector worker, subscription, snapshot, or orchestrator changes.

## Capture

1. Record UTC timestamp, image digest/build SHA, pod start time, and restart count.
2. Query per-container Prometheus series—not pod aggregates—for CPU, RSS, and working set.
3. Collect accepted event/row rates by dataset and series, writer queue depth, and ingest/flush ages.
4. Read worker `/state/subscriptions` for retained binding and family cardinality.
5. Measure periodic snapshot requests and confirmed markets per request. Keep request frequency separate from traversal cardinality.
6. Derive rates from five-minute worker heartbeat counter deltas. Summarize conditional channel and record-bus backpressure rather than counting warning lines alone.
7. Capture orchestrator CPU/RSS and host disk throughput, utilization, load, and I/O wait.
8. Query a multi-day Prometheus range at fixed resolution. Compare percentiles, quiet/busy regimes, and sustained high-CPU episodes rather than relying on one htop sample.
9. For suspected stale bindings, sample event IDs and verify terminal status through the authoritative Kalshi API. Dates or one empty query are not proof.

## Interpretation

- Treat `/state/throughput` as a cardinality/attribution surface, not a true rolling-rate source: its window parameter may be echoed while old quiet rows retain cumulative counts.
- Compare accepted throughput, ticker traffic, subscription cardinality, and snapshot markets/request independently.
- Correlation is not causation. Label lifecycle/snapshot CPU attribution as a hypothesis until a profile or controlled A/B establishes it.
- Distinguish market activity from games currently in progress; no canonical active-game gauge exists unless a change adds one.
- Evaluate individual samples against source truth and macro time-series distributions together.

## Durable record

Append exactly one independently parseable JSON object to `kairos-infra/docs/collector-health-snapshots/snapshots.jsonl`. Preserve metric-scope caveats, especially when older snapshots contain pod aggregates rather than per-container values. Parse every JSONL line independently and run `git diff --check`. Publish through a branch and PR; do not apply infrastructure live for a documentation-only baseline.

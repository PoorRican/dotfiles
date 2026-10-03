# Cost attribution

Scope: mechanisms for locating cost and deciding what a benchmark actually establishes.

## Attribution to the executed path


- Which exact process, function, step, or span produced the timing, and does that measured path reach the code the proposed optimization targets? A duration attached to one unit does not establish cost in a different, merely related unit. (src: perf-issue-claim-attribution-audit)
- Invocation counts establish frequency, not duration. Likewise, idle-system I/O or throughput probes do not reproduce the running process’s cache, connection reuse, concurrency, or contention state; phase wall times and counts measured in a realistic run distinguish repeated work from genuinely expensive work. (src: opaque-step-cost-attribution)
- With a reported logical-to-physical work ratio, the implied multiplier can be factored into passes and fan-out. Separately issued per-entity queries do not share scans merely because they read the same input; a large ratio can indicate query fan-out rather than a few full passes. (src: perf-issue-claim-attribution-audit)
- Have partial prior art and postmortems been checked? They can show that a plausible optimization already exists or is contradicted by the measured mechanism. (src: perf-issue-claim-attribution-audit)


- A measured stage’s share matters to an end-to-end estimate: a component made several times slower may barely affect total time if it was a small fraction of the original pipeline. Component latency and whole-pipeline impact are distinct quantities. (src: checkpoint-cpu-gpu-benchmark-from-fixtures)



## Comparison validity


- When real outputs change downstream branches, call counts, or loop lengths, comparing full-run times confounds component cost with a changed workload. One attribution design executes the real component at its real call frequency and context, discards its result, and returns the baseline value; matching output digests then establish that the downstream trajectory stayed fixed. This estimates component cost on that trajectory, not output fidelity or output-distribution-dependent downstream cost. (src: fixed-output-cost-attribution)
- Benchmark inputs derived from the component’s real schema and populated with varied plausible values avoid a constant-input strawman. A benchmark report can distinguish real from synthetic inputs and work; schema realism alone does not make a synthetic-value benchmark a production end-to-end measurement. (src: fixed-output-cost-attribution)

- Component-off comparisons are interpretable when a real production dial suppresses its calls and the remaining consumer-visible inputs, outputs, and attempts stay equivalent. If disabling it also removes a downstream consumer, that consumer’s cost is part of the measured delta. (src: load-matched-cost-decomposition)
- Shared-host absolutes drift with co-tenant load. Back-to-back comparisons under matched conditions support a ratio or delta; an absolute from a quiet run is a separate anchor, not a substitute for the matched comparison. (src: load-matched-cost-decomposition)
- A batch’s wall time is not each member’s historical per-item latency. Batching can change both measured latency semantics and downstream behavior when timing is itself an input. (src: load-matched-cost-decomposition)

## Fit, compatibility, and speed


- A checkpoint’s saved hyperparameters and state dictionary can reconstruct the model’s actual tensor shapes; random parameter values suffice for forward-latency timing when shapes are faithful, and schema-valid synthetic fixtures can avoid an unrelated production data pipeline. Checkpoint size, software/API compatibility, forward latency, and end-to-end cost are distinct questions. (src: checkpoint-cpu-gpu-benchmark-from-fixtures)
- For small-batch inference, launch and fixed latency can dominate, so peak-FLOPS ratios may greatly overstate the measured CPU/GPU speed ratio. (src: checkpoint-cpu-gpu-benchmark-from-fixtures)
- A faster implementation is an optimization of a validated path only when values at the consumer’s actual reads remain equivalent. Similar state can omit observation moments and change decisions, so equivalence is judged at the consumer’s reads and in light of any changed timing or observation frequency. (src: load-matched-cost-decomposition)


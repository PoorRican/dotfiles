---
name: performance-and-throughput
description: "Use when a pipeline, model, training loop, or data path is slow or memory-hungry; for cost attribution, performance-claim review, RSS growth, CPU/GPU benchmarking, loader starvation, CPU-bound training, container-only CUDA faults, streaming-cache thrash, and memory or numerical blowups."
---

# Performance and throughput

Performance claims often confuse a measured component with end-to-end cost, or mistake a workload’s current representation for an inherent limit. The references separate cost attribution and benchmark validity, memory and numerical behavior, training-loop bottlenecks, and streaming-dataset cache/layout effects. They emphasize mechanisms that can make an apparent speedup misleading or change the computation being measured.

| When you are… | Open |
|---|---|
| Attributing elapsed time, checking a proposed hotspot, or comparing component costs | [references/cost-attribution.md](references/cost-attribution.md) |
| Diagnosing RSS growth, peak memory, accumulation, or non-finite values | [references/memory-growth-and-numerics.md](references/memory-growth-and-numerics.md) |
| Distinguishing CPU, GPU, loader, and step bottlenecks or investigating CUDA faults | [references/training-loop-throughput.md](references/training-loop-throughput.md) |
| Working with Mosaic StreamingDataset caches, shuffling, or merged shard indexes | [references/mosaic-streaming.md](references/mosaic-streaming.md) |

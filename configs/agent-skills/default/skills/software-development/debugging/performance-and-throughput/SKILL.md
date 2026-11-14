---
name: performance-and-throughput
description: Diagnose slow or memory-hungry pipelines and training workloads, benchmark performance changes, and investigate native heap growth or GPU kernel replacements.
---

# Performance and throughput

Performance diagnosis separates the cost of the executed workload from unrelated phases, measurement overhead, and changes to the computation. Misattribution can make a fast component look like an end-to-end improvement or conceal a correctness regression.

| When | Reference |
|---|---|
| Attribute costs or compare benchmarks | [Cost attribution](references/cost-attribution.md) |
| Diagnose memory growth, native heaps, or numerical failures | [Memory growth and numerics](references/memory-growth-and-numerics.md) |
| Diagnose loader, CPU, GPU, and streaming-cache throughput | [Training-loop throughput](references/training-loop-throughput.md) |
| Replace an eager recursion with a fused GPU kernel | [Fused kernel replacement](references/fused-kernel-replacement.md) |

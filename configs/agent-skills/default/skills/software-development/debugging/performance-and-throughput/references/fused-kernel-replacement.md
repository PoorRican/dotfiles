# Fused kernel replacement

Scope: replacing a PyTorch eager recursion or a custom autograd Function with fused Triton kernels, from proving the bottleneck to attributing the speedup. Dated numbers are one 2026-10 project's observations, not expectations.

## Prove the bottleneck before writing kernels

- Compare per-step wall time between arms that differ only in the suspect component, then use synchronized timers and `torch.profiler` sorted by `cuda_time_total`. In one case 23.3 s/step against 1.2 s/step put about 95% of the step in a single dynamic-programming recursion. (src: fused-kernel-replacement; 2026-10)
- Low-precision formats pay only on large GEMMs, not on fp32 probability recursions. (src: fused-kernel-replacement; 2026-10)
- Capture real chunk inputs by monkeypatching the chunk builder to `torch.save` them, then iterate on kernel-only parity and timing from the file without the data loader. (src: fused-kernel-replacement; 2026-10)

## Design rules that held

- One program per independent row, looping over layers; no atomics (run-length merge so each destination is written once); skip provably zero work.
- Use `tl.dot(..., input_precision="ieee")`: the default TF32 breaks 1e-6 parity, and `tf32x3` is a numerics decision to escalate rather than make silently.
- Define kernels lazily, cache the compile-environment check (Triton importable and a C compiler present), and fall back to the reference path with a one-time warning when the check fails.
- Keep differentiable seeds in autograd, read `ctx.saved_tensors` once under `torch.utils.checkpoint`, and reuse the first forward's kernel outputs on replay within a bounded byte budget.
- Size chunks with the fused path's own memory estimator, not the reference path's.

(src: fused-kernel-replacement; 2026-10)

## Parity ladder (stop at the first failing rung)

1. Kernel-only on captured chunks (about 1e-7 in fp32).
2. Integrated per chunk, with per-row limits.
3. End-to-end in eval mode: total loss and maximum gradient error measured against the global gradient scale, judged against reference-to-reference spread.
4. A permanent test that skips without CUDA and compares against CPU float64, with a dispatch counter proving the fused path ran.
5. Cross-hardware rescoring.

(src: fused-kernel-replacement; 2026-10)

## Nondeterminism

- A bitwise-repeatability test that fails only after other tests have run points at `scatter_add`, `index_add_`, or `index_put_(accumulate=True)` with colliding indices. Reproduce with the exact test prefix, record stage outputs over identical calls to find the first differing stage, and replace the accumulation with a fixed-order reduction. (src: fused-kernel-replacement; 2026-10)

## Timing and attribution

- Triton compiles per specialization: warm every batch shape, discard the first pass, report the mean of the rest with `torch.cuda.max_memory_allocated`. Occupancy dominates; in one sweep per-row forward+backward fell from 1.97 ms to 0.52 ms as rows per launch rose from 43 to 344, so sweep chunk budget, tile size, and warps on captured chunks. (src: fused-kernel-replacement; 2026-10)
- Attribute a speedup before writing it down: run an untouched recipe on both hosts, and do not use a refit's final score to validate a kernel swap (same-code refits are the reference). Project budgets from the mean step plus the fixed per-epoch cost, not the median step. (src: fused-kernel-replacement; 2026-10)
- GPU microbenchmark hygiene (warm-up, profiler memory, run-to-run spread) is in [cost-attribution.md](cost-attribution.md).

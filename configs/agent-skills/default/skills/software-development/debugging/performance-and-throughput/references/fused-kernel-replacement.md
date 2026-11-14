# Fused kernel replacement

## Prove the bottleneck

Compare matched steps with and without the suspect component, then use synchronized timings and a GPU profiler to localize its cost. Capture representative real inputs for kernel-only parity and timing so loader variability does not obscure iteration.

## Preserve semantics

- Independent rows can be fused into separate programs with a loop over layers; where possible, arrange each destination to be written once and skip work proven to be zero.
- Dot-product precision affects parity: on supported NVIDIA tensor cores `tl.dot` defaults to TF32 for float32 inputs, which can truncate values; choose `input_precision="ieee"` when required by the reference tolerance and validate on the target device.
- Preserve differentiable inputs and checkpoint replay behavior; size chunks for the fused path's actual memory use, not the reference path's estimate.
- Compare captured chunks first, then integrated per-chunk outputs, loss, and gradients against the reference. Use baseline-to-baseline spread to set a meaningful tolerance; verify the fused dispatch actually ran and compare with a higher-precision reference where practical.
- Colliding indexed accumulations can be nondeterministic. If repeatability depends on prior execution, reproduce the exact test prefix, compare intermediate outputs to find the first divergence, and consider a fixed-order reduction.

## Timing and attribution

Warm each specialization before measurement and report steady-state runtime with peak memory. Sweep chunk size and launch configuration: insufficient parallel rows can underutilize the device, so per-row cost can change with work per launch. Attribute gains using matched code and workloads; a separately refitted model's final score does not establish kernel parity. Include fixed per-epoch work when projecting total runtime.

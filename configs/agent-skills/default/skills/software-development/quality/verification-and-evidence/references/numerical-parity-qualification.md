# Numerical parity qualification

Scope: qualifying a numerical path (model forward, inference service, kernel) on new hardware or a new runtime without letting one passing property stand in for the others. A verification recipe, not authorization to spend compute or to bypass resource contention.

## Separate the questions

- Input/schema parity, numerical reference parity, fixed-runtime repeatability, consumer-decision sensitivity, and end-to-end qualification are different claims. Passing one does not pass the others; the report names which one was measured. (src: gpu-inference-qualification; 2026-10)
- Pair canonical row keys one-to-one, preserve order, and reject missing rows, null or non-finite values, and out-of-support values explicitly. `NaN > tolerance` is false in IEEE arithmetic, so a gate that only tests "difference exceeds tolerance" can pass on a column of NaNs. (src: gpu-inference-qualification; 2026-10)
- A fixed numeric fixture with a tight tolerance may be encoding same-architecture reproducibility rather than the property under test; see [verification-instrument-trust.md](verification-instrument-trust.md) before loosening or trusting one.

## Tolerances and discrepancy reading

- Never set a tolerance from the observed maximum and never import another model's tolerance. A gap that passes on one fold or sample is not a tolerance for the next. (src: gpu-inference-qualification; 2026-10)
- BF16 variants run on the same GPU show execution sensitivity only. FP32/FP64 reruns are diagnostic references that help locate a discrepancy; they are not evidence of equivalence. (src: gpu-inference-qualification; 2026-10)

## Repeatability

- Run a same-process repeat and a separate fresh-process repeat with identical input, source, and runtime hashes, and observe actual equality. The same GPU model is not a determinism guarantee, and training on some GPUs is not bitwise reproducible run to run; rerun the baseline to measure that spread before attributing a difference to a code or image change. (src: gpu-inference-qualification; 2026-10)

## Ad hoc probes

- Record the baseline commit SHA, `source_dirty=true` when the tree was modified (untracked probe scripts ship with the source), and every module hash; verify the uploaded archive against the run's recorded code path rather than the working tree. (src: gpu-inference-qualification; 2026-10)
- Exit 0 only when the gates pass, a distinct code (for example 3) for a completed comparison that fails, and another nonzero code for an incomplete run, so an incomplete run can never read as a verdict.

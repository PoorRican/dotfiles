# Numerical parity qualification

- Input/schema parity, numerical reference parity, repeatability, consumer-decision sensitivity and end-to-end qualification are distinct claims. Name which were measured.
- Pair canonical row keys one-to-one, preserve order, and check missing, null, non-finite and out-of-support values explicitly. A gate testing only whether a difference exceeds a tolerance can pass NaNs because the comparison is false.
- Choose tolerances for the property and intended use, independently justified by relevant prior evidence; do not set them from the observed maximum or import another model's tolerance. A tight frozen fixture may encode architecture-specific reproducibility rather than the intended contract.
- Higher precision or alternate execution modes can diagnose discrepancies but do not themselves prove equivalence. Investigate comparator errors separately from actual numeric differences.
- BF16 variants on the same GPU measure execution sensitivity, not cross-runtime equivalence; FP32/FP64 reruns are diagnostic references.
- If attributing a difference to code or runtime, measure baseline repeatability with identical inputs, source and runtime identities. Compare both same-process and fresh-process repeats where relevant; identical hardware alone does not guarantee determinism.
- Record the actual executed source and uploaded archive identities. Untracked files are shipped only if the packaging mechanism includes them; a dirty working tree alone does not establish archive contents. Use distinct exit statuses for a completed failed comparison and an incomplete run.

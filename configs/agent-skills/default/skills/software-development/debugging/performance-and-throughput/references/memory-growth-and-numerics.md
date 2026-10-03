# Memory growth and numerical behavior

Scope: distinguish memory consumers and computational changes before interpreting growth or non-finite results.

## Memory terms by scaling behavior


- Activation transients scale with chunk or tile size; retained autograd graphs scale with work between backward calls; model, optimizer, and cache residency is comparatively fixed. A small chunk does not reduce total retained graph memory if every chunk’s outputs remain attached until one deferred backward. (src: training-memory-and-nan-localization)
- Gradient accumulation reduces peak graph memory only when each microbatch is backpropagated before the next graph is retained. For unequal microbatches, exact per-item mean-loss weighting uses each microbatch’s item count over the total item count; dividing by the number of accumulation steps is exact only for equal sizes. Batch statistics and nonlinear statistics such as variance or covariance hinges can also differ when evaluated per microbatch. (src: training-memory-and-nan-localization)
- On some unified-memory GPU platforms, CUDA allocations may not be charged to the pod cgroup, so a cgroup memory limit may not bound device allocations. Where that accounting boundary applies, a per-process CUDA fraction set before allocation can cap process allocations and cause an overrun to fail at the process rather than consume the shared pool; platform-specific accounting determines whether the cap is effective. (src: training-memory-and-nan-localization; 2026-09-20)



- A CPU-only smoke that inherits a batch sized for accelerator memory can exhaust host memory; a tiny smoke batch may answer shape/plumbing questions but does not establish full-batch feasibility. (src: cpu-smoke-never-inherits-gpu-batch)

## Python heap and process memory


- Large proportional file-backed PSS points toward mapped/file cache; large anonymous PSS alongside a small Python heap points toward native allocations, allocator arenas, or embedded-engine buffers rather than Python object accumulation. RSS is not a Python-heap measurement. (src: unbounded-rss-attribution)
- An embedded engine may grow toward its configured memory limit without leaking. The inverse trap is a worker connection that never applies the intended profile and instead uses a larger default; the active connection’s setting determines the real cap. Lowering a native-engine limit without a configured writable spill path can turn memory pressure into query failure. Spill storage capacity is separate from the memory limit, so a writable path can still run out of space. (src: unbounded-rss-attribution)

- A native kernel that buffers all results before returning still has memory proportional to total output. Faster execution or moving the kernel to another language does not by itself change that memory curve. (src: unbounded-rss-attribution)

## Numerical failures and evaluation bugs


- A repeatably identical set of non-finite elements suggests a structural subset; changing locations or counts suggest nondeterminism or instability. Checking stored inputs, collated batches, isolated forwards with finite substitutes for cached state, then the state-producing stage separates data, model, and cache causes. (src: training-memory-and-nan-localization)
- An evaluation that works on one batch but returns wrong finite values across many batches may apply a batch-local index to globally concatenated arrays. Equivalence between multi-batch and single-batch results, rather than finiteness alone, is the discriminating test. (src: training-memory-and-nan-localization)


- A memory optimization that changes when backward occurs can alter the recipe, not merely its resource use. Per-item loss weighting, batch-dependent statistics, and the model/fit identity are separate equivalence questions. (src: training-memory-and-nan-localization)

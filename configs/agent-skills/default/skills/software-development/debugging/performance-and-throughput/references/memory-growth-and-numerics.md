# Memory growth and numerical behavior

## Training memory

- Chunking reduces activation transients, but not retained graph memory if all chunk outputs remain attached until a deferred backward. Backpropagating each microbatch releases its graph sooner; weight unequal microbatches by item count for an exact per-item mean. Batch-dependent and nonlinear statistics can still change the computation.
- A CPU smoke with an accelerator-sized batch can exhaust host memory; a small smoke establishes plumbing, not full-batch feasibility.
- On unified-memory platforms where device allocations are not charged to the container cgroup, its memory limit may not bound CUDA use; a per-process CUDA memory fraction set before allocation can cap the process's allocator, subject to platform accounting.
- When retrying a CUDA OOM, leave the exception scope before retrying: the traceback can retain failed forward frames and activations, making even a smaller retry fail. Verify failed tensors can be collected.

## Process and native heap

- RSS is not Python heap. File-backed proportional memory suggests mappings or file cache; anonymous memory with a small Python heap suggests native allocations, allocator arenas, or embedded-engine buffers.
- Compare allocator live allocated and resident gauges with process RSS: rising allocated bytes suggest live-heap growth; flat allocated with higher allocator resident suggests retention. RSS also includes other mappings, including file-backed and shared pages, so the difference does not identify anonymous memory by itself. Confirm suspected causes with profiles.
- Check the active embedded-engine connection's actual memory limit, not just the intended configuration. A writable spill path and sufficient spill capacity are separate requirements.
- When comparing container metrics across a rollout, filter to current instances: stale series can make an aggregate include old and new processes.
- jemalloc `prof_gdump:true` dumps on each new high-water mark and can flood disk. When `tikv-jemalloc-sys` uses prefixed symbols, plain `MALLOC_CONF` is ignored; use `_RJEM_MALLOC_CONF=prof:true,lg_prof_sample:19,lg_prof_interval:27` with a profiling-enabled build and verify dumps appear.
- Compare profiles with `jeprof --text --inuse_space --cum --base=<early.heap> <binary> <later.heap>` to separate startup allocation from growth. Cumulative frames overlap, so use allocator gauges and RSS for process-level totals.

## Numerical failures and evaluation

- Stable locations of non-finite values suggest a structural subset; changing locations may indicate nondeterminism or instability. Inspect stored inputs, collated batches, isolated forwards, and state production to localize the first divergence.
- If a Transformer encoder returns NaNs in evaluation with a finite three-dimensional float `src_mask`, compare train and eval on identical inputs and mask: an eval fast path can behave differently.
- An evaluation can return finite but wrong values when batch-local indices address globally concatenated arrays. Compare multi-batch with single-batch results.
- A process-pool task's cleanup before returning cannot release an object still held by its result while serialization occurs. Consider cleanup at the next task boundary when diagnosing worker retention.
- A Parquet column chunk with roughly 2 GiB of binary payload can hit `ArrowCapacityError` despite high compression; bound row-group size and test a sufficiently large real table, since a normal error exit is not evidence of an OOM.

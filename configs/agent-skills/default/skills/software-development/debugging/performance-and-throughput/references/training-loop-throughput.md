# Training-loop throughput

Scope: bottleneck distinctions in training and the timing or asynchronous-execution traps that obscure them.

## Host-side binding work


- Low GPU activity and device-memory use alongside a saturated single CPU core (diagnostic pattern described 2026-09-18) indicate host-side serial work; a larger GPU will not accelerate that serial floor, and a single-thread-bound rate is hardware-dependent. GPU utilization and cgroup CPU usage over the same interval distinguish this pattern. (src: cpu-bound-training-infeasibility-triage)

- Row-wise JSON or string decoding into nested objects, per-step string lookups, repeated tensor construction, and many tiny encoder calls can turn nominal tensor/model work into interpreter and launch overhead. Call and token counts per step can expose this overhead; removable parsing/reconstruction is distinct from recipe-required arithmetic. (src: cpu-bound-training-infeasibility-triage)
- Evidence for a behavior-preserving optimization is a same-population comparison of loss and a sample of gradients with an explicit tolerance; removable representation work remains distinct from recipe-required arithmetic. (src: cpu-bound-training-infeasibility-triage)


- A step-rate projection depends on the exact work-unit count for the bounded and full populations and on the hardware that produced the measurement. A step rate from another CPU or an epoch count inferred from assumptions does not establish the target fit duration; an epoch that cannot finish within a hard lease cannot progress when checkpoints are only written at epoch boundaries. (src: gpu-fit-throughput-preflight)
- A CPU smoke that inherits an accelerator-sized batch can exhaust host memory before it answers anything useful about the model; CPU diagnostic batch sizing and accelerator feasibility are separate questions. (src: cpu-smoke-never-inherits-gpu-batch)

## Input and step capacity


- A data-wait fraction can be inflated when the compute bracket does not synchronize asynchronous CUDA work: kernels may finish during the next loader wait. Synchronized loader-only fetch/collate/transfer capacity and a synchronized full optimization step on a resident batch are distinct measurements; the larger per-batch time is the immediate throughput constraint. (src: pytorch-loader-vs-step-attribution)
- Loader wait/utilization alone does not localize cost. Per-item construction, collation, host-to-device transfer, and the resident-batch step are separate terms; a worker can parallelize across batches but not eliminate serial item/collate work within one batch. For many small graphs, packed CSR planes can replace graph-object construction and `Batch.from_data_list` with tensor gathers and edge-index rebasing, but that representation change still requires semantic equivalence. (src: gpu-dataloader-starvation-audit)


- Worker scaling has a serial floor and can collapse under oversubscription, so sublinear gains from more workers point toward structural per-batch work rather than a need for still more workers. Many small tensors can make object, IPC, and transfer overhead depend on tensor count more than payload bytes. (src: pytorch-loader-vs-step-attribution)
- Some lazily initialized graph models bind to the ordered node-type and edge-type metadata tuple; its ordering is semantically significant, so a different order can be rejected even when the tuple contains the same types. (src: gpu-dataloader-starvation-audit)

- Dense or packed representations can avoid per-object graph construction when many small graphs are the source of overhead, but a representation change is not automatically semantics-preserving. Are relation edges exactly derivable from IDs and occupancy masks? Equality separately for each graph kind is the evidence for treating persisted edges as redundant. Node indices identify entities only when identity travels with the graph; per-sample identity needs explicit IDs or features. A relation absent in one sample does not establish that its parameter is globally unused; population-wide evidence and a writer cross-check distinguish a truly absent relation. (src: graph-representation-necessity-audit)



## CUDA and container traps


- CUDA errors are asynchronous: the traceback often marks where an earlier fault surfaced, not where it began. `CUDA_LAUNCH_BLOCKING=1` serializes launches and can mask cross-stream/allocator races; a clean blocking run does not establish that an unblocked run is safe. (src: cluster-only-cuda-fault-triage)
- A side-stream copy followed only by a current-stream wait, without `record_stream()` on transferred tensors, can let the allocator recycle destination storage while a consumer kernel still reads it. A pinned-source nonblocking copy on the default stream avoids this particular cross-stream lifetime hazard. (src: cluster-only-cuda-fault-triage)
- Kubernetes’ default `/dev/shm` allocation for a pod is 64 MiB (reported in the source as of 2026-08-27); data-loader workers that pass batches through it can fail with a shared-memory exhaustion signature while the pod is reported as OOMKilled. This failure can be mistaken for insufficient ordinary container memory. (src: cluster-only-cuda-fault-triage)
- Some Kubernetes quota controllers count resource requests, while process OOM termination follows cgroup limits; quota pressure and a container’s memory ceiling are different mechanisms (source verified 2026-08-27). (src: cluster-only-cuda-fault-triage)
- CUDA qualification: separate the minimum driver under NVIDIA minor-version compatibility (CUDA 13.x needs a driver of 580 or newer) from the driver bundled with the toolkit (580.65.06 in the cited release). PTX and feature caveats mean a version quote or a major-version gate does not prove a workload initializes, so test the workload on the device path and do not tighten a gate from the bundled-driver table. Reported 2026-10-07; NVIDIA's compatibility table was not re-checked here. (src: cuda-driver-gate-qualification, 2026-10-07)

## Local GPU use and loader semantics

- When a diagnostic does run on the local workstation, use its GPU. A CPU `TensorDataset`/`DataLoader` feeding a small MLP sat at 0% GPU; GPU-resident tensors took 14 runs of over an hour each down to about two minutes. A nested sklearn `RidgeCV` took over an hour where a closed-form grouped ridge in torch float64 on the GPU took seconds. A caching allocator can reserve far more than the working set (13 GB reserved against 7 GB used), so cap it with a per-process memory fraction. Scope: bounded diagnostics only; work that belongs to a managed pipeline stage stays there. (src: local-gpu-diagnostics, 2026-09-23)
- Never filter an `IterableDataset` independently in each `DataLoader` worker and trust `ceil(global_allowed / batch_size)` as its length: with 4 workers, batch size 2, and prefetch 4, 22 allowed items gave 12 local batches while Lightning consumed 11, silently dropping an item every epoch. Filter after the ordered merge, pack globally, and collate in the main process; the main-process collation cost was not measured. (src: iterable-dataset-filtering, 2026-10)
- Throughput and budget estimates: never divide fit wall time by a selected checkpoint's `global_step` without proving it is terminal (a checkpoint selected from an earlier epoch makes the fit look longer than it ran). Keep configured, completed, selected, and progress counts separate, and remember that GPU occupancy excludes waits before admission. (src: step-count-budgeting, 2026-10)

# Capacity ledgers and Prometheus evidence

Scope: a node or cluster where jobs stay Pending or suspended while the host looks idle, or where requests must be sized from observed usage. Compare the three ledgers before changing any quota, then read peaks, growth and live-pod usage carefully.

## The three ledgers

1. **Host actual.** Node-exporter: memory used `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes`; CPU busy `sum(rate(node_cpu_seconds_total{mode!~"idle|iowait"}[5m]))`, both selected by the node label.
2. **Scheduler requests.** Node allocatable minus the requests of pods bound to the node (`kubectl get pods -A --field-selector spec.nodeName=<node>`). A pod's effective request is `max(sum of containers, largest init container)` (restartable init containers add to the sum). Check whether allocatable equals capacity (no system or kube reservation configured). Unbound Pending pods reserve nothing on the node.
3. **Quota ledger.** The ClusterQueue flavor's nominal quota, borrowing limit and `.status.flavorsUsage`. It only accounts namespaces the queue manages; workloads in unmanaged namespaces (controllers, stateful services, workflow-engine run pods launched with their own defaults) are invisible to it.

A suspended workload on an idle host usually means the quota controller admitted something the scheduler could not place (`PodsReadyTimeout` evictions plus `FailedScheduling ... Insufficient memory|cpu`). Raising quota then only admits more pods that cannot bind. Real quota waits show up as `insufficient unused quota for <resource> in flavor <f>` in the queue controller's JSON logs (attribute them with `jq -r '.object.namespace'`). See the Kueue troubleshooting skill for the diagnosis procedure.

## PromQL joins that work

- cAdvisor `container_*` series carry no node label. Join on pod info: `<expr> * on(namespace,pod) group_left() max by (namespace,pod)(kube_pod_info{node="<node>"})`.
- Requests of active pods only: `kube_pod_container_resource_requests{node="<node>",resource="memory"} * on(namespace,pod) group_left() (max by (namespace,pod)(kube_pod_status_phase{phase=~"Running|Pending"})==1)`.
- Pod peak: `max_over_time((sum by (namespace,pod)(container_memory_working_set_bytes{container!="",container!="POD"}))[24h:2m])`. Summing per-container maxima overstates it.
- Concurrent class peak: take `max_over_time` of the per-timestep `sum(...)`. Never sum per-pod maxima.
- Per-container peaks come from live pods only (`pod=~"<current pod names>"`): cAdvisor series of replaced pods linger for minutes after a rollout and mix old and new pods in an unfiltered `sum by (container)`.
- Workflow-engine runs that carry no per-run resource tag inherit the launcher default; join runs to pods through the run-id pod label to attribute their usage.

## Evidence hygiene

- **Check the oldest retained sample** (`prometheus_tsdb_lowest_timestamp_seconds`, or the first sample of the series) before trusting any peak. Configured retention is not available history, and the retained window changes when Prometheus moves or is resized; re-measure rather than quoting an old figure.
- **Measure growth within one pod incarnation** (point samples or `deriv(...[12h])`) before any restart, because reboots and rollouts reset leaky processes. A rise over the first hours of a fresh build may be start-up catch-up rather than a leak; do not call it either without a longer window.
- **An allocator, runtime or binary change resets the evidence.** Re-measure for at least 24 hours on the new build, including the peak load window, before resizing; peaks and slopes from the previous allocator size nothing, and OOM records written before the change are not evidence about the new one (rewrite the manifest comment with the new evidence in the same change).
- **Requests and limits are different decisions.** A lower request does not reclaim physical memory or cap growth and can worsen OOM and eviction ranking under node pressure; state which of the two a change touches.
- State the formula and window you used for a request (for example a multiple of the retained working-set peak plus measured growth, rounded up) with the figures, so the next pass can redo it.

## Reading the cost of a change

- Singleton Deployments with `Recreate` leave a capture gap on restart; `RollingUpdate` surge pods need room for both copies. Resizing a singleton that is the only client of an upstream API restarts that client: ride a planned release instead of a standalone tweak.
- Pods at a high priority with `PreemptLowerPriority` evict lower-priority pods on a full node; see [staged-rollout-and-headroom-gate.md](staged-rollout-and-headroom-gate.md).
- When a PR cuts requests, update every render test that pins the expected request tuples, and read the comments next to each `resources:` block before cutting.

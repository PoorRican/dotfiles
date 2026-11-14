# Capacity ledgers and Prometheus evidence

## Compare the ledgers

- Compare host actual CPU and memory, scheduler allocatable minus effective requests of bound non-terminal pods, and queue flavor quota and reservations. Queue-managed workloads need not account for unmanaged pods; low actual usage is not scheduler headroom.
- Calculate effective pod requests according to the cluster's Kubernetes version, including init containers, restartable init sidecars, pod overhead and any enabled pod-level resources. Include system reservation and all relevant resources. Consult the Kueue troubleshooting skill for admission and placement diagnosis.
- Check queue status and controller logs against scheduler events: `PodsReadyTimeout` evictions together with `FailedScheduling` for insufficient resources indicate placement trouble, where increasing quota alone admits more pods that cannot bind. An `insufficient unused quota` message instead points to a quota wait.
- Missing pod metrics are missing evidence, not zero. Show coverage and shortfalls per resource. Partial history may inform a decision with stated uncertainty but does not by itself prove over-reservation.

## Measure usage

- Check the oldest available samples for each series, not just configured retention. Calculate a simultaneous pod peak as the maximum over time of the per-timestep container sum; calculate a class peak from the per-timestep pod sum. Summing independent maxima overstates concurrent usage.
- For example: `max_over_time((sum by (namespace,pod) (container_memory_working_set_bytes{container!="",container!="POD"}))[24h:2m])`. Choose a populated window and resolution suited to the workload. Include pod identity when aggregating across generations.
- Inspect actual scrape labels. If container series lack a node label, join to `kube_pod_info` by namespace and pod, taking care with duplicate or stale identities. Restrict current-pod comparisons to live pod identities because replaced pods' series can linger.
- Node join example: `<expr> * on(namespace,pod) group_left() max by (namespace,pod)(kube_pod_info{node="<node>"})`. For active-pod requests, filter `kube_pod_container_resource_requests` using a `Running|Pending` phase join; separately account for effective init, overhead and pod-level requests.
- Measure memory growth within each pod incarnation; startup catch-up and restarts can mimic or conceal a trend. Runtime, allocator or binary changes can invalidate previous peaks; collect a representative window on the new build, including relevant peak cycles.
- Requests and limits are different decisions: lowering a request does not reclaim physical memory or cap growth, and can change eviction behavior. Explain the sizing formula, evidence window and uncertainty.
- For attribution, compare bounded measurements at appropriate resolution before, during and after actual process intervals. Interface totals alone do not identify a process; a maximum of rolling p99s is not a pooled p99.
- Separate receive from transmit and process incarnations; retain bounded query responses and the query windows. Configured storage endpoints do not establish historical bytes transferred.

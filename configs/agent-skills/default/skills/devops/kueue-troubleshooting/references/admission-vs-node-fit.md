# Admitted but unschedulable: quota ledger versus node fit

Scope: a Job in a Kueue-managed namespace is admitted, but its pod stays `Pending`/`Unschedulable`, is evicted after the PodsReady timeout and requeues, while the node looks lightly used or someone asks whether requests are inflated. Verify the live Kueue configuration (`waitForPodsReady.timeout`, `recoveryTimeout`, requeue backoff) and the ClusterQueue flavors before relying on any number below; timeouts and quotas differ per cluster and change.

## Mental model

- Two independent gates, and neither looks at actual usage:
  - **Kueue admission** checks a quota ledger covering Kueue-managed workloads only (namespaces the queue manages).
  - **kube-scheduler placement** checks node allocatable minus the requests of all resident pods, managed or not, and the node's taints against the pod's tolerations.
- An admitted workload can therefore be unbindable, and raising Kueue quota then only admits more pods that cannot bind.
- On PodsReady timeout the Workload shows `Evicted=True/PodsReadyTimeout`, `QuotaReserved=False`, `Admitted=False/NoReservation` (quota returned, not a shortage), the Job is `suspend=true` and the pod is deleted. The timeout clock starts at admission, not at Job creation.
- Requeue backoff was observed as `min(60 * 2^(count-1), 3600)` seconds after each eviction, with unlimited retries and a fresh count for each new step Job; the master configuration stated a 60 s base and 3600 s cap. Re-admission also waits for free quota, so on a one-slot flavor the gap can be longer.
- A flavor injects only its own tolerations, never kubelet node-condition taints (`disk-pressure`, `memory-pressure`).

## Procedure

1. **Exact objects.** Find the step Job, then the Workload whose ownerReference is that Job; never guess the Workload suffix. Read the Workload's `status.conditions`, `requeueState` and `schedulingStats.evictions`, and the pod's `FailedScheduling` events (pods are deleted at eviction but events remain: `kubectl -n <jobs-namespace> get events --sort-by=.lastTimestamp | grep <job-prefix>`).
2. **Classify `FailedScheduling` first.**
   - `Insufficient cpu/memory` on the only selector-eligible node plus `Preemption is not helpful`: request-fit failure; continue below.
   - `1 node(s) had untolerated taint(s)` while other nodes fail the selector: a taint blocks the only eligible node, so requests and quota are irrelevant. Read `kubectl get node <node> -o json | jq '.spec.taints, .status.conditions'` and see the taint section below.
3. **Take one coherent snapshot** from a single script whose reads happen within seconds:
   - node `status.allocatable`;
   - every non-terminal pod on the node with its effective request `max(sum of containers + restartable inits, max over regular inits of (running restartable inits + that init)) + overhead`, with pod-level `spec.resources` overriding the sum;
   - the Metrics API for pods and the node, reporting matched/total coverage (never count a missing metric as zero);
   - LocalQueue to ClusterQueue `spec.resourceGroups` quotas, `status.flavorsReservation` and the admitted holders.
4. **Report the arithmetic per resource**: allocatable, total requests, declared headroom, actual usage, the step's request and shortfall, and quota reservation plus the step's request against nominal quota. Classify holders by owner kind: Job (batch), ephemeral runner (CI, transient), ReplicaSet/StatefulSet/DaemonSet (persistent). "Not a Job" does not mean persistent.
5. **Predict placement.** For each candidate release and each pair, compute per-resource headroom plus released requests and compare with the step's request. Name the binding resource. Say "when X or Y finishes" only if each alone covers every resource, and note that new arrivals can take freed space first.
6. **Request-inflation audit, only if asked.** Per pod, sum `container_memory_working_set_bytes{container!="",container!="POD"}` at each evaluation and then take max and p99 (the simultaneous pod total, not the sum of per-container maxima); CPU from `rate(container_cpu_usage_seconds_total[5m])`. Use the range that is actually populated rather than the configured retention, and treat partial history as evidence of over-reservation, not grounds for setting requests.
7. **Report options; do not act.** Wait (give the backoff timing); lower the step's request while keeping limits; right-size persistent reservations (an owner or infrastructure decision); for a node-condition taint, free the resource behind it. Change no quota, priority or foreign workload without explicit approval.

## Traps

- **Node-condition taints.** kubelet adds `node.kubernetes.io/disk-pressure:NoSchedule` when nodefs or imagefs free space falls below `evictionHard`, and with `evictionMinimumReclaim` keeps the condition until well above it. Image garbage collection cannot reclaim storage that is not the kubelet's (for example local container build caches on a shared workstation node), so the taint does not clear by itself and every step that targets the node loops through evictions. Diagnose with the node's `stats/summary` and `configz` proxy endpoints and the container engine's disk usage. Pruning other sessions' cached layers needs the owner's approval; report numbers and ask.
- **One-slot ping-pong.** On a flavor with one GPU, two blocked workloads alternate: each is admitted, holds the slot through its PodsReady timeout, is evicted, and the other is admitted. `insufficient unused quota ... gpu 1 more needed` on the waiting one is a symptom of the other holding the slot, not the cause.
- **Cached steps on re-attempt.** After a failed pipeline run is re-attempted, its completed steps are cache hits (step status `cached`, `original_step_run_id` set, a "using cached version" log line), so a Completed pod proves nothing about fresh execution. Record the original step run, cache key and reused artifact in any acceptance receipt.
- **Watchers.** Report only pod start, terminal failure, or a backoff of 30 minutes or more, and distinguish Job creation time from Kueue admission time.

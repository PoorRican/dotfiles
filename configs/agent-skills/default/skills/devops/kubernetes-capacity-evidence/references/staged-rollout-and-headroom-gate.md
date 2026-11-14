# Staged rollout and headroom

A concurrent rollout can create multiple surge pods. On a full node, high-priority surge pods can preempt lower-priority workloads; a `Recreate` singleton instead has a service gap. Consider staging when that risk matters.

## Before each stage

- Compare the intended render with live objects, including coupled configuration, to expose unrelated changes that a broad apply would carry. A changed content-hashed ConfigMap can restart every workload referencing it; a fixed-name configuration may instead require an explicit reload.
- Check healthy old replicas, startup dependencies and the readiness of the new template. A rollout requiring zero unavailable replicas cannot complete if the replacement never becomes Ready.
- Estimate each eligible node's unreserved resources from allocatable less effective requests of bound non-terminal pods, then compare with the replacement pod's effective requests, including init containers and overhead. Check placement constraints and other resources as well as CPU and memory. Account for concurrent arrivals; headroom is not a reservation.
- Stage related changes according to their actual dependency and disruption requirements. A singleton `Recreate` frees resources before its replacement but interrupts service; a rolling surge needs space for both copies. Wait for each stage to stabilize and inspect restarts, readiness and actual image identities.
- Apply only the intended rendered objects, skipping those with an empty server-side diff. Check lists and deployment strategies before applying, and dry-run helpers first. If a startup dependency is resolved only at boot, check it before removing a healthy `Recreate` pod.

## Verify and recover

- Compare live resource quantities numerically: `1000m` CPU equals `1`, whereas `500Mi` does not equal `0.5Gi`. Verify application progress separately from pod readiness; a flat low-cadence series in a short window does not prove data loss.
- Counters created only on their first event may yield zero `increase()` after a rollout because no earlier sample exists; inspect first-sample timestamps before interpreting zero as inactivity. Break warm-up alerts down by pod before acting.
- Attribute preemption events to the actual preemptor and affected pods. Events expire, so absence of an old event is not proof of no preemption. Distinguish merged, applied and runtime-verified state.
- Investigate a slow handoff before intervening: startup dependencies and large state can delay readiness. Changing rollout strategy or deleting a pod is disruptive and requires authorization; restore intended configuration after any temporary intervention.
- If an authorized recovery changes `maxUnavailable` or removes an old ReplicaSet, first establish that the replacement is actually progressing, wait for handoff, then reapply the intended Deployment render and check for drift. A readiness delay alone is not proof of a stuck handoff.
- With `OrderedReady` StatefulSets, a not-Ready pod can prevent the updated template from rolling out; investigate the unhealthy pod before an authorized manual deletion to let the controller recreate it.
- For guarded JSON patches, use `test` operations for expected old values, snapshot the object and server-side dry-run before applying. A drifted object must fail rather than be overwritten.

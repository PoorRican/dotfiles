# Staged rollout with a headroom gate

Scope: applying a manifest change (resources, config, image) that restarts several Deployments on a node where new pods can preempt others. A single whole-overlay `kubectl apply -k` starts every surge at once, so roll in stages. Staged stays the default even when earlier whole-overlay applies preempted nothing because the node happened to have large request headroom.

## Why staging matters

- High-priority pods with `PreemptLowerPriority` evict lower-priority pods when a surge pod cannot fit on a full node. Once batch pods at the lowest priorities are gone, the next victims are priority-0 services (the metrics store, experiment tracking, orchestration servers and their databases, CI runner pods that share priority 0 with `preemptionPolicy: Never`).
- `Recreate` Deployments leave a capture or serving gap but free memory first; `RollingUpdate` Deployments with `maxSurge: 1, maxUnavailable: 0, minReadySeconds: N` need room for two copies and finish one handoff in roughly `minReadySeconds` plus readiness time.

## Preflight

1. Apply only from a clean detached worktree at the remote default branch that contains the merge. Run `kubectl diff -k` on the target overlay and every coupled overlay (below) before merging, to catch unapplied drift from other PRs that would ride along.
2. Every target Deployment must have `availableReplicas == replicas` with all containers Ready.
   - A permanently not-Ready container in the old pod does not block the handoff if the new pod can go Ready.
   - A not-Ready container in the new template makes a `maxSurge: 1 / maxUnavailable: 0` rollout unfinishable.
3. Content-hashed ConfigMaps restart every Deployment that mounts them, so bundle config edits with an image release when you can.
4. Verify startup dependencies a `Recreate` will exercise before removing the healthy pod: a service that resolves discovery entries against an upstream API at startup can crash-loop on a transient 404 after the healthy pod is gone (one such restart took about eleven minutes to recover). Resolve every rendered entry from the node first and stop unless all succeed.

## Order

1. New hashed ConfigMap first, applied alone; it is a new name, so it is harmless.
2. `Recreate` Deployments next, one at a time (capture gaps of seconds to a few tens of seconds), because they free memory before any surge.
3. `RollingUpdate` Deployments one stage at a time, each gated on room.
4. Leave singleton orchestrators (the only client of an upstream API) alone for resource-only tweaks; ride the next release.

## Headroom gate

Before each `RollingUpdate`, require the node's unreserved CPU and memory (allocatable minus the requests of Running and Pending pods on the node) to be at least the new pod's summed requests. Read the new pod's requests from the render, not from remembered numbers (they change when requests and limits are split or re-sized). If there is no room, wait and poll with a time budget rather than proceeding.

## Apply

- Extract only the target objects from the master render (`kubectl kustomize ... > render.yaml`) and skip any whose server-side `kubectl diff -f -` is empty.
- Dry-run any helper script first; it catches render and name mistakes. List and strategy assertions should run before anything is applied so a wrong list fails closed.
- After each rollout, require Ready, zero restarts, no `OOMKilled` in `lastState` and unchanged image digests. A broad selector can stop on an unrelated sibling pod that restarted earlier; read the printed pods.

## Coupled overlays

- A capture-reference or fingerprint object that hashes the collector config or manifest bytes rolls through an annotation. If merged PRs regenerated it independently, resolve conflicts by re-running the render script on the merged tree; never hand-merge hashes.
- Fixed-name config objects (a metrics scrape config) do not restart the pod; run the explicit reload step after applying and verify through the status API (the last-reload timestamp lags one self-scrape, so recheck after about 20 s). Rule files that are content-hashed roll the Deployment instead.
- Dashboard ConfigMaps update in place; verify the mounted file.

## Verify each stage

- **Resources**: compare live against render with quantity normalization (`500Mi` and `0.5Gi`, `1000m` and `1` are equal); a string compare gives false mismatches.
- **Data plane**: sample a per-lane open-bytes (or equivalent progress) series twice, 90 to 120 seconds apart, and require growth per container; count a lane whose bytes dropped as sealed (activity). Report grow/total lane counts per container. Subscribe-only lanes, low-cadence snapshot lanes and weekend-quiet markets may stay flat; non-growth in a short window is not proof of loss.
- **Counters created at first event**: `increase()` over the hour reads 0 on freshly rolled pods because the series did not exist before the first seal. Read first-sample timestamps from a short range vector a few minutes after the hour instead.
- **Warm-up alerts**: latency rules can fire on a warming surge pod while the old pod still captures. Break `ALERTS` down by pod before acting.
- **Preemptions**: attribute `reason=Preempted` events by matching the preemptor UID in the event message against your pods' UIDs; events expire after about an hour, so for older rollouts compare long-running priority-0 pod start times with the rollout window.
- **Final state**: `kubectl diff -k` exits 0 for the target overlay and every coupled overlay you touched.

## Stuck handoff (new pod capturing, old never removed)

1. Prove the new pod's lanes are growing (two samples as above).
2. Patch `maxUnavailable: 1` (`kubectl patch deploy <name> --type=merge -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":1}}}}'`) and wait for the old pod to be deleted, or scale the old ReplicaSet to 0.
3. Re-apply the master render of that Deployment. The strategy is not part of the pod template, so this starts no new rollout.
4. Confirm `kubectl diff` exits 0.

Slow readiness is not a stall: a pod that waits on another component's readiness, or a workload loading a large state, can take many minutes (tens of minutes on a cold start). Wait before intervening.

## StatefulSets and guarded JSON patches

- A StatefulSet with `podManagementPolicy: OrderedReady` does not roll a pod that is not Ready, so a template change never reaches it; `kubectl delete pod <name>` is the roll, and the controller recreates it from the updated template.
- Apply JSON patches (`--type=json`) with leading `test` ops that assert the values you expect to replace, so a drifted object fails the patch instead of being overwritten. Snapshot the objects first (`kubectl get <kind> <name> -o yaml`), and run the same patch with `--dry-run=server` before applying it. (src: statefulset-rollout-and-json-patch, 2026-11-10; not re-run)

## Report

Separate merged, applied and runtime-verified. Name which Deployments had `Recreate` gaps and how long. Do not claim historical capture loss from readiness or missing metric series alone; that needs landing files or row-level evidence.

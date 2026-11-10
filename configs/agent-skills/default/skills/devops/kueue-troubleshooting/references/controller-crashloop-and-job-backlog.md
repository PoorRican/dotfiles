# Kueue webhook down: controller crash loop from a finished-Job backlog

Scope: Job submission fails because the Kueue mutating webhook has no endpoint, the controller manager is in CrashLoopBackOff, and a large backlog of finished Jobs is the likely trigger. Includes cleanup of your own stopped pipeline run and an adjacent "GPU step Pending while the GPU is idle" trap.

## Signature

- Submissions fail with `failed calling webhook "mjob.kb.io": ... no endpoints available for service "kueue-webhook-service"`. This blocks every Job on the cluster, not only yours.
- `kubectl -n kueue-system get pods` shows `kueue-controller-manager-*` in CrashLoopBackOff with many restarts, and `kubectl -n kueue-system get endpoints kueue-webhook-service` lists no endpoint.

## Diagnose (read-only)

1. **Check the exit reason first**: `kubectl -n kueue-system get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'`. Two variants share one root cause, a large finished-Job backlog re-reconciled at startup:
   - `OOMKilled` (exit 137) a few seconds after start. Upstream manifests ship a modest default manager memory limit (512Mi); a backlog of well over a thousand finished Jobs has been observed to exceed it, with logs showing only `Reconciling Job` lines before death. Steady-state usage after recovery is far lower.
   - **Leader election lost**: `kubectl -n kueue-system logs <pod> --previous --tail=60` shows lease-lock rate-limiter errors (`client rate limiter Wait returned an error`), failed lease renewals and then `leader election lost`, roughly every five minutes. This points to client-side throttling during the startup re-reconcile of finished Workloads.
2. **Size the backlog per namespace** that submits Jobs:
   ```sh
   for ns in <jobs-ns-1> <jobs-ns-2>; do echo "$ns $(kubectl -n $ns get jobs --no-headers | wc -l)"; done
   kubectl -n <jobs-ns> get jobs --no-headers | awk '{print $2}' | sort | uniq -c   # completion column
   ```
   Count events by reason as well (finished-Workload events grow with the backlog).
3. **Why it accumulates**: check the `ttlSecondsAfterFinished` the submitter renders. A TTL of days against a campaign that launches hundreds of Jobs per day leaves a standing backlog; the durable fix is a shorter TTL or periodic cleanup in the submitter, not repeated manual deletion.

## Recover (explicit owner approval required: the Jobs belong to another session or campaign)

Offer options: (a) delete only the Complete Jobs in the backlog namespace, keeping Failed ones for debugging; (b) raise the controller's client QPS/burst or memory limit through its manifest; (c) both; (d) wait for the owner. If the manifest already sets higher QPS, the remaining lever is the memory limit; check both before choosing.

For (a), re-list immediately before deleting because another actor may be clearing concurrently:

```sh
OUT="${SCRATCH_DIR:-.state}/kueue-unblock-$(date -u +%Y%m%d)"; mkdir -p -m 0700 "$OUT"; TS=$(date -u +%Y%m%dT%H%M%SZ)
kubectl -n <jobs-ns> get jobs -o json > "$OUT/jobs-all-$TS.json"   # snapshot first
# write the names with condition Complete=True and no status.active to complete-names-$TS.txt
xargs -a "$OUT/complete-names-$TS.txt" -n 100 \
  kubectl -n <jobs-ns> delete job --cascade=background --wait=false --ignore-not-found
```

- Treat `NotFound` as a concurrent deleter, not an error.
- Verify: the controller stays `1/1 Running` for several minutes, a fresh `LeaderElection` event appears, the webhook EndpointSlice has an address, and a server-side dry-run create of a Job in the managed namespace is admitted. Then resubmit.
- Log owner approval, counts, snapshot location and the still-open TTL or limit fix in the project's record.
- For (b), a manifest change to Kueue follows the cluster's admission-safety procedure; render and diff the overlay and expect only the intended lines before applying.

## Cleaning up your own stopped run

Stopping a pipeline run (for example `zenml pipeline runs stop <run>`) marks the run stopped but leaves its orchestrator and step Kubernetes Jobs, and a pending Workload, in the queue. Delete only your run's Jobs by the run-id prefix (`kubectl -n <jobs-ns> get jobs | grep <prefix>`). A submission that failed on the webhook created no Job: resubmit under a new campaign or intent name rather than reusing the failed intent file.

## Adjacent trap: GPU step Pending while the GPU is idle

Read the Workload condition before assuming GPU contention:

```sh
kubectl -n <jobs-ns> get workload <wl> -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
kubectl get clusterqueue <cq> -o json   # spec flavor quotas and status.flavorsUsage
```

`insufficient unused quota for ephemeral-storage in flavor <f>` means a non-GPU resource is exhausted, often held by an unrelated CPU-only tenant. Size `ephemeral_storage` to about 1.5 times measured peak (get artifact sizes from the pipeline stack's artifact store) rather than copying a value from another training configuration, and check the target node's actual free disk too.

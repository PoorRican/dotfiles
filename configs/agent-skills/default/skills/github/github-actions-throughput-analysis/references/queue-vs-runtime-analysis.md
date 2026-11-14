# Queue versus runtime

## Collect runs and jobs

- Enumerate repositories with an explicit sufficient limit or paginated API; the CLI's default repository limit may omit active repositories. Page through both workflow runs and each run's jobs, including attempts. Preserve run attempt, event, SHA, job labels, runner name and timestamps. `gh api --paginate` requests all pages; process each returned object.
- For completed jobs, compare `started_at - created_at` with `completed_at - started_at`. Check the API's timestamps and attempt identity before interpreting negative waits or dependent-job waits; re-runs can distort them. Do not silently discard anomalies.
- For Kubernetes runner pods, join runner name to pod identity only after verifying the naming relationship. Use pod creation, scheduling and container-start timestamps to distinguish listener delay, admission/scheduling, boot and registration. Missing or unmatched pods make the split incomplete.
- Collect `kube_pod_created`, `kube_pod_status_scheduled_time`, `kube_pod_container_state_started{container="runner"}` and `kube_pod_info` over the analysis window. Split the joined timestamps into job-to-pod-create, creation-to-scheduling, scheduling-to-container-start and container-start-to-job-start.
- For runner sizing, take the maximum over time of the per-pod sum of container CPU rates and memory working sets; do not sum independently observed container maxima.

## Diagnose and compare capacity

- Compare waits with concurrent runner pods and actual pool caps. Saturation suggests slot scarcity; a long wait without runners suggests investigating listener or broker behavior, but neither observation alone proves cause. Listener logs can reveal stalls absent from pod metrics.
- Group autoscaling listener metrics by the scale-set label rather than a listener name with a changing suffix. Listener logs reporting no assigned jobs while jobs remain queued warrant broker investigation, not an immediate capacity increase.
- Replay observed arrivals and job durations across candidate slot counts using a heap of next-free times. Include measured startup overhead and actual pool and quota caps; this simplified replay assumes future arrivals and durations remain comparable and omits competing bottlenecks.
- Compare the same job across nodes and concurrency levels. Check CPU throttling and node I/O pressure before attributing a runtime difference to code.
- Keep merged configuration, applied configuration and runtime observations distinct.

# Job timing, duplicate work and failures

- Compare step durations across runs; use timestamped logs for finer detail. For build jobs, BuildKit completion lines expose layer and cache-export durations. For tests, progress and worker counts can distinguish a straggler from uniformly low throughput.
- If direct job-log retrieval is empty, use `gh run view <run> -R <owner>/<repo> --log --job <job-id>`; timestamps may have a leading byte-order mark.
- Group runs by repository, workflow and commit, then inspect groups triggered by both push and pull-request events. Confirm whether their actual work overlaps before summing avoidable runner time. Inspect workflow files from the current remote default branch, not a potentially stale checkout.
- Before calling a failure a flake, group by job, step, runner and node; inspect runner evictions, container terminations and node pressure. Use failure logs to distinguish infrastructure from test or code failures.
- Use `gh run view --log-failed` to classify failures. Check `kube_pod_status_reason` and runner-container termination state for evictions; group by node as well as job and step.
- For image build failures inspect actual builder limits and storage; distinguish DNS and trust failures at runner, builder and image-process layers. Do not disable TLS verification or expose certificate material to make a probe pass.

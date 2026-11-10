# Queue versus runtime: slots, scheduling and registration

Scope: use when CI feels slow or before resizing runner capacity (autoscaled self-hosted runner pods, a quota queue in front of them). Measure first; capacity, listener or GitHub-side stalls, and node speed each leave a different signature.

## 1. Collect runs and jobs

1. List the active repositories (`gh repo list <org> --json name,pushedAt`). For each, page through `gh api repos/<org>/<repo>/actions/runs?per_page=100&page=N`, merge the pages, sort by `created_at` and take the most recent N runs.
2. For each run fetch its jobs (`gh api repos/<org>/<repo>/actions/runs/<id>/jobs?filter=all&per_page=100`), in a thread pool. Keep labels, `runner_name`, created, started and completed times and steps.
3. A job is self-hosted when its labels include your runner label. Queue time is `started_at - created_at` and duration is `completed_at - started_at`. A dependent job's `created_at` is when its dependencies finish, so `started - created` is true runner wait. Drop negative queue times, which are re-run artifacts.

## 2. Join runner pod lifecycle

From Prometheus (runner namespace), take for the window:

- `max_over_time(kube_pod_created[7d])`, `max_over_time(kube_pod_status_scheduled_time[7d])` and `max_over_time(kube_pod_container_state_started{container="runner"}[7d])`, plus `kube_pod_info` for the node.
- Join on `runner_name == pod`. From the join, split each job's wait into:
  - job to pod-create (the listener),
  - created to scheduled (the quota or admission gate),
  - scheduled to container start (boot),
  - container start to job start (registration).
- Per-pod peak CPU and memory over the same window for right-sizing: `max_over_time(sum by(pod)(rate(container_cpu_usage_seconds_total{namespace="<runner-ns>",container!=""}[2m]))[7d:1m])` and the equivalent `container_memory_working_set_bytes`.

## 3. Pool saturation and stalls

- Build a concurrency histogram from pod created/gone times and bucket jobs by how many runner pods were running when the job was created. A long queue at the maximum pod count is slot scarcity; a long queue with zero pods running is a listener or GitHub-side stall.
- Distinguish the two with the autoscaling listener's logs (query the controller namespace in Loki): a listener reporting zero assigned jobs while jobs are queued points at the GitHub broker, and it cannot be seen in the scale-set metrics.
- Group listener metrics by the `scale_set` label, not the `name` label: names carry a random runner-set suffix.

## 4. Slot replay

Replay the real arrival stream through a heap of free times at several slot counts (for example 4, 6, 8 and 12), using each job's created time and duration plus a per-pod overhead of roughly a dozen seconds, to see how queue time would change before buying capacity. Check the live caps (the scale-set maximum runners and the quota queue) rather than assuming them.

## 5. Same job, different node

Compare the median duration of the same job across nodes; node speed and saturation can differ by a large factor, and at full concurrency a node can slow every job on it. Check node IO pressure (`node_pressure_io_waiting_seconds_total`) as well as CPU throttling before blaming the code under test.

## 6. Reporting

- Report merged, applied and runtime state separately; analysis authorizes no change.
- Treat a dated finding ("the bottleneck was runner slots, not the controller") as an observation to re-measure, not a standing conclusion.
- For capacity changes, apply only the objects you analyzed (the CI queue and CI flavors), not a whole overlay whose live state may carry unrelated drift, and link the runner documentation for the layout instead of copying it into the report.

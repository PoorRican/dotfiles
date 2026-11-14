# Controller, webhook and Job backlog

A missing webhook endpoint can block Job submissions covered by its webhook configuration. Check controller pod state and webhook EndpointSlices; do not assume every Job in the cluster is affected.

- Inspect the previous controller termination reason, logs, resource limits, leader-election errors and API rate-limit messages. OOM kills and lost leadership have several causes; a finished-Job or Workload backlog is a hypothesis, not a diagnosis. Correlate startup reconciliation, object counts and resource or API pressure before attributing cause.
  Check the previous container termination with `kubectl -n <namespace> get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'` and its logs with `kubectl -n <namespace> logs <pod> --previous`. Bound log inspection to the relevant controller incarnation and interval; a truncated response cannot establish that later events are absent.
- Count finished and active Jobs and Workloads in relevant namespaces, and inspect the submitter's `ttlSecondsAfterFinished` or cleanup policy. Long retention combined with sustained submissions can create a recurring backlog.
- Match remediation to evidence: controller memory or client rate limits may need adjustment, or completed Jobs may need cleanup. Snapshot and re-list candidates; preserve failed Jobs needed for diagnosis. Deleting another owner's objects or changing controller configuration requires approval. Do not use a partial name-selection script as a deletion command.
- After an authorized recovery, verify controller stability, an address in the webhook EndpointSlice and successful server-side dry-run admission of a representative Job. Distinguish this from merely restoring the pod.
- Stopping a pipeline may leave its Kubernetes Jobs and queued Workloads behind; verify actual ownership before any cleanup. A failed webhook submission may have created no Job at all.

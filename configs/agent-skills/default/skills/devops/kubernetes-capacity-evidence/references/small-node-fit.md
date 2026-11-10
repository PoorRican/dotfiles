# Could this workload move to a small node?

Scope: whether an always-on workload (trading or ingestion service, collector, a stateful sidecar pair) could run on a small ARM or low-RAM board or mini PC, or how to right-size a pod from measured history instead of manifest requests. Answer from history, and check the three non-RAM blockers (write volume, image platform, network reachability) before quoting a RAM number.

## 1. Establish what is actually deployed

Architecture notes and topology docs drift: a doc described workloads and databases that were no longer running while the live cluster had a different set owned by a CronJob. Before reading topology docs run, for the namespaces in question:

```sh
kubectl get pods -A -o wide | grep -Ei '<workload-name-patterns>'
kubectl -n <ns> get deploy,sts,cronjob
kubectl -n <ns> get pod <pod> -o jsonpath='{range .status.containerStatuses[*]}{.name}{"\t"}{.imageID}{"\n"}{end}'
```

Then read the manifests for limits, hostPaths and the ClusterIPs the pod must reach, including workloads added since the doc was last edited.

## 2. Memory from Prometheus history

Use a script (not a hand-typed dashboard) and aggregate with `max by (container)`; filter container names explicitly. An unfiltered `container!=""` in a namespace with CronJobs returns thousands of series.

- Now: `max by (container) (container_memory_working_set_bytes{...})`.
- Peak across generations: `max by (container) (max_over_time(container_memory_working_set_bytes{...}[30d]))`; typical: `quantile_over_time(0.5, ...[30d])`.
- RSS: `container_memory_rss`. RSS about equal to working set means anonymous heap, not page cache.
- Pod-simultaneous total, which is what the node must hold: `max_over_time((sum by (pod) (container_memory_working_set_bytes{...}))[30d:1m])`.
- Uptime trend: `query_range` at a 5-minute step over the window, bucketed per day with p50 and max. Growth with uptime means a quiet sample understates the requirement.

## 3. CPU, writes, network

- Mean millicores `avg by (container) (rate(container_cpu_usage_seconds_total{...}[5d]))*1000`, p99 via `quantile_over_time(0.99, (rate(...[5m]))[30d:1m])`. Five-minute rates hide sub-second bursts for latency-sensitive takers; say so.
- Writes per day: `sum by (container) (rate(container_fs_writes_bytes_total{...}[5d]))*86400`. Cross-check the node side with `node_disk_written_bytes_total` by device, then log in and `du` plus `find -mmin -5` the hostPath to name the writer. Anything above about 5 GiB per day rules out microSD or eMMC storage.
- Network receive per day: `rate(container_network_receive_bytes_total{...}[5d])*86400`.
- Check reachability to the ClusterIPs the pod depends on from the target node (overlay networking between sites is a blocker, not a detail).

## 4. Fixed node overhead

Measure the agent, node-exporter and CNI overhead on the target node class rather than assuming it: the kube agent's resident memory is small on a quiet node and bursts to a multiple of that during image pulls (`max_over_time(...[7d])`). A "minimal" agent saves little when the pod needs ClusterIPs on other nodes, because kube-proxy and the CNI daemon are load-bearing.

## 5. Image platform

Images are single-platform amd64 unless proven otherwise. Read the manifest through the registry with a pull credential and then the config blob's `architecture`:

```sh
AUTH=$(kubectl -n <ns> get secret <pull-secret> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths["<registry>"].auth')
curl -sk -H "Authorization: Basic $AUTH" \
  -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json' \
  "https://<registry>/v2/<name>/manifests/<tag-or-digest>"
# then fetch /v2/<name>/blobs/<config digest> and read .architecture
```

Check the Dockerfile for optional heavy components that the live pod does not execute (for example a CPU ML runtime baked in for a sidecar that is disabled at run time); dropping them changes the RAM and image-size answer.

## 6. Report shape

- A per-container table (now, p50, max, limit), the pod-simultaneous maximum and the uptime trend.
- A board-class table (for example 1, 2, 4 and 8 GB) with peak plus measured node overhead.
- The blockers list: writes need an SSD, an amd64 image needs an arm64 build in CI, cross-site network reachability, and any component (such as a GPU Deployment) that must stay where it is.
- Keep measured baselines separate from `[INFERENCE]` (CPU scaling factors, base OS memory), and date every measurement: all of these are observations to re-measure, not constants.

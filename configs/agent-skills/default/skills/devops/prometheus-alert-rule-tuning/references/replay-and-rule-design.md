# Replaying history and designing the rule

Scope: before changing a rule. Read what exists, replay it on history, separate failure classes, then choose thresholds, `for:` and labels. Set `PROM` to the Prometheus base URL and use the kubeconfig the cluster requires for any `kubectl` query.

## 1. Read before replaying

- Read the alert, any recording rule it uses and its test file. Before changing a recording rule's labels or expression, find its consumers (`git grep -n '<record name>' origin/<default-branch> -- <manifest and doc dirs>`); dashboards, docs and other rules may read it.
- Check what the metric means in the producer's code. Summary-type quantiles from common exporter libraries are rolling windows (often 60 seconds) that render every quantile as 0 when the window is empty, so a silent stream looks healthy and a `>` rule on such a quantile sees lag, never silence.
- Alertmanager's root route usually groups by `[alertname, namespace]`; keeping an extra label (for example an outcome class) splits the alert per value while the notifications may still go out as one group.
- Copy sibling conventions (group interval, severity, service and owner labels) from the nearest existing rules rather than inventing new ones.
- A new rules file may need listing in the rules ConfigMap generator; a new group in an existing file does not.
- **New node-level alert**: list the metric's live label sets first (a filesystem metric returns every mount; on a single-volume host pin the mountpoint). Ask whether the exporter survives the condition you alert on: a node under disk pressure can evict its node-exporter, so a node-exporter rule resolves exactly when the disk is fullest. Anchor the critical alert on an independent source such as kube-state-metrics node conditions.

## 2. Replay on history

1. Replay the **current** rule first and compare it with `ALERTS{alertstate="firing",alertname="<name>"}` (merge consecutive samples into episodes) for the period it has been live. Do not trust candidate numbers until the replay matches what fired.
2. Break the series down by its labels (outcome, category, pod, dataset) before choosing the rule's shape. Read every episode a candidate keeps and say whether it was a real impairment.
3. Report a table: candidate, episodes, hours firing, and name each surviving episode with what was actually wrong.
4. For a new rule, replay candidate thresholds and the incident signal you want to catch earlier, and list gaps of more than five minutes in the input series.
5. To check whether a class was ever sustained: `max_over_time((min_over_time((<expr>)[15m:1m]))[15d:1m])`. A result of 0 means it was never non-zero for fifteen consecutive minutes (adjust the window to the rule's `for:`).
6. Which failure classes occur at all: `sum by (<class label>) (increase(<counter>[<history>]))`. Often one class is routine noise and the others are hard failures.
7. node-exporter's `pod` and `instance` labels change whenever the pod is recreated; wrap node-exporter inputs in `max by (node) (...)` to replay one continuous series.

A replay with no episodes can still be right when the incident censored the metric (an exporter evicted before the free-space threshold was ever reached, a gap in the series that matches each incident). Explain that in the change rather than raising the threshold until something fires.

Run the helper from a heredoc or from a private scratch directory, never from a stray file in a shared temp directory that can shadow the standard library:

```python
import json, time, urllib.parse, urllib.request
from collections import defaultdict

PROM = "<prometheus-base-url>/api/v1/query_range"
EXPR = "<alert left-hand side, no comparison>"
THRESHOLDS = [0, 0.1, 0.25, 0.5]
FOR_S = 15 * 60   # the alert's `for:`
STEP_S = 60       # replay step; the rule group's interval is exact
DAYS = 15         # at most the retained history

def query_range(expr, start, end, step):
    series = defaultdict(dict)
    s = start
    while s < end:
        e = min(s + 10_000 * step, end)   # stay under 11,000 points per series
        q = urllib.parse.urlencode({"query": expr, "start": s, "end": e, "step": step})
        for r in json.load(urllib.request.urlopen(f"{PROM}?{q}", timeout=180))["data"]["result"]:
            series[tuple(sorted(r["metric"].items()))].update((int(t), float(v)) for t, v in r["values"])
        s = e
    return series

def firing(points, threshold):
    """Replay `expr > threshold` with `for:`; a missing sample resets the alert."""
    episodes, since, cur, prev = [], None, None, None
    for t in sorted(points):
        if prev is not None and t - prev > STEP_S:
            if cur:
                episodes.append(cur)
            since = cur = None
        prev = t
        if points[t] > threshold:
            since = t if since is None else since
            if t - since >= FOR_S:
                cur = [cur[0], t] if cur else [t, t]
        else:
            if cur:
                episodes.append(cur)
            since = cur = None
    if cur:
        episodes.append(cur)
    return episodes

end = int(time.time()) // STEP_S * STEP_S
data = query_range(EXPR, end - DAYS * 86400, end, STEP_S)
fmt = lambda t: time.strftime("%m-%d %H:%M", time.gmtime(t))
for thr in THRESHOLDS:
    eps = sorted(((a, b, dict(k)) for k, p in data.items() for a, b in firing(p, thr)), key=lambda e: e[0])
    print(f"> {thr}: {len(eps)} episodes, {sum(b - a + STEP_S for a, b, _ in eps) / 3600:.1f} h firing")
    for a, b, labels in eps[:10]:
        print(f"    {fmt(a)} -> {fmt(b)} {labels}")
```

Put gates and label selectors in `EXPR` and keep the comparison in Python; flip it for `<` or `==` rules. Use the rule group's evaluation granularity as the step (a fine step for short `for:`) and chunk long ranges.

## 3. Design

- Split benign from hard failures: keep the class label in the recording rule and give each class its own bound (for example `rate{outcome="429"} > 0.25 or rate{outcome!="429"} > 0`). A shared raised threshold lets one failing lane hide under the bar; put the class in the annotation.
- Share or ratio thresholds go undefined or noisy when backoff drives attempts toward zero, so a starvation episode can be missed. Prefer an absolute rate of the error outcome.
- A readiness gate (`unless on (namespace, pod) kube_pod_status_ready{condition="false"} == 1`) removes warm-up alerts on pods that are not Ready but fails open when kube-state-metrics is missing; the `and ... == 1` form fails closed. Either form hides a pod that never becomes Ready. Record an owner's decision to decline a gate as a dated decision, not a rule.
- Put the backtest window, its numbers and the surviving episode in a comment above the rule.

## Gotchas

- PromQL `=~` matchers are fully anchored: `pod=~"collector"` matches only that literal name; write `collector.*`.
- `query_range` returns at most 11,000 points per series; chunk long ranges.
- Select node-exporter series by the node label the scrape job relabels; `instance` is a pod IP and `node_uname_info.nodename` is the pod name, not the host.
- Log lines can carry ANSI colour codes; strip them before slicing timestamps.
- After a recording-rule label change the old label set stays queryable for up to the five-minute lookback, so a query right after apply can show both.
- Diffing a live ConfigMap against a render through `jq -r` adds a trailing newline to each file; compare changed lines only.

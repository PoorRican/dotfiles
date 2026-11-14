# Replay and rule design

- Read the existing alert, its recording rules and consumers. Check the producer's metric semantics: rolling summary quantiles may return zero when a window is empty, so a threshold on lag may not detect a silent stream.
- Replay the current rule over its live history at the rule group's evaluation interval, with the same selectors, labels, comparison and `for:` semantics; compare episodes against `ALERTS{alertstate="firing"}`. Investigate mismatches and missing samples before trusting candidate results. Account for rules changing during the window and for gaps or stale series.
- Break episodes down by labels and inspect the impairment each candidate catches or misses. An empty replay may reflect an exporter disappearing during the incident, not a healthy system; use an independent signal where the exporter itself can fail.
- Preserve a class label and consider separate bounds when benign and serious failures need different sensitivity. A shared raised threshold can hide a hard failure, but a split is not automatically better. Absolute error rates may catch starvation that ratios miss when backoff makes the denominator vanish.
- Evaluate readiness gates for missing telemetry and for pods that never become Ready: an `unless` gate can fail open if its matching readiness series disappears, while an `and` gate can fail closed. Either can suppress a persistent unready pod.
- Inspect the configured Alertmanager route and `group_by`: distinct alert instances can still be grouped into one notification. Check live metric labels and scrape relabeling rather than assuming `instance` or a node label identifies the host.
- Recording-rule label changes affect consumers; old series may remain queryable temporarily. PromQL regex matchers are anchored, so a prefix match needs an explicit suffix wildcard.

## Replay helper

This helper replays a `>` threshold and a `for:` period on range-query samples, resetting pending state on gaps. Set the expression to the alert's left-hand side, including selectors and gates, and use the rule group's evaluation interval and alignment. Adapt the comparison for `<` or `==`; compare with firing `ALERTS` before trusting candidate results. It does not reconstruct historical rule changes or all Prometheus alert-state behavior.

```python
import json, time, urllib.parse, urllib.request
from collections import defaultdict

PROM = "<prometheus-base-url>/api/v1/query_range"
EXPR = "<alert left-hand side, no comparison>"
THRESHOLDS = [0, 0.1, 0.25, 0.5]
FOR_S = 15 * 60
STEP_S = 60
DAYS = 15

def query_range(expr, start, end, step):
    series = defaultdict(dict)
    s = start
    while s < end:
        e = min(s + 10_000 * step, end)
        q = urllib.parse.urlencode({"query": expr, "start": s, "end": e, "step": step})
        for r in json.load(urllib.request.urlopen(f"{PROM}?{q}", timeout=180))["data"]["result"]:
            series[tuple(sorted(r["metric"].items()))].update((int(t), float(v)) for t, v in r["values"])
        s = e
    return series

def firing(points, threshold):
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

Chunking stays below the range-query point limit. Inspect all retained episodes, not just the first ten printed here, and examine gaps in input series.

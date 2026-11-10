# Landing, applying and verifying an alert change

Scope: after the replay and tests pass. Landing a rule change and applying the Prometheus overlay are separate steps; verify the second explicitly.

## PR

1. Work in a worktree from the remote default branch and stage explicit paths.
2. Put the replay table in the PR body, with the rejected alternatives, the tests and the mutants they caught.
3. Satisfy whatever review gate the owner requires (CI green, review threads replied to and resolved), then merge with a match on the head commit so a late push cannot slip in (`gh pr merge N --merge --match-head-commit <sha>`).

## Before applying

Compare the live rules ConfigMap with the master render file by file. Other sessions' merged-but-unapplied rules ride along with your apply, and a rule whose input metric is not yet emitted is inert until the producer ships; name such rules in the report and read the PR's deploy gate. The live ConfigMap name is on the Deployment's rules volume:

```bash
kubectl -n <ns> get deploy prometheus -o jsonpath='{range .spec.template.spec.volumes[?(@.name=="rules")]}{.configMap.name}{end}'
```

## Apply

From a clean detached worktree at the merged default branch:

```bash
kubectl diff -k <prometheus overlay>     # expect a new content-hashed rules ConfigMap and the Deployment's reference to it
kubectl apply -k <prometheus overlay>
kubectl -n <ns> rollout status deploy/prometheus --timeout=10m   # Recreate: one brief restart
kubectl diff -k <prometheus overlay>; echo $?   # must be 0
```

## Verify

- Wait one rule-group interval (plus margin), then read the rules API: the rule's `query` must be the new expression, and every rule's `health` must be `ok` or `unknown` (a new rule is `unknown` until its first evaluation). For example `curl -s "$PROM/api/v1/rules" | jq -r '.data.groups[].rules[] | select(.name=="<Alert>") | "\(.query) health=\(.health) state=\(.state)"'`.
- Active alerts: `kubectl -n <ns> exec deploy/prometheus -c prometheus -- wget -qO- 'http://alertmanager:9093/api/v2/alerts?active=true&silenced=false&inhibited=false'`.
- Delivery: if Prometheus does not scrape Alertmanager, read the notification counters from its own endpoint (`alertmanager_notifications_total` and `alertmanager_notifications_failed_total` for the integration in use) rather than assuming delivery.
- After a recording-rule label change, expect both label sets to be queryable for a few minutes.
- Report merged, applied and runtime-verified separately, and the dated decisions (for example an owner declining readiness gating) that the rule deliberately does not encode.

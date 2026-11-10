# promtool boundary tests and a mutation harness

Scope: proving a changed or new alert rule does what the replay said. Each rules file has its tests beside it (`<name>.rules.test.yml`); run everything in the same image CI uses, so the result matches CI.

## Boundary tests

- Cover both sides of each threshold: just under, held well past `for:`, gives `exp_alerts: []`; just over gives no alert before `for:` elapses and an alert after. Keep evaluation times well clear of the boundary (for example `10m` and `25m` for a 15-minute `for:` over a `rate(...[5m])`).
- Absolute byte thresholds: test `threshold - 1` (fires for a `<` rule) and exactly `threshold` (silent), for example `53687091199` and `53687091200` for 50 GiB. Add decoys that must stay silent: another mount on the same node and the same mount on another node.
- Counter inputs at `interval: 1m`: `'0+18x60'` is 0.3 per second.
- `exp_labels` must list severity, service and every label the expression keeps (the class label, `condition`, `status: "true"` for kube-state-metrics conditions). Quote numeric-looking or boolean-looking values (`outcome: "429"`). `exp_annotations` must be the exact rendered text with templates expanded.

## Mutation check

Mutate every threshold, comparison operator, label matcher and `for:` in turn. Each mutation must fail exactly its intended case; a mutation that no test notices means the test is not pinning that boundary. Build the mutants outside the worktree:

```bash
M=$(mktemp -d -p "${SCRATCH_DIR:-.}")
python - "$M" <<'PY'
import pathlib, shutil, sys
root, src = pathlib.Path(sys.argv[1]), pathlib.Path("<rules-dir>")
rules = (src / "NAME.rules.yml").read_text()
EXPR = 'node_filesystem_avail_bytes{node="n1",mountpoint="/"} < 53687091200'   # exact text of the expression in the rules file
assert rules.count(EXPR) == 1
mutants = {
    "threshold": rules.replace(EXPR, EXPR.replace("53687091200", "42949672960")),
    "lt-to-le": rules.replace(EXPR, EXPR.replace("< ", "<= ")),
    "drop-mountpoint": rules.replace(EXPR, EXPR.replace(',mountpoint="/"', "")),
}
for name, text in mutants.items():
    assert text != rules, name
    shutil.copytree(src, root / name)
    (root / name / "NAME.rules.yml").write_text(text)
PY
chmod -R a+rX "$M"   # the image runs as nobody: otherwise cd fails and every mutant looks detected
docker run --rm --entrypoint /bin/sh -v "$M:/m:ro" prom/prometheus:<ci-version> -c '
  for d in /m/*/; do cd "$d"
    if out=$(/bin/promtool test rules NAME.rules.test.yml 2>&1); then echo "$(basename "$d"): NOT DETECTED"
    else echo "$(basename "$d"): $(printf "%s\n" "$out" | grep -o -E "name: [a-z0-9-]+" | sort -u | tr "\n" " ")"; fi
  done'
rm -rf "$M"
```

Use the Prometheus image version CI pins, not `latest`. A mutant must fail at least one named test; "NOT DETECTED" is a missing test.

## Run everything

```bash
docker run --rm --entrypoint /bin/sh -v "$PWD/<rules-dir>:/rules:ro" prom/prometheus:<ci-version> -ec \
  'cd /rules && for f in *.rules.yml; do /bin/promtool check rules "$f" >/dev/null || echo "CHECK FAIL $f"; done;
   for t in *.rules.test.yml; do /bin/promtool test rules "$t" >/dev/null 2>&1 || echo "FAIL $t"; done'
```

Also run any repository render tests that pin the observability overlays (storage or Alertmanager render tests) when those overlays changed.

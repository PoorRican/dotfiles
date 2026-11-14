# Rule tests and runtime verification

## Test the intended behavior

- Test values immediately on each side of the threshold and exactly at it where comparison strictness matters. For a `for:` rule, test before and after the hold period with enough input history for range functions. Add decoy label sets that must not fire and assert expected labels and rendered annotations.
- Use the Prometheus version used by the deployment or CI. When confidence in test sensitivity matters, mutate a threshold, comparison, matcher or `for:` independently and check that the relevant test fails; a passing mutant indicates a gap. A failure due to setup or file permissions is not a detected behavioral mutation.
- Ensure a test loop propagates failures rather than merely printing them. For example:

```sh
status=0
for t in ./*.rules.test.yml; do
  promtool test rules "$t" || status=1
done
exit "$status"
```

## Apply and verify

- Compare the intended rules render to the live configuration before an authorized apply: unrelated merged changes can ride along, and a rule whose producer metric is absent may be inert. Reload or roll out according to the deployment's configuration mechanism.
- After an evaluation interval, inspect the rules API for the intended expression and health; a newly loaded rule may be unknown before its first evaluation. Check active alerts and the relevant Alertmanager route, silences and inhibition separately.
- Verify notification delivery using the actual integration's delivery counters or receiver evidence. A loaded rule or an active Alertmanager alert alone does not prove delivery. Report merged, applied and runtime-verified states separately.

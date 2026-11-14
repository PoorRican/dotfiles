# Cost attribution

## Attribution to the executed path

- Identify the executing revision and the process, function, or phase that produced each timing. Counts establish frequency, not duration; time phases in a representative run rather than inferring them from idle-system probes.
- Factor logical-to-physical work into passes and fan-out. Separately issued per-entity queries need not share scans, even when they read the same input.
- Separate queue wait, admission, query, validation, reduction, and publication time when those phases exist. A late publication does not identify the expensive phase.
- A component's share of total time bounds the end-to-end effect of changing it. Measure both component and whole-workload cost.

## Comparison validity

- If a component's output changes downstream branches or call counts, whole-run timing mixes its cost with a changed workload. To isolate cost on a fixed trajectory, execute the real component at the real call sites but return baseline values; matching output digests check that the trajectory remained fixed. This does not establish output fidelity or cost under a changed trajectory.
- A component-off comparison isolates its cost only if the remaining consumer-visible inputs, outputs, and attempts are equivalent. Removing a downstream consumer includes that consumer's cost in the delta.
- Compare shared-host runs back-to-back under matched load and report spread, not just the best run. Batch wall time is not each item's historical latency, particularly when timing itself affects downstream behavior.
- Synthetic inputs should preserve relevant shapes and plausible variation; label them as synthetic and do not present component timing as production end-to-end timing. Judge equivalence at the consumer's actual reads, including changed observation timing or frequency.

## GPU measurement

- Warm each relevant specialization before timing; compilation and plan creation can dominate first calls. Collect steady-state timings separately from profiling.
- GPU profiling can consume substantial memory and perturb execution. Profile a bounded representative portion and time separate unprofiled warm runs.
- Measure baseline-to-baseline variation before attributing small training differences to a code or environment change.

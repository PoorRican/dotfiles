# Metric hygiene: auditing and restructuring logged metrics

Scope: finding degenerate or bloated W&B series, deciding what a key should mean, restructuring safely, and backfilling run tags across a shared project.

## Audit before proposing

- Pull each run's history once (`run.scan_history`) and classify every series: always 0, always 1, 0/1-varying, constant other, varying. Group exact duplicates after rounding to 1e-6, and tabulate by leading path segments and leaf name. The usual bloat is per-key health flags, Cartesian grids emitted whether or not a cell can exist, `0.0` standing for undefined, data-named keys, config facts logged as metrics, and keys grouped by statistic instead of by objective. (src: wandb-metric-hygiene; 2026-10)

## Rules that survived review

- NaN means undefined; `0.0` only means a measured zero.
- No per-key 0/1 flags: log per-snapshot health counts. Warn only on non-finite gradients.
- Emit a cell only if config, module ownership, or loss-mask structure allows it to exist. Never prune from observed batch values or from the first batch, and pin each exclusion with a test.
- Batch-derived counts stay metrics. Facts fixed by config go to run config (`log_hyperparams` or `wandb.config`).
- Drop a key only when it is an exact identity of other keys, with the proving code cited. Replace pairwise grids with component-versus-total alignment per target.

(src: wandb-metric-hygiene; 2026-10)

## Group, job type, and step axis

- `group` and `job_type` are read-only after `wandb.init`. Through a pipeline framework's tracker integration, pass the tracker's settings object with `group`, `job_type`, and `tags` under its settings key. These settings override the tracker component's own fields (including defaults), so keep the component configuration to entity, project, and API key. (src: wandb-metric-hygiene; 2026-10)
- With `WandbLogger(experiment=run)` make your own `define_metric` calls: the step metric with `step_sync=True`, and `summary="min"` for the selection metric. (src: wandb-metric-hygiene; 2026-10)

## Prove a restructure with a before/after key census

- Fit the module for two epochs with the production callbacks and a `CSVLogger` in a throwaway test, parse `metrics.csv`, and classify the series. Run the baseline from a `git archive` copy using the worktree's virtualenv, because the package in the working directory shadows the editable install. Bound expensive composed objectives so the census finishes. (src: wandb-metric-hygiene; 2026-10)

## Tag backfill

- List runs lazily with a `$nin` tag filter and classify by name and tags only. Mutate tags by re-fetching each run, skipping runs still running, and sending `upsertBucket(id, tags)`; `Run.update()` re-sends config, notes, group, and job type. Verify the returned tags equal `sorted(old | {new})` and append `{id, old, new}` to a JSONL manifest.
- Go dry run first, then one run with a config/summary hash comparison, then batches of 50-200 until the remaining count reaches zero. W&B cannot rename history, so document key vintages instead of renaming. (src: wandb-metric-hygiene; 2026-10)
- `upsertBucket` is an internal GraphQL mutation reached through the SDK's private service API (exercised under wandb 0.30); it is not a public contract, so recheck it on your wandb version before a bulk run. [INFERENCE: not re-run here]

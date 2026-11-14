# Denominators, Grains, and Boundaries

## Aggregation grain

- When selecting a child value for a parent, check whether it is constant on the actual filtered population. If not, use an explicitly meaningful selection rule; first/last selection needs a total ordering or an explicit tie-breaker for reproducibility.
- Check where non-constant groups concentrate and where the selected value flows: even a small share can distort a label or downstream features. Compare base rates on the same rows before treating a discrepancy as a defect.

## Short-circuit funnels

- Rejection buckets depend on check order. Each rate is conditional on reaching that check, so raw counts cannot rank gates. A downstream check never reached is unmeasured, not harmless; reordering can change bucket counts without changing behavior.
- Removing an upstream gate exposes candidates to downstream checks. Estimate the gain using the newly exposed population and its downstream pass rates, not the raw rejection count.

## Data and release boundaries

- Use actual deployment timing and the changes in that release to identify the data regime, rather than a source tag date. A rollout can span a partition; identify clean windows using rollout completion, partition timezone, lookback semantics, and subsequent releases.
- A schema change can appear as null-to-populated values, while a behavioral shift may require a distributional signature. Rows per timestamp can miss cadence changes when timestamps are unique; inspect per-entity inter-arrival distributions and tails rather than only the median.
- A declared evaluation window does not constrain an artifact unless admission checks enforce that window. A short post-release window can establish a mechanism without supporting a performance claim at the available independent sample size.

## Revision histories and grouped holdouts

- Separate an event's real-world history from the consumer's observed revision history. Validate revision markers against complete matched histories, including false positives and missed targets. First-to-final comparisons miss changes that later reverse; distinguish metadata, type, perspective, and substantive changes.
- Random row-level early-stopping splits can leak groups shared between training and validation. For grouped data, choose iterations on group-held-out data; a permuted control can help expose leakage.

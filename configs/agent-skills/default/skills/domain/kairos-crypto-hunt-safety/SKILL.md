---
name: kairos-crypto-hunt-safety
description: "Use when running parallel Kalshi crypto lake assays in kairos-research; enforces safe DuckDB resource limits, causal signal controls, fill realism, and verified fee/L2 decoding."
---

## Resource safety

- Set DuckDB `memory_limit='1GB'`.
- Spill only to `/var/tmp/duckdb_spill_<agent>` with `max_temp_directory_size='6GB'`; `/tmp` is RAM-backed tmpfs.
- Filter `family_id` and `date` before heavy operations. Process long windows per day/week and return compact aggregates.
- Delete spill directories when done. Never share an eval kernel between parallel prospectors.

## Lake correctness

- Deduplicate `lake.kalshi.universe` by `instrument_id` before joins.
- `universe.expiration_value` is exact settlement truth for threshold ladders.
- Trades use YES-axis price `price` for `side='bid'`, otherwise `1-price`; side is taker side.
- L2 asks are NO-price encoded: `yes_ask = 1_000_000 - max(ask_side_price)`.
- L2 `sequence` is null; order by `event_ts_ns` best-effort and exclude known feed-gap days.
- Become one with the data: inspect raw rows, units, event paths, and book reconstruction before aggregate inference.

## Causal signal standard

- Live features use only point-in-time, trailing, or expanding inputs.
- Full-event demeaning and centered smoothing are measurement-only; they are look-ahead inside a trigger.
- Use gapped/disjoint forward targets to avoid shared-endpoint EIV.
- Synthetic ladder estimators can show causal, OOS-stable IC from bid/ask bounce; confirm every signal on the actual traded contract's own quotes/results.
- Deduplicate repeated decisions on the same instrument so downstream tape is never counted multiple times.

## Execution and evidence

- Crypto maker fee is zero for `fee_type=quadratic`; taker fee is the exact order-level cent ceiling. Do not apply the sports-only 1.75% maker rate.
- Taker PnL pays the real touch and exact fee.
- Maker claims require true FIFO queue simulation: join behind displayed quantity, do not let cancels ahead advance the queue, and compare against matched random-side mechanics.
- Validate reconstructed book touches against tickers before trusting fills.
- Require absolute net profit, matched-placebo lift, clustered uncertainty, temporal OOS, monotonicity, and outlier/top-week robustness before `PAYS`.
- Report descriptive information separately from monetizable profit; a CI-null or post-selected result remains `RICH VEIN?`, never a stake.

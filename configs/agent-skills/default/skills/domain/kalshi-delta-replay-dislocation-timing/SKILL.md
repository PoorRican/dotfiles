---
name: kalshi-delta-replay-dislocation-timing
description: "Measure sub-second cross-market dislocation lifetimes on Kalshi lake data (any family) via validated orderbook_delta replay — use for arb-resolution timing, ladder coherence, or two-leg re-sync questions in kairos-research."
---

# Kalshi delta-replay dislocation timing

Measures episode lifetimes of cross-book coherence violations (two-leg sum-to-100, ladder monotonicity, crossed boxes) at true book resolution. Tickers-channel timing is unusable sub-second (inflates medians 10–180x, misses >60% of episodes) — always replay `orderbook_delta`.

## Setup

- Attach via `kairos_research.lake.attach_lake(env)`; the eval kernel may lack `KAIROS_LAKE_*` — dump from bash: `env | grep '^KAIROS_LAKE' > /var/tmp/kairos_lake.env` and parse.
- `SET memory_limit='1GB'; SET temp_directory='/var/tmp/duckdb_spill_<name>'; SET max_temp_directory_size='6GB'; SET preserve_insertion_order=false`. Delete spill dir when done.
- Always filter `family_id` + `date` (+ `instrument_id` list) before any scan; unfiltered orderbook_delta scans time out or OOM.

## Pre-flight gates

1. **Snapshot gap days**: check `orderbook_snapshots` has rows for the family+date (e.g. KXBTCD 2026-07-08 has deltas but NO snapshots — undreplayable). Enumerate dates, don't assume.
2. **Rung/leg selection** (ladders): pick instruments two-sided with 5c ≤ mid ≤ 95c for >10 ticks in-window from `tickers`. Near-money rungs carry ~95% of event delta volume, so instrument-filtered pulls are cheap.
3. **Windows starting at 00:00 UTC** (e.g. KXBTCD daily suffix-17): no same-date pre-window warmup snapshot exists; books ground at the first in-window snapshot (~1/min/rung) — skip deltas for an instrument until its book is seeded.

## Replay recipe (validated)

Reuse `kairos_research.sports.transcode`: `BookState`, `DeltaRow`, `apply_delta(clamp_underflow=True, clamp_stats=...)`.

- **Ground** each instrument from the latest raw snapshot STRICTLY before window start.
- **Encoding**: raw `orderbook_snapshots` asks are NO-space — seed `book.asks = {1_000_000 - price: qty}`; bids are YES-space. `apply_delta` converts ask deltas internally. `refined_snapshots` are already YES-space.
- **Order**: `sequence` is null; sort by `event_ts_ns`, apply same-ts deltas as one batch before evaluating pairs; at equal ts apply deltas before snapshots.
- **Validate before re-grounding**: at each in-window snapshot, compare replay BBO vs snapshot BBO (same YES-space conversion on both sides!) → require ≥99% exact (MLB reference: 99.33%; crypto achieved 99.4–100%). Then snapshot becomes authoritative (re-ground).

## Episode measurement

- Entry/exit convention matching the MLB probe: entry violation ≥2c, exit <1c; add ≥3c robustness row and an executable metric (crossed: ask_low < bid_high).
- Require BOTH legs simultaneously two-sided; when a leg goes one-sided mid-episode record `leg_dead` separately (on thin rungs the quote-pull IS the correction — report both conventions, headline the resolved-with-live-legs subset).
- Capture leg mids/touch prices at entry (needed for moneyness clustering and exact fee math later — retrofitting is painful).
- Clean-row rule: drop episodes with either endpoint within 500ms of a clamp or re-ground snapshot.
- Report: MLB-comparable duration bins (<100ms … >60s), p50/p90/p99, survival at 100ms/250ms/1s/2s/10s, episodes/hour AND burst count (episodes cluster: gaps ≥5s define bursts), entry-magnitude distribution, censoring counts.
- Always run a tickers-stage control on the same events to show the channel artifact.

## Fees (verified 2026-07-13)

Standard series: taker ⌈M·0.07·C·P(1−P)⌉ with M=1, maker M=0 (zero). KXBTCD/KXBTC are standard; KXBTCY/KXETHY are M=0 both sides. Compute box viability at ACTUAL leg prices — fees collapse away from 50c, so "≥4c at mid prices" style bars badly undercount nominally fee-positive boxes. Nominal ≠ capturable: gate on lifetime, depth at touch, adverse selection.

## Reference numbers (for comparison)

MLB KXMLBGAME two-leg ≥2c: delta p50 139ms / p90 2.0s / p99 16.4s; tickers p50 1.1s; 155 eps/active-game-hour (liquid set), 42→248/hr decided→competitive. KXBTCD adjacent-rung ≥2c: delta p50 ~9ms / p90 2.2s; tickers p50 1.6s; ~29/hr on hourlies arriving as ~27 bursts/day (80% in 12:00–17:00 UTC, ATM boundary rungs); daily suffix-17 ladder near-perfectly coherent (0.2/hr); crypto weekly cadence does not exist; 15M events are single-market (no coherence arb).

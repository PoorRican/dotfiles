---
name: kalshi-backtest-artifact-controls
description: "Mandatory artifact controls when assaying Kalshi (or any kline+tape) backtest signals: bar-label look-ahead audit, strict trade-through maker fills, month-split stability, adverse-selection fill checks"
---

# Kalshi Backtest Artifact Controls

Four controls that each killed a fake vein in the 2026-07-11 crypto survey. Run them BEFORE staking any claim; a signal that skips them is unverified.

## 1. Bar-label look-ahead audit (kline features)

`open_ts_ns` labels the bar OPEN; its close is knowable only at `open_ts + interval`. For a decision at time T, the causal close is from the bar with `open_ts = T - interval`.

- Reproduce the signal BOTH ways: (E1) strictly causal bars, (E2) deliberately shifted one bar later (`open_ts = T`).
- If E2 >> E1, the edge is look-ahead. E2 reproducing the original numbers to the cent identifies the bug precisely.
- **Next-quote/next-tick execution tests do NOT catch this class** — a quote 2s after T still doesn't know the T→T+60s move. Only the bar audit does.

## 2. Strict trade-through maker fills

Loose "at-or-through" tape fills (print >= rest price) manufacture veins: they yield ~99% fill rates and filter nothing.

- Strict rule: fill ONLY on a print STRICTLY beyond the rest price (queue-behind proxy). Score filled entries only, from rest price to settlement.
- Measured loose→strict haircut on KXBTC15M: **~1.6–2.1c/trigger**. Any maker edge below ~2c gross is presumptively a fill artifact.
- Rest price must be executable: `max(last_trade, prevailing same-side quote)` — never assume a fill at a stale last-print price.

## 3. Month-split (regime) stability

Report every result split by calendar month. A sign flip between months = regime artifact, not a stable claim (killed the 1m-momentum maker direction and the double-YES streak fade). Directional composition check: if >85% of trades are one side, suspect disguised beta on the period's drift.

## 4. Adverse-selection fill check

Compare settlement rates of FILLED vs UNFILLED (and vs all-trigger) populations:
- Filled win rate materially below unfilled/all-trigger → fills arrive exactly when the trade is wrong (killed the certainty-premium overlay: filled 95.6% vs unfilled 100%, and far-bucket sell: filled settle-YES 7–9% vs 0% unfilled).

## Reporting contract

Every assay states: N, hit rate, gross AND net (taker fee `ceil_to_cent(0.07*P*(1-P))`; maker under both $0 and 0.0175*P*(1-P) while disputed), price-region split (fee peaks 1.75c at P=.5, 0.63c at P=.9), and one-per-market variant when triggers can repeat within a market (overlap inflates N). Settlement fields are scoring-only, never features. Also state measurement-IC and causal-trigger-IC as separate numbers.

---
name: using-nautilus-trader
description: Use when building, backtesting, or deploying algorithmic trading systems with NautilusTrader (nautilus_trader) — writing Strategy/Actor classes and StrategyConfig, configuring BacktestNode/BacktestEngine, constructing instruments, order management, ParquetDataCatalog/wranglers, message bus and custom data streams, indicators, portfolio/analysis/report generation, or live TradingNode deployment. Curated for v1.230.0.
---

# NautilusTrader (v1.230.0)

Open-source, Rust-native, event-driven trading platform. **The same strategy code
runs unchanged in backtest, sandbox, and live** — this is the central design idea,
and most mistakes come from forgetting it. Python API over a Rust/Cython core.

> **Version pin:** curated against **v1.230.0** (current `latest`, 2026-07). The
> online docs serve only `latest`/`nightly` (no per-version markdown), so the links
> here point to `/docs/md/latest/…` which *is* v1.230.0 today. Nautilus makes
> **breaking changes between minor versions** before v2.0 — if your installed
> `nautilus_trader.__version__` differs, verify names/signatures against the
> [release notes](https://github.com/nautechsystems/nautilus_trader/releases) and
> [API reference](https://nautilustrader.io/docs/python-api-latest/). See
> [references/doc-map.md](references/doc-map.md) for the full online index.

## The one mental model that prevents most mistakes

You are **not** writing a backtest script. You are writing an event-driven
**component** (a `Strategy`, which *is* an `Actor` with order management) that
reacts to messages delivered by a `MessageBus` inside a `NautilusKernel`. A backtest
just feeds that component historical data through the same engines that a live venue
would. Consequences:

- No `for`-loops over data, no look-ahead. React inside `on_bar` / `on_quote_tick`
  / `on_trade_tick` / `on_data` / `on_event`. State lives on `self`.
- Everything is reached through the component: `self.submit_order(...)`,
  `self.cache`, `self.portfolio`, `self.clock`, `self.msgbus`, `self.log`,
  `self.subscribe_*`, `self.request_*`.
- Config is data: subclass `StrategyConfig`, keep it immutable/serializable, and the
  same class + config wiring deploys live.

## Decide where to look

| Your task | Read |
|---|---|
| Understand the engine, kernel, config system, environment contexts, logging | [architecture.md](references/architecture.md) |
| `Price` / `Quantity` / `Money` / `Currency`, IDs, precision bugs | [value-types.md](references/value-types.md) |
| Quote/Trade/Bar/OrderBook types, **BarType grammar**, subscriptions, aggregation | [data.md](references/data.md) |
| Feed your **own** data type through the engine (signals, features, PBP, etc.) | [custom-data.md](references/custom-data.md) |
| Build an `Instrument` + required metadata; providers; synthetics; options/greeks | [instruments.md](references/instruments.md) |
| Write a `Strategy`: config, handlers/hooks, timers, **one strategy → many markets** | [strategies.md](references/strategies.md) |
| Non-trading component (feature/data publisher) with `Actor` | [actors.md](references/actors.md) |
| Order types, `OrderFactory`, brackets/contingencies, emulation, order events | [orders.md](references/orders.md) |
| Execution flow, `ExecAlgorithm` (TWAP), OMS NETTING vs HEDGING, positions, fills | [execution.md](references/execution.md) |
| `MessageBus` pub/sub, `Cache` queries, events, **creating/subscribing to streams** | [message-bus.md](references/message-bus.md) |
| Configure & run a backtest — **high-level `BacktestNode` vs low-level `BacktestEngine`** | [backtesting.md](references/backtesting.md) |
| `ParquetDataCatalog`, wranglers, persisting instruments, datasets, streaming | [data-catalog.md](references/data-catalog.md) |
| Portfolio/account/PnL queries, `PortfolioAnalyzer` stats, report DataFrames | [portfolio-and-reports.md](references/portfolio-and-reports.md) |
| Go live: `TradingNode`, reconciliation, adapters, production safety | [live-trading.md](references/live-trading.md) |
| **Non-obvious mistakes across all areas** (read this early) | [gotchas.md](references/gotchas.md) |
| Full link index back to the online docs | [doc-map.md](references/doc-map.md) |

## The 80% workflow (offline backtest)

1. **Instrument** — build or load an `Instrument` ([instruments.md](references/instruments.md)),
   or grab one from `TestInstrumentProvider` for prototyping.
2. **Data** — wrangle raw data into Nautilus objects and (optionally) write to a
   `ParquetDataCatalog` ([data-catalog.md](references/data-catalog.md)).
3. **Strategy** — subclass `StrategyConfig` + `Strategy`; subscribe in `on_start`;
   trade in handlers ([strategies.md](references/strategies.md)).
4. **Backtest** — low-level `BacktestEngine` for a quick single run, or high-level
   `BacktestNode` + configs for reproducible, catalog-driven runs
   ([backtesting.md](references/backtesting.md)).
5. **Analyze** — pull `generate_*_report` DataFrames and `PortfolioAnalyzer` stats
   ([portfolio-and-reports.md](references/portfolio-and-reports.md)).
6. **Deploy** — swap `BacktestEngine`/`BacktestNode` for a `TradingNode`; the
   `Strategy` is untouched ([live-trading.md](references/live-trading.md)).

## Primitives you must get exactly right

```python
from nautilus_trader.model.identifiers import InstrumentId
from nautilus_trader.model.data import BarType
from nautilus_trader.model.objects import Price, Quantity

# InstrumentId = "{symbol}.{VENUE}"
InstrumentId.from_str("BTCUSDT.BINANCE")
InstrumentId.from_str("EUR/USD.SIM")     # SIM = the built-in simulated venue

# BarType = "{instrument_id}-{step}-{aggregation}-{price_type}-{agg_source}"
#   aggregation: MILLISECOND|SECOND|MINUTE|HOUR|DAY|WEEK|MONTH|YEAR | TICK|VOLUME|VALUE(+_IMBALANCE/_RUNS) | RENKO
#   price_type:  LAST | BID | ASK | MID
#   agg_source:  EXTERNAL (bars arrive pre-aggregated from the venue/data)
#                INTERNAL (Nautilus aggregates them from ticks/quotes for you)
BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
BarType.from_str("BTCUSDT.BINANCE-15-MINUTE-LAST-INTERNAL")

# ALWAYS build Price/Quantity from strings (or the instrument helpers) — never floats.
Price.from_str("50000.00")          # preserves precision
Quantity.from_str("1.5")
# instrument.make_price(50000.0) / instrument.make_qty(1.5)  # snaps to increments
```

| Enum | Values | Use |
|---|---|---|
| `OmsType` | `NETTING` (one net position/instrument, crypto-style), `HEDGING` (multiple positions/instrument) | per-venue in backtest/live config |
| `AccountType` | `CASH` (spot), `MARGIN` (leverage), `BETTING` | per-venue |
| `OrderSide` | `BUY`, `SELL` | orders |
| `TimeInForce` | `GTC`, `IOC`, `FOK`, `GTD` (needs `expire_time`), `DAY`, `AT_THE_OPEN`, `AT_THE_CLOSE` | orders |

## Top cross-cutting gotchas (full list in [gotchas.md](references/gotchas.md))

| Pitfall | Do this |
|---|---|
| Custom `Data` subclass never reaches `on_data` ("Cannot handle data: unrecognized type") | Feed it **wrapped**: `CustomData(DataType(T), obj)`. Nautilus unwraps before `on_data`, so `isinstance(data, T)` still works. Inside a component use `self.publish_data(DataType(T), obj)`. See [custom-data.md](references/custom-data.md). |
| `float` prices/quantities cause precision drift & silent rejects | `Price.from_str`/`Quantity.from_str` or `instrument.make_price/make_qty`. |
| Indicator never initializes / uses stale values | `register_indicator_for_bars(bar_type, ind)` **before** `subscribe_bars(bar_type)`; guard on `if not ind.initialized: return`. |
| `BarType` string wrong → no data | Exact grammar above; `INTERNAL` vs `EXTERNAL` is not cosmetic — it decides whether Nautilus aggregates. |
| Wrote ticks/bars to catalog but backtest sees no instrument | Persist the **instrument** into the catalog too (`catalog.write_data([instrument])`), and match `instrument_id` exactly. |
| One strategy trading many instruments collides on order/position tracking | Give each `Strategy` instance a unique `order_id_tag`/`StrategyId`; key per-instrument state in dicts; see the multi-instrument pattern in [strategies.md](references/strategies.md). |
| Subclassing `Strategy` but ignoring `StrategyConfig` | Put params in a frozen `StrategyConfig` subclass so the exact code deploys live and is reproducible. |

## Install

```bash
pip install -U nautilus_trader          # or: uv add nautilus-trader
# High-precision (128-bit) build differs from standard — see architecture.md.
```

- **Online docs:** https://nautilustrader.io/docs/latest/ ·
  **raw markdown:** https://nautilustrader.io/docs/md/latest/ ·
  **API ref:** https://nautilustrader.io/docs/python-api-latest/ ·
  **source:** https://github.com/nautechsystems/nautilus_trader

# Backtesting: High-Level vs Low-Level APIs

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/backtesting.md
- https://nautilustrader.io/docs/md/latest/getting_started/backtest_high_level.md
- https://nautilustrader.io/docs/md/latest/getting_started/backtest_low_level.md
- https://nautilustrader.io/docs/md/latest/getting_started/quickstart.md

## TL;DR

NautilusTrader has **two** backtest APIs over the same deterministic engine.

- **Low-level (`BacktestEngine`)** — you imperatively build one engine in memory:
  `add_venue → add_instrument → add_data → add_strategy/add_actor → run`. Full
  programmatic control, raw in-memory data, component swapping. Best for a single
  run, notebooks, and precise wiring.
- **High-level (`BacktestNode` + `*Config` objects)** — declarative, reproducible,
  config-driven. Data comes from a [ParquetDataCatalog](data-catalog.md); strategies
  are referenced by `module:Class` path strings. `BacktestNode` builds a **fresh
  `BacktestEngine` per `BacktestRunConfig`**, so it scales to many runs (grid
  searches / parameter sweeps) and large/out-of-memory data. Strategies written this
  way carry forward to [live trading](live-trading.md) unchanged.

Both replay data in **strict timestamp order**. Execution realism is governed by the
venue `book_type`, the data granularity fed, the fill model, and correct bar-close
timestamps (see [Gotchas](#gotchas)). Config value types differ between the two APIs:
low-level takes real objects (`OmsType.NETTING`, `Money`, `Currency`); high-level
config takes **strings** (`"NETTING"`, `"100_000 USD"`).

---

## Choosing an API

| Need | Use |
|---|---|
| Single run, full control, in-memory data | Low-level `BacktestEngine` |
| Notebook / quick experiment | Low-level |
| Many runs, parameter sweeps, reproducibility | High-level `BacktestNode` |
| Large / out-of-memory data via catalog | High-level (or low-level streaming) |
| Swap engine components / custom raw data formats | Low-level |
| Path directly to live `TradingNode` | High-level (same `*Config` shape) |

---

## Low-Level API: `BacktestEngine`

`BacktestEngine(config: BacktestEngineConfig = None)`. Order matters: **venue → instrument → data → strategy → run**.

```python
from decimal import Decimal
from nautilus_trader.backtest.engine import BacktestEngine
from nautilus_trader.config import BacktestEngineConfig, LoggingConfig
from nautilus_trader.model.currencies import USD
from nautilus_trader.model.enums import AccountType, OmsType
from nautilus_trader.model.identifiers import Venue
from nautilus_trader.model.objects import Money

engine = BacktestEngine(
    config=BacktestEngineConfig(logging=LoggingConfig(log_level="ERROR")),
)

SIM = Venue("SIM")
engine.add_venue(
    venue=SIM,
    oms_type=OmsType.NETTING,
    account_type=AccountType.MARGIN,
    starting_balances=[Money(1_000_000, USD)],
    base_currency=USD,
    default_leverage=Decimal(1),
)

engine.add_instrument(EURUSD)          # Instrument object (not the id)
engine.add_data(bars)                   # data derived from the instrument
engine.add_strategy(strategy)           # strategy config uses EURUSD.id
engine.run()

# Results (in-memory) — generate BEFORE dispose()
engine.trader.generate_account_report(SIM)
engine.trader.generate_positions_report()
engine.trader.generate_order_fills_report()
engine.dispose()
```

### `BacktestEngine` methods

| Method | Purpose |
|---|---|
| `add_venue(venue, oms_type, account_type, starting_balances, base_currency=..., book_type=..., default_leverage=..., fill_model=..., latency_model=..., bar_adaptive_high_low_ordering=..., ...)` | Register a simulated exchange + account |
| `add_instrument(instrument)` | Add instrument; must match loaded data precision |
| `add_data(data, sort=True)` | Load `Data` objects (copied internally); optional per-call sort |
| `add_data_iterator(data_name, generator)` | Stream data via a generator (out-of-memory datasets) |
| `sort_data()` | Sort the combined dataset once; idempotent |
| `add_strategy(strategy)` | Register a [strategy](strategies.md) |
| `add_actor(actor)` | Register an [actor](actors.md) |
| `add_exec_algorithm(exec_algo)` | Register an [execution algorithm](execution.md) |
| `run(streaming=False)` | Replay events deterministically; `streaming=True` for batched runs |
| `end()` | Finalize a streaming run: `on_stop`, flush timers, settle trailing commands |
| `reset()` | Reset to initial state; **keeps** data, instruments, venues, components |
| `clear_data()` | Remove loaded data (between manual chunk batches) |
| `clear_strategies()` | Remove strategies (call before re-adding after `reset()`) |
| `get_result()` | The `BacktestResult` for the run (singular) |
| `dispose()` | Release resources (call if script continues after run) |

### Multi-instrument: defer sorting

Sorting the full stream on every `add_data()` call compounds and is slow. Load with
`sort=False`, then sort once:

```python
engine.add_instrument(instrument1)
engine.add_instrument(instrument2)
engine.add_data(instrument1_bars, sort=False)
engine.add_data(instrument2_bars, sort=False)
engine.sort_data()          # one final sort; idempotent
engine.add_strategy(strategy)
engine.run()
```

Calling `run()` with unsorted data (after `add_data(sort=False)`) raises `RuntimeError`.

### Multi-currency / spot account

`base_currency=None` enables a multi-currency account with multiple starting balances:

```python
engine.add_venue(
    venue=Venue("BINANCE"),
    oms_type=OmsType.NETTING,
    account_type=AccountType.CASH,          # CASH = spot only (not perps/futures)
    base_currency=None,                      # multi-currency
    starting_balances=[Money(1_000_000.0, USDT), Money(10.0, ETH)],
)
```

### Reset for parameter optimization

```python
engine.reset()              # keeps data/instruments/venues; resets component state
engine.clear_strategies()   # required before adding a replacement
engine.add_strategy(new_strategy)
engine.run()
```

### Low-level streaming (out-of-memory)

```python
# Via generator
def data_generator():
    yield load_chunk_1()
    yield load_chunk_2()
engine.add_data_iterator("stream_name", data_generator())
engine.run()

# Manual chunked (the pattern BacktestNode uses internally)
engine.add_strategy(strategy)
for batch in batches:
    engine.add_data(batch)
    engine.run(streaming=True)
    engine.clear_data()
engine.end()                # finalizes; do NOT skip
```

---

## High-Level API: `BacktestNode` + configs

Load data into a catalog, then declare venues/data/strategies as config objects,
aggregate into a `BacktestRunConfig`, and run via `BacktestNode`.

```python
from nautilus_trader.backtest.node import (
    BacktestDataConfig, BacktestEngineConfig, BacktestNode,
    BacktestRunConfig, BacktestVenueConfig,
)
from nautilus_trader.config import ImportableStrategyConfig
from nautilus_trader.model import QuoteTick
from nautilus_trader.persistence.catalog import ParquetDataCatalog

# 1) Catalog (see data-catalog.md) — write instrument first (as a list), then data
catalog = ParquetDataCatalog(CATALOG_PATH)
catalog.write_data([EURUSD])
catalog.write_data(ticks)

# 2) Venues — note: strings, not enum/Money objects
venues = [BacktestVenueConfig(
    name="SIM",
    oms_type="HEDGING",
    account_type="MARGIN",
    base_currency="USD",
    starting_balances=["1_000_000 USD"],
)]

# 3) Data sources — catalog_path must be a str()
data = [BacktestDataConfig(
    catalog_path=str(CATALOG_PATH),
    data_cls=QuoteTick,
    instrument_id=EURUSD.id,
    start_time=start_time,
    end_time=end_time,
)]

# 4) Strategy by module:Class path strings; bar_type as its STRING form
strategies = [ImportableStrategyConfig(
    strategy_path="nautilus_trader.examples.strategies.ema_cross:EMACross",
    config_path="nautilus_trader.examples.strategies.ema_cross:EMACrossConfig",
    config={
        "instrument_id": EURUSD.id,
        "bar_type": "EUR/USD.SIM-15-MINUTE-BID-INTERNAL",
        "fast_ema_period": 10,
        "slow_ema_period": 20,
        "trade_size": Decimal(1_000_000),
    },
)]

# 5) Assemble + run — one BacktestRunConfig per run
config = BacktestRunConfig(
    engine=BacktestEngineConfig(strategies=strategies),
    data=data,
    venues=venues,
)
node = BacktestNode(configs=[config])
results = node.run()
```

### High-level config objects

| Config | Key fields |
|---|---|
| `BacktestRunConfig` | `venues: list[BacktestVenueConfig]`, `data: list[BacktestDataConfig]`, `engine: BacktestEngineConfig`, `chunk_size`, `raise_exception`, `dispose_on_completion`, `start`, `end`, `data_clients`. (Actors/strategies/exec_algorithms live on the `engine` `BacktestEngineConfig`.) |
| `BacktestVenueConfig` | `name`, `oms_type`, `account_type`, `base_currency`, `starting_balances`, `book_type`, `fill_model`, `latency_model`, `margin_model`, ... (see venue table) |
| `BacktestDataConfig` | `catalog_path` (str), `data_cls` (e.g. `QuoteTick`), `instrument_id`, `start_time`, `end_time` |
| `BacktestEngineConfig` | `strategies`, `actors`, `exec_algorithms`, `controller`, `trader_id`, `logging`, `cache`, `message_bus`, `data_engine`/`risk_engine`/`exec_engine` sub-configs |
| `ImportableStrategyConfig` | `strategy_path`, `config_path`, `config` (dict) |
| `ImportableFillModelConfig` | `fill_model_path`, `config_path`, `config` (dict) |

`BacktestNode(configs)` builds a **fresh engine per config** — pass many
`BacktestRunConfig`s for a sweep. The high-level API is *Partialable for staged
construction. Populate the catalog first (see [data-catalog.md](data-catalog.md)).

---

## Venue configuration (both APIs)

| Param | Type / values | Default | Meaning |
|---|---|---|---|
| `oms_type` | `OmsType.NETTING` / `HEDGING` (str `"NETTING"`/`"HEDGING"` high-level) | — | Position accounting model |
| `account_type` | `AccountType.CASH` / `MARGIN` / `BETTING` (str high-level) | — | `CASH` = spot only |
| `starting_balances` | `[Money(...)]` low / `["100_000 USD"]` high | — | Initial balances |
| `base_currency` | `Currency` / str / `None` | — | `None` → multi-currency account |
| `book_type` | `BookType.L1_MBP` / `L2_MBP` / `L3_MBO` | `L1_MBP` | Book granularity driving matching |
| `fill_model` | `FillModel` / `ImportableFillModelConfig` | none | Probabilistic fill/slippage |
| `latency_model` | `LatencyModel` | none | Simulated command latency |
| `margin_model` | `MarginModelConfig` | none | Margin simulation |
| `default_leverage` | `Decimal` | — | Leverage for margin accounts |
| `trade_execution` | `bool` | `True` | Enable trade-tick fills |
| `bar_execution` | `bool` | `True` | Enable bar-based fills (needs bar close `ts_init`) |
| `queue_position` | `bool` | `False` | Track LIMIT queue position (with `trade_execution`) |
| `bar_adaptive_high_low_ordering` | `bool` | `False` | Adaptively sequence High/Low within a bar (~75-85% accuracy vs ~50%) |
| `liquidity_consumption` | `bool` | `False` | Track consumed liquidity per level; prevents duplicate fills |
| `price_protection_points` | `int` / `None` | `None` | Protection boundary for MARKET/STOP_MARKET; `None` disables |

### `BookType` → data required

| BookType | Drives matching from | Bars/quotes update book? |
|---|---|---|
| `L1_MBP` (default) | quotes, trades, **bars** | yes (L1 top-of-book) |
| `L2_MBP` | `OrderBookDelta(s)` | **no** — bars/quotes do not update the book |
| `L3_MBO` | `OrderBookDelta(s)` | **no** |

Under L2/L3, feeding only quotes/bars means orders may **never fill** — provide
order book delta data (see [data.md](data.md)). Bars are not processed for
execution under L2/L3 (strategies still receive them).

---

## FillModel

`FillModel(prob_fill_on_limit=1.0, prob_slippage=0.0, random_seed=None)`

| Param | Default | Meaning |
|---|---|---|
| `prob_fill_on_limit` | `1.0` | Probability a limit order fills at touch |
| `prob_slippage` | `0.0` | Probability of slippage (L1 data) |
| `random_seed` | `None` | PRNG seed for reproducibility (same-process) |

Low-level: pass a `FillModel(...)` to `add_venue(fill_model=...)`. High-level: use
`ImportableFillModelConfig`:

```python
from nautilus_trader.backtest.config import BacktestVenueConfig, ImportableFillModelConfig

BacktestVenueConfig(
    name="SIM", oms_type="NETTING", account_type="CASH",
    starting_balances=["100_000 USD"],
    fill_model=ImportableFillModelConfig(
        fill_model_path="nautilus_trader.backtest.models:FillModel",
        config_path="nautilus_trader.backtest.config:FillModelConfig",
        config={"prob_fill_on_limit": 0.2, "prob_slippage": 0.5, "random_seed": 42},
    ),
)
```

`LatencyModel` (simulated command latency) is passed via `add_venue(latency_model=...)`
low-level or `BacktestVenueConfig(latency_model=...)` high-level. `MarginModelConfig`
takes `model_type` (`"leveraged"` / `"standard"` / class path) and `config` dict.

---

## Backtest loop (mental model)

Each data point is processed in three phases at its timestamp:
1. **Exchange matching** — the venue matches resting orders against the update.
2. **Strategy callbacks** — `on_bar` / `on_quote_tick` / `on_data` etc. fire.
3. **Command settling** — orders submitted in phase 2 settle; cascading orders
   settle **within the same timestamp**.

Trade-tick fills trigger on the **opposite** side of the aggressor: a SELLER trade
fills your BUY orders; a BUYER trade fills your SELL orders.

---

## Getting results

Both APIs expose the trader's report generators (low-level via `engine.trader`,
call before `dispose()`):

| Call | Returns |
|---|---|
| `engine.trader.generate_account_report(venue)` | Account report for a venue |
| `engine.trader.generate_order_fills_report()` | Order fills report |
| `engine.trader.generate_positions_report()` | Positions report |
| `engine.get_result()` | The `BacktestResult` for the run (singular) |
| `node.run()` | List of results (one per `BacktestRunConfig`) |

Deeper P&L / statistics come from the portfolio analyzer — see
[portfolio-and-reports.md](portfolio-and-reports.md).

### Single engine vs multiple runs

- **One engine, many instruments/strategies** — add all to a single `BacktestEngine`
  (or one `BacktestRunConfig`). They share one account/portfolio and interact
  (cross-instrument portfolio state). Use for multi-asset strategies.
- **Multiple runs** — pass multiple `BacktestRunConfig`s to `BacktestNode`, or
  `reset()`/`clear_strategies()` a low-level engine between runs. Each run is
  isolated (fresh engine in the high-level case). Use for sweeps/comparisons.

---

## Grammar tables

| Name | Format | Example |
|---|---|---|
| `InstrumentId` | `{symbol}.{venue}` | `EUR/USD.SIM`, `ETHUSDT.BINANCE` |
| `BarType` (string form) | `{InstrumentId}-{step}-{aggregation}-{price_type}-{source}` | `EUR/USD.SIM-15-MINUTE-BID-INTERNAL`, `ETHUSDT.BINANCE-250-TICK-LAST-INTERNAL` |
| `starting_balances` entry (high-level) | `"{amount} {currency}"` | `"1_000_000 USD"` |
| `strategy_path` / `config_path` | `{module.path}:{ClassName}` | `nautilus_trader.examples.strategies.ema_cross:EMACross` |
| `TradeId` (backtest-derived) | `T-{fnv1a_hash(venue, raw_id, ts_init):016x}-{fill_count:03d}` | `T-1a2b3c4d5e6f7890-001` (deterministic across runs) |

`BarType.from_str("...")` parses the string form. In high-level config dicts,
`bar_type` must be passed as the **string**, not a `BarType` object.

---

## Gotchas

- **Bars timestamped at OPEN time.** With `bar_execution=True` (default) Nautilus
  strictly expects `ts_init` = bar **close** time; open-timestamped bars cause
  look-ahead bias. → Use adapter config like `bars_timestamp_on_close=True`, or set
  `ts_init_delta` to the bar duration (e.g. `60_000_000_000` ns for 1-minute bars).
  Also consider `DataEngineConfig.time_bars_build_delay` (µs) so boundary data is
  processed before the bar closes.
- **`book_type=L2_MBP/L3_MBO` but feeding only quotes/bars.** Quotes and bars do NOT
  update the L2/L3 book, so orders may never fill. → Provide `OrderBookDelta(s)`
  matching the chosen book type.
- **Subscribing to book deltas under `L1_MBP`.** Under L1 (default) order book deltas
  are ignored by the matching engine. → Set `book_type` to `L2_MBP`/`L3_MBO`.
- **`run()` with unsorted data after `add_data(sort=False)`.** Raises `RuntimeError`.
  → Call `sort_data()` (idempotent) before `run()`.
- **Sorting on every `add_data()` for many instruments.** Compounds (1M, 2M, …). →
  `add_data(..., sort=False)` per call, then `sort_data()` once.
- **Precision mismatch between data and instrument.** Prices/quantities validated
  against `instrument.price_precision` / `size_precision`; mismatch raises
  `RuntimeError` immediately. → Align via `instrument.make_price()` /
  `instrument.make_qty()`.
- **Assuming a trade tick fills same-side orders.** Fills trigger on the OPPOSITE
  side of the aggressor. → Reason by aggressor side, not the order's side label.
- **Expecting book depth to decrement after fills.** Historical book is immutable;
  default `liquidity_consumption=False` lets the same liquidity be consumed
  repeatedly. → Set `liquidity_consumption=True`. (Not applied to custom fill-model
  synthetic books — those must track their own liquidity.)
- **Fixed OHLC ordering vs real intrabar path.** Default is Open→High→Low→Close
  regardless of actual movement, affecting which of TP/SL fills first. → Enable
  `bar_adaptive_high_low_ordering=True` (~75-85% accuracy vs ~50%).
- **`AccountType.CASH` for perps/futures.** CASH is spot only. → Use `MARGIN` (etc.)
  for derivatives.
- **`Bar.volume` in quote-currency units.** Must be base-currency units. → Convert
  before loading.
- **Passing a `Path` to `BacktestDataConfig.catalog_path`.** Expects a string. →
  `str(CATALOG_PATH)`.
- **Writing an instrument as a bare object.** `catalog.write_data` expects an
  iterable. → `catalog.write_data([EURUSD])`.
- **`bar_type` as a structured object in high-level config dict.** Expects the string
  form, e.g. `"EUR/USD.SIM-15-MINUTE-BID-INTERNAL"`.
- **Importing strategy classes directly for the high-level API.** It resolves from
  `module:Class` path strings via `ImportableStrategyConfig`, not live objects.
- **Adding data before its instrument (low-level).** Data references the instrument.
  → `add_instrument(...)` before `add_data(...)`.
- **Generating reports after `dispose()`.** Reports read in-memory state. → Generate
  before `dispose()`.
- **Assuming `reset()` clears everything.** It keeps data/instruments/venues/
  components and resets only internal state. → After `reset()`, `clear_strategies()`
  and re-add replacements; do not re-add instruments/data.
- **Relying on fill handlers during shutdown.** Strategy event handlers do not fire
  for post-shutdown fills in `on_stop`. → Run fill-reactive logic before `on_stop`
  returns.
- **Indicator values before warmup.** → Gate `on_bar` on `if not
  self.indicators_initialized(): return`.
- **Naive/non-UTC DataFrame index for wranglers.** → Use `pd.date_range(..., tz="UTC")`.
- **Cross-process reproducibility with `random_seed`.** Same-process reruns match;
  cross-process may differ in rare cases due to hash-ordering. Compare within a
  process.
- **Data added by a timer callback at exact start time may be misordered.** The
  engine reads the first data point before start-time timers. → Give such data
  timestamps strictly after the start time.
- **Reusing a stale catalog directory.** → `shutil.rmtree` + recreate before writing.

See also: [SKILL.md](../SKILL.md), [strategies.md](strategies.md),
[data-catalog.md](data-catalog.md), [portfolio-and-reports.md](portfolio-and-reports.md),
[live-trading.md](live-trading.md), [gotchas.md](gotchas.md).

# Market Data Primitives & Bar Aggregation

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/data.md
- https://nautilustrader.io/docs/md/latest/concepts/order_book.md

## TL;DR

Every Nautilus data object is a `Data` subclass carrying **two nanosecond
timestamps**: `ts_event` (when the event happened at source) and `ts_init` (when
Nautilus created/received the object). Backtests order the world by `ts_init`.
Strategies/actors never loop over data — they `subscribe_*` (live stream) or
`request_*` (historical batch) and react in `on_*` handlers. A `Bar` is identified
by a `BarType`, whose string grammar (`{instrument}-{step}-{aggregation}-{price}-{source}`)
is the single most error-prone string in the framework: get the enum spellings and
the `INTERNAL` vs `EXTERNAL` source right and most bar work just works. Prices and
quantities are fixed-point (`Price`/`Quantity`), never raw floats.

See also: [value-types](value-types.md) (Price/Quantity/InstrumentId),
[custom-data](custom-data.md), [instruments](instruments.md),
[strategies](strategies.md), [data-catalog](data-catalog.md),
[backtesting](backtesting.md), [SKILL.md](../SKILL.md).

## Built-in data types

All carry `ts_event: int` and `ts_init: int` (UNIX nanoseconds). Import from
`nautilus_trader.model` (e.g. `from nautilus_trader.model import QuoteTick, TradeTick, Bar`).

| Type | What it is | Subscribe with | Handler |
|---|---|---|---|
| `QuoteTick` | Top-of-book bid/ask price + size (L1) | `subscribe_quote_ticks(instrument_id)` | `on_quote_tick(tick)` |
| `TradeTick` | A single executed trade (price, size, `aggressor_side`, trade id) | `subscribe_trade_ticks(instrument_id)` | `on_trade_tick(tick)` |
| `Bar` | OHLCV bar keyed by a `BarType` | `subscribe_bars(bar_type)` | `on_bar(bar)` |
| `OrderBookDelta` / `OrderBookDeltas` | Incremental L2/L3 book updates (single / container) | `subscribe_order_book_deltas(instrument_id)` | `on_order_book_deltas(deltas)` |
| `OrderBookDepth10` | Aggregated snapshot, up to 10 levels per side | `subscribe_order_book_depth(instrument_id)` | `on_order_book_depth(depth)` |
| (full book snapshot) | Rebuilt `OrderBook` at a timed interval | `subscribe_order_book_at_interval(instrument_id, interval_ms=1000)` | `on_order_book(order_book)` |
| `InstrumentStatus` | Trading-session/phase status change | `subscribe_instrument_status(instrument_id)` | `on_instrument_status(status)` |
| `InstrumentClose` | End-of-session close/settlement | `subscribe_instrument_close(instrument_id)` | `on_instrument_close(close)` |
| `MarkPriceUpdate` | Venue mark price | `subscribe_mark_prices(instrument_id)` | `on_mark_price(update)` |
| `IndexPriceUpdate` | Underlying index price | `subscribe_index_prices(instrument_id)` | `on_index_price(update)` |
| `FundingRateUpdate` | Perp funding rate | `subscribe_funding_rates(instrument_id)` | `on_funding_rate(update)` |

Custom types subclass `Data` and are delivered via `on_data`. See
[custom-data](custom-data.md).

## BarType and BarSpecification grammar

A `BarType` is built from an `InstrumentId`, a `BarSpecification`
(`step`-`aggregation`-`price_type`), and an **aggregation source**
(`INTERNAL` = Nautilus builds the bar; `EXTERNAL` = the venue/data already provides it).

```python
from nautilus_trader.model import BarType
bar_type = BarType.from_str("AAPL.XNAS-5-MINUTE-LAST-INTERNAL")
```

| Grammar | Format | Examples |
|---|---|---|
| **BarType (standard)** | `{instrument_id}-{step}-{aggregation}-{price_type}-{INTERNAL\|EXTERNAL}` | `AAPL.XNAS-5-MINUTE-LAST-INTERNAL`, `6EH4.XCME-50-VOLUME-LAST-INTERNAL`, `6EH4.XCME-1-MINUTE-ASK-INTERNAL` |
| **BarType (composite / bar-to-bar)** | `{target}-INTERNAL@{step}-{aggregation}-{INTERNAL\|EXTERNAL}` | `AAPL.XNAS-5-MINUTE-LAST-INTERNAL@1-MINUTE-EXTERNAL`, `6EH4.XCME-1-HOUR-LAST-INTERNAL@5-MINUTE-INTERNAL` |
| **BarSpecification** | `{step}-{aggregation}-{price_type}` | `5-MINUTE-LAST`, `100-VOLUME-LAST` |
| **InstrumentId** | `{symbol}.{venue}` | `EUR/USD.SIM`, `AAPL.XNAS`, `BTC/USD.BINANCE`, `6EH4.XCME` |

### Aggregation enum (exact spellings)

| Family | Values |
|---|---|
| **Time** | `MILLISECOND` `SECOND` `MINUTE` `HOUR` `DAY` `WEEK` `MONTH` `YEAR` |
| **Threshold** | `TICK` `VOLUME` `VALUE` `RENKO` |
| **Information** | `TICK_IMBALANCE` `TICK_RUNS` `VOLUME_IMBALANCE` `VOLUME_RUNS` `VALUE_IMBALANCE` `VALUE_RUNS` |

`VALUE` bars aggregate by traded notional (price × size). Information-driven bars
(`*_RUNS`) require `aggressor_side` → build them from **`TradeTick`**, not `QuoteTick`.

### PriceType enum

| Value | Meaning |
|---|---|
| `LAST` | Trade-based (from `TradeTick`) |
| `BID` | Quote bid |
| `ASK` | Quote ask |
| `MID` | Midpoint of bid/ask |

### Time-step divisibility rule

For subunit time aggregations the step must cleanly **divide its parent unit**:
`MILLISECOND` divides 1000, `SECOND`/`MINUTE` divide 60, `HOUR` divides 24,
`MONTH` divides 12. `6EH4.XCME-7-MINUTE-...` is invalid; `-5-MINUTE-` is fine.

### Composite (bar-to-bar) aggregation

`{target}@{source}` builds higher bars from lower ones. The **target (left of `@`)
must be `INTERNAL`** (Nautilus builds it); the **source (right of `@`) may be
`INTERNAL` or `EXTERNAL`**. Example: `AAPL.XNAS-5-MINUTE-LAST-INTERNAL@1-MINUTE-EXTERNAL`
builds 5-minute bars from externally-provided 1-minute bars.

## Subscribing and requesting in strategies/actors

`subscribe_*` = ongoing live stream. `request_*` = one-shot historical batch
delivered to `on_historical_data` (bars also flow to `on_bar` in some paths — the
callback pattern below is the safe way).

| Call | Purpose |
|---|---|
| `subscribe_bars(bar_type)` | Live/streaming bars (instrument must be in cache) |
| `subscribe_quote_ticks(instrument_id)` / `subscribe_trade_ticks(instrument_id)` | Live ticks |
| `subscribe_data(data_type, client_id=None)` | Custom `Data` keyed by `DataType` |
| `request_bars(bar_type, start, callback=None)` | Historical bars; `start` is a **required** positional; `callback` fires after delivery |
| `request_aggregated_bars(bar_types, start)` | Bars aggregated from lower-level data / lower-timeframe bars; `start` required |
| `register_indicator_for_bars(bar_type, indicator)` | Auto-update an indicator from a bar type |
| `publish_data(data_type, data)` / `publish_signal(name, value, ts_event)` | Emit custom data / lightweight signal |
| `subscribe_signal(name)` → `on_signal(signal)` | Named primitive signal (single `int`/`float`/`str` value) |

**Canonical pattern — request history, register indicator first, subscribe from callback:**

```python
def on_start(self) -> None:
    bar_type = BarType.from_str("6EH4.XCME-5-MINUTE-LAST-INTERNAL")
    start = self.clock.utc_now() - timedelta(days=30)
    self.register_indicator_for_bars(bar_type, self.my_indicator)  # BEFORE request
    self.request_bars(
        bar_type,
        start=start,
        callback=lambda _: self.subscribe_bars(bar_type),  # subscribe AFTER delivery
    )

def on_bar(self, bar: Bar) -> None:
    ...
```

Order-book subscription variants and handlers:

```python
self.subscribe_order_book_deltas(instrument_id)            # -> on_order_book_deltas(deltas)
self.subscribe_order_book_depth(instrument_id)             # -> on_order_book_depth(depth)  (top 10)
self.subscribe_order_book_at_interval(instrument_id, interval_ms=1000)  # -> on_order_book(order_book)
```

## DataType (custom-data keying)

```python
from nautilus_trader.model.data import DataType   # DataType(data_cls, metadata: dict | None = None)

self.publish_data(DataType(MyDataPoint, metadata={"category": 1}), MyDataPoint(...))
self.subscribe_data(
    data_type=DataType(MyDataPoint, metadata={"category": 1}),
    client_id=ClientId("MY_ADAPTER"),
)

def on_data(self, data: Data) -> None:
    if isinstance(data, MyDataPoint):
        ...
```

`metadata` is part of the pub/sub key — publisher and subscriber must use the **same**
metadata dict or messages won't route. See [custom-data](custom-data.md) for
serialization (`register_serializable_type`, `register_arrow`, `@customdataclass`).

## Bar aggregation model

- **Time bars** — emitted on wall-clock boundaries. Controlled by `DataEngineConfig`
  (see below). Built `INTERNAL`ly when the venue doesn't supply them.
- **Tick / Volume / Value bars** — threshold-driven; emit when a running count/sum
  crosses `step`. `VALUE` uses traded notional.
- **Information bars** (`TICK_RUNS`/`VOLUME_RUNS`/`VALUE_RUNS`) — need `aggressor_side`;
  source must be `TradeTick`.
- **Composite bars** — `target@source`, target `INTERNAL`, source `INTERNAL`/`EXTERNAL`.

### DataEngineConfig time-bar knobs

| Field | Default | Meaning |
|---|---|---|
| `time_bars_interval_type` | `left-open` | Interval boundary convention |
| `time_bars_timestamp_on_close` | `True` | `True` → bar `ts_event` = close time; `False` → open time |
| `time_bars_skip_first_non_full_bar` | `False` | Skip the first partial bar in a session |
| `time_bars_build_with_no_updates` | `True` | Emit bars even in empty intervals |
| `time_bars_origin_offset` | `None` | Offset the aggregation origin per aggregation |
| `time_bars_build_delay` | `0` | Delay before building a time bar |

## Backtest data config (from a catalog)

```python
from nautilus_trader.config import BacktestDataConfig
from nautilus_trader.model import Bar, InstrumentId

data_config = BacktestDataConfig(
    catalog_path="/path/to/catalog",
    data_cls=Bar,
    instrument_id=InstrumentId.from_str("AAPL.NASDAQ"),
    bar_spec="5-MINUTE-LAST",           # required grammar when data_cls=Bar
    start_time="2024-01-01",
    end_time="2024-01-31",
)
```

Key fields: `catalog_path`, `data_cls` (`QuoteTick`/`TradeTick`/`Bar`/`OrderBookDelta`),
`catalog_fs_protocol` (default `file`), `instrument_id` / `instrument_ids`,
`start_time` / `end_time` (ISO 8601 or UNIX ns), `bar_spec` / `bar_types`,
`filter_expr`, `client_id`, `metadata`. See [backtesting](backtesting.md) and
[data-catalog](data-catalog.md).

## Precision and timestamp semantics

- **Fixed-point** — prices/sizes are `Price`/`Quantity`, not floats. Raw internal
  values must be valid multiples of the scale factor `10^(FIXED_PRECISION - precision)`;
  invalid raw values panic. Always construct via `Price`/`Quantity`, never hand-build
  raw ints. See [value-types](value-types.md).
- **`ts_event`** — when the event occurred at the source venue.
- **`ts_init`** — when the Nautilus object was created/received. **Backtests sort by
  `ts_init`.** Do **not** assume `ts_init >= ts_event` (venue↔local clock skew makes
  ordering between them unreliable — do not use the delta for latency).

## Loader → wrangler pipeline (turning vendor data into Nautilus objects)

```python
from nautilus_trader import TEST_DATA_DIR
from nautilus_trader.adapters.binance.loaders import BinanceOrderBookDeltaDataLoader
from nautilus_trader.persistence.wranglers import OrderBookDeltaDataWrangler
from nautilus_trader.test_kit.providers import TestInstrumentProvider

df = BinanceOrderBookDeltaDataLoader.load(TEST_DATA_DIR / "binance" / "btcusdt-depth-snap.csv")
instrument = TestInstrumentProvider.btcusdt_binance()
wrangler = OrderBookDeltaDataWrangler(instrument)
deltas = wrangler.process(df)   # -> list[OrderBookDelta]
```

Wranglers: `QuoteTickDataWrangler`, `TradeTickDataWrangler`, `BarDataWrangler`,
`OrderBookDeltaDataWrangler` (all v1 / Cython). `OrderBookDepth10DataWranglerV2` is a
v2 (PyO3) wrangler — its objects are **not** interchangeable with v1 objects.

## Gotchas

- **`subscribe_bars()` immediately after `request_bars()`** → with
  `validate_data_sequence=True` the historical response races the live stream. **Fix:**
  pass a `callback` to `request_bars()` and call `subscribe_bars()` from inside it.
- **Registering an indicator after `request_bars()`** → historical bars won't update
  it. **Fix:** `register_indicator_for_bars()` **before** the request.
- **Information bars (`*_RUNS`) from `QuoteTick`** → quotes lack `aggressor_side`.
  **Fix:** use `TradeTick`.
- **Arbitrary time step** → step must divide the parent unit (`MILLISECOND`÷1000,
  `SECOND`/`MINUTE`÷60, `HOUR`÷24, `MONTH`÷12). **Fix:** choose a clean divisor.
- **Non-`INTERNAL` target in composite `target@source`** → the aggregated target must
  be built by Nautilus. **Fix:** target (left of `@`) `INTERNAL`; source may be either.
- **`subscribe_bars()` with the instrument not in cache** → subscription needs the
  instrument. **Fix:** add/load the instrument before subscribing.
- **Assuming bar `ts_event` is always the close time** → only when
  `time_bars_timestamp_on_close=True`; when `False` it's the open time. **Fix:** set it
  explicitly to match your expectation.
- **Assuming `ts_init >= ts_event`** → clock skew breaks this. **Fix:** don't derive
  latency from the delta; rely on `ts_init` for ordering.
- **Mismatched `DataType` metadata between publisher and subscriber** → messages don't
  route (metadata is part of the key). **Fix:** use identical metadata on both sides.
- **Feeding v2 (PyO3) wrangler objects to a `BacktestEngine`** → incompatible with the
  v1 Cython objects it expects. **Fix:** use v1 wranglers for engine input.
- **Omitting `F_LAST` on the final `OrderBookDelta` of an event group (even empty
  Clear-only snapshots)** → buffered consumers accumulate deltas and never publish.
  **Fix:** always set `F_LAST` on the last delta of each logical group.
- **`cache.order_book()` ≠ the PyO3 `OrderBook`** → the v1 Cython book and the
  Rust/PyO3 book have similar-but-not-identical interfaces. **Fix:** verify the method
  set on the object you actually hold.

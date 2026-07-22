# ParquetDataCatalog, Wranglers & Datasets

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/getting_started/backtest_high_level.md
- https://nautilustrader.io/docs/md/latest/getting_started/backtest_low_level.md
- https://nautilustrader.io/docs/md/latest/concepts/data.md

## TL;DR

The pipeline is **loader → DataFrame → wrangler → Nautilus objects → catalog**. A
raw-CSV *loader* (`CSVTickDataLoader`, `BinanceOrderBookDeltaDataLoader`, …) produces a
pandas `DataFrame`; a *wrangler* (`QuoteTickDataWrangler`, `TradeTickDataWrangler`,
`BarDataWrangler`, `OrderBookDeltaDataWrangler`) `.process(df)`-es it into typed Nautilus
`Data` objects (`QuoteTick`, `TradeTick`, `Bar`, `OrderBookDelta`). A
`ParquetDataCatalog` persists those to Parquet-on-disk. **You must write the instrument
into the catalog before (or alongside) writing ticks/bars for it.** In the high-level
backtest API you point a `BacktestDataConfig` at the catalog path; in the low-level API
you `engine.add_data(...)` the wrangled objects directly. See
[backtesting](backtesting.md), [data](data.md), [instruments](instruments.md),
[custom-data](custom-data.md), and the master [SKILL.md](../SKILL.md).

---

## Creating a catalog

```python
from pathlib import Path
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog(CATALOG_PATH)                 # local dir
catalog = ParquetDataCatalog.from_env()                    # NAUTILUS_PATH + "/catalog"
catalog = ParquetDataCatalog.from_uri("s3://bucket/prefix") # remote via fsspec
```

Constructor: `ParquetDataCatalog(path, fs_protocol='file', fs_storage_options=None)`.

| Constructor | Notes |
|---|---|
| `ParquetDataCatalog(path, fs_protocol='file', fs_storage_options=None)` | Local or fsspec remote. `path` may be a `Path` or `str`. |
| `ParquetDataCatalog.from_env()` | Reads `NAUTILUS_PATH` and **appends `/catalog`**. Point `NAUTILUS_PATH` at the *parent*, not the catalog dir itself. |
| `ParquetDataCatalog.from_uri(uri, fs_storage_options=None)` | e.g. `s3://…`; pass credentials/region/endpoint via `fs_storage_options`. |

Typical fresh-catalog setup (from the high-level tutorial):

```python
import shutil
CATALOG_PATH = Path.cwd() / "catalog"
if CATALOG_PATH.exists():
    shutil.rmtree(CATALOG_PATH)   # avoid stale data across runs
CATALOG_PATH.mkdir(parents=True)
catalog = ParquetDataCatalog(CATALOG_PATH)
```

---

## Writing data

```python
catalog.write_data([EURUSD])   # instrument FIRST (as a list)
catalog.write_data(ticks)      # then ticks/bars/deltas
```

Signature: `write_data(data: list[Data], start=None, end=None, data_cls=None, identifier=None, **kwargs) -> None`.
(`skip_disjoint_check=True` is passed via `**kwargs`; `data_cls`/`identifier` are for the empty-data gap-recording case.)

- `data` must be an **iterable** of Nautilus data objects (wrap a single instrument in a list).
- Persist the instrument before (or in the same session as) writing any ticks/bars that
  reference it — the catalog needs the instrument definition on disk.
- By default overlapping time-range writes **raise `ValueError`**. Pass
  `skip_disjoint_check=True` only when the overlap is intentional.

---

## Reading / querying

Two query surfaces exist: the generic `query(...)` and typed convenience accessors.

### Generic query

```python
from nautilus_trader.model import QuoteTick

quotes = catalog.query(
    data_cls=QuoteTick,
    identifiers=["EUR/USD.SIM"],
    start="2024-01-01T00:00:00Z",
    end="2024-01-02T00:00:00Z",
)
```

Signature: `query(data_cls, identifiers=None, start=None, end=None, where=None, files=None, **kwargs) -> list[Data]`.
`start`/`end` accept **ISO 8601 strings, `datetime`/`pd.Timestamp`, or UNIX nanoseconds** (`TimestampLike`). (`filter_expr` is accepted via `**kwargs`.)

### Typed accessors

| Method | Returns |
|---|---|
| `catalog.instruments()` | list of stored instruments |
| `catalog.quote_ticks(instrument_ids, start, end)` | list of `QuoteTick` |
| `catalog.trade_ticks(instrument_ids, start, end)` | list of `TradeTick` |
| `catalog.bars(...)` | list of `Bar` |

The typed accessors delegate straight to `query(...)`, so their `start`/`end` accept the
**same `TimestampLike`** — ISO 8601 strings, `datetime`/`pd.Timestamp`, or UNIX
nanoseconds all work (no manual conversion needed):

```python
ticks = catalog.quote_ticks(
    instrument_ids=[instrument.id.value],
    start="2024-01-01T00:00:00Z",   # ISO string, datetime, pd.Timestamp, or int ns
    end=end_dt,
)
```

---

## Wranglers (DataFrame → Nautilus objects, v1)

```python
from nautilus_trader.persistence.wranglers import (
    QuoteTickDataWrangler,
    TradeTickDataWrangler,
    BarDataWrangler,
    OrderBookDeltaDataWrangler,
)

wrangler = QuoteTickDataWrangler(instrument)
ticks = wrangler.process(df)        # list[QuoteTick]
```

| Wrangler | Construct with | `.process(df)` yields |
|---|---|---|
| `QuoteTickDataWrangler(instrument)` | instrument | `list[QuoteTick]` |
| `TradeTickDataWrangler(instrument=…)` | instrument | `list[TradeTick]` |
| `BarDataWrangler(...)` | bar type + instrument | `list[Bar]` |
| `OrderBookDeltaDataWrangler(instrument)` | instrument | `list[OrderBookDelta]` |

**The DataFrame must be timestamp-sorted before `.process(...)`.** Backtests replay in
strict `ts_init` order; unsorted input breaks determinism.

### Loader → wrangler examples

FX quote ticks from a Histdata CSV (high-level tutorial):

```python
from nautilus_trader.test_kit.providers import CSVTickDataLoader, TestInstrumentProvider

df = CSVTickDataLoader.load(
    file_path=raw_files[0],
    index_col=0, header=None,
    names=["timestamp", "bid_price", "ask_price", "volume"],
    usecols=["timestamp", "bid_price", "ask_price"],
    parse_dates=["timestamp"],
    date_format="%Y%m%d %H%M%S%f",
)
df = df.sort_index()                                  # REQUIRED

EURUSD = TestInstrumentProvider.default_fx_ccy("EUR/USD")
ticks = QuoteTickDataWrangler(EURUSD).process(df)
```

Trade ticks from bundled test data (low-level tutorial):

```python
from nautilus_trader.test_kit.providers import TestDataProvider, TestInstrumentProvider

provider = TestDataProvider()
trades_df = provider.read_csv_ticks("binance/ethusdt-trades.csv")
ETHUSDT_BINANCE = TestInstrumentProvider.ethusdt_binance()
ticks = TradeTickDataWrangler(instrument=ETHUSDT_BINANCE).process(trades_df)
```

Order book deltas via a vendor loader:

```python
from nautilus_trader.adapters.binance.loaders import BinanceOrderBookDeltaDataLoader

df = BinanceOrderBookDeltaDataLoader.load(data_path)
instrument = TestInstrumentProvider.btcusdt_binance()
deltas = OrderBookDeltaDataWrangler(instrument).process(df)
```

### Wrangler v2 (PyO3)

Some v2 wranglers exist (e.g. `OrderBookDepth10DataWranglerV2`). They produce **PyO3**
objects, not the legacy Cython v1 objects.

> Gotcha: **do not add v2/PyO3 wrangler output directly to a `BacktestEngine`** — it
> expects v1 Cython objects. Use v1 wranglers for backtest-engine data, or convert.

---

## Catalog as backtest data source (high-level API)

```python
from nautilus_trader.config import BacktestDataConfig
from nautilus_trader.model import Bar, QuoteTick, InstrumentId

data_config = BacktestDataConfig(
    catalog_path=str(CATALOG_PATH),      # str, NOT a Path object
    data_cls=QuoteTick,
    instrument_id=instrument.id,
    start_time=start_time,
    end_time=end_time,
)
```

Key `BacktestDataConfig` fields:

| Field | Type | Meaning |
|---|---|---|
| `catalog_path` | `str` | Path/URI to the catalog. **Pass `str(...)`, not `Path`.** |
| `data_cls` | `type[Data]` | `QuoteTick`, `TradeTick`, `Bar`, `OrderBookDelta`, or custom. |
| `catalog_fs_protocol` | `str` = `"file"` | fsspec protocol. |
| `catalog_fs_storage_options` | `dict\|None` | Credentials/region/endpoint. |
| `instrument_id` | `InstrumentId\|str\|None` | Single-instrument filter. |
| `instrument_ids` | `list[...]\|None` | Multi-instrument filter. |
| `start_time` / `end_time` | `str\|int\|None` | ISO 8601 or UNIX ns load window. |
| `bar_spec` | `str\|None` | e.g. `"5-MINUTE-LAST"` when `data_cls=Bar`. |
| `bar_types` | `list[str]\|None` | Explicit bar-type strings to load. |
| `filter_expr` | `Any\|None` | Arrow filter expression. |
| `client_id` | `str\|None` | Routing for custom data. |
| `metadata` | `dict\|None` | Keying for custom `DataType`. |

`DataCatalogConfig` (standalone catalog config): `path`, `fs_protocol="file"`,
`fs_storage_options=None`, `name=None`.

Wire into a run (feeds `BacktestNode`):

```python
config = BacktestRunConfig(
    engine=BacktestEngineConfig(strategies=strategies),
    data=[data_config],
    venues=venue_configs,
)
results = BacktestNode(configs=[config]).run()
```

For the low-level API you skip the catalog config and pass wrangled objects straight in:
`engine.add_instrument(inst)` **then** `engine.add_data(ticks)` (instrument first). See
[backtesting](backtesting.md).

---

## On-disk layout & file grammar

The catalog stores each data class/identifier as Parquet files whose names encode the
covered time range.

| Grammar | Format | Example |
|---|---|---|
| Parquet file name | `{start_ts}_{end_ts}.parquet` with ISO 8601 `:` and `.` replaced by `-` | `2024-01-01T00-00-00-000000000Z_2024-01-01T23-59-59-999999999Z.parquet` |

### Maintenance / consolidation

| Method | Purpose |
|---|---|
| `consolidate_catalog(start=None, end=None, ensure_contiguous_files=True, deduplicate=False)` | Merge many small files across the whole catalog. |
| `consolidate_data(data_cls, identifier=None, start=None, end=None)` | Consolidate one class/identifier. |
| `consolidate_catalog_by_period(period: pd.Timedelta, start=None, end=None)` | Merge into fixed-period file boundaries. |
| `consolidate_data_by_period(data_cls, period, identifier=None, start=None, end=None)` | Same, per data class. |
| `delete_catalog_range(start=None, end=None)` | **Permanently** delete a time range (splits partial-overlap files). |
| `delete_data_range(data_cls, identifier=None, start=None, end=None)` | Permanently delete a class's range. |
| `reset_all_file_names()` | Recompute file names from contained time ranges. |
| `reset_data_file_names(data_cls, identifier=None)` | Recompute names for one class/identifier. |

> Deletions are **irreversible**. Partial-overlap files are split to preserve
> out-of-range rows, but the in-range data is gone. Back up or verify first.

---

## Custom-data catalog registration (Arrow)

A custom `Data` subclass must have an Arrow encoder/decoder registered before it can be
written to / read from the Parquet catalog. The easy path is the `@customdataclass`
decorator — it auto-generates `to_dict`/`from_dict`/`to_bytes`/`from_bytes`/`to_arrow`/
`from_arrow` (the schema lives on the `_schema` attribute, not a `schema()` method) **and
registers them for you**: internally the decorator calls both
`register_arrow(cls, cls._schema, cls.to_arrow, cls.from_arrow)` and
`register_serializable_type(cls, cls.to_dict, cls.from_dict)`. A decorated class therefore
persists to a catalog with **no manual registration**:

```python
from nautilus_trader.model.custom import customdataclass
from nautilus_trader.core import Data
from nautilus_trader.model import InstrumentId

@customdataclass
class GreeksTestData(Data):        # name must be globally unique (see gotcha)
    instrument_id: InstrumentId = InstrumentId.from_str("ES.GLBX")
    delta: float = 0.0

catalog = ParquetDataCatalog(".")
catalog.write_data([GreeksTestData()])   # persists with zero extra registration
```

Manual `register_arrow` is only for **hand-rolled** (non-decorated) `Data` classes, where
you supply the schema plus your own encoder/decoder callables:

```python
from nautilus_trader.serialization.arrow.serializer import register_arrow

register_arrow(MyData, MY_SCHEMA, MyData.to_arrow, MyData.from_arrow)
```

Signature: `register_arrow(data_cls, schema, encoder=None, decoder=None, batch_encoder=None) -> None`.

`register_serializable_type(cls, to_dict, from_dict)` (msgpack/dict) covers the bus and
cache only — it is **not** enough for catalog persistence, which goes through the Arrow
encoder/decoder. Any `Data` subclass must expose `ts_event` and `ts_init` (int nanos)
properties. See [custom-data](custom-data.md) for the full pub/sub and serialization story.

> Gotcha: **custom-data class names must be globally unique.** Registration keys on the
> bare class name, and `nautilus_trader.model.greeks_data.GreeksData` ships auto-registered,
> so a `@customdataclass` named `GreeksData` raises `KeyError` at class definition. Pick a
> distinct name.

---

## Streaming / batching large datasets

- The high-level `BacktestNode` streams catalog data in **`ts_init` order**; you don't
  hold all rows in memory the way the low-level engine's `add_data` does.
- Narrow the load window and instrument set via `start_time`/`end_time` and
  `instrument_id(s)` on `BacktestDataConfig`, and push predicate work down with
  `filter_expr` (Arrow) rather than filtering in Python.
- For write/read throughput, keep files disjoint and periodically `consolidate_*` (many
  tiny files hurt scan performance; over-large files hurt range pruning). Use
  `consolidate_*_by_period(pd.Timedelta(...))` to target sensible per-file spans.

---

## Gotchas

- **`catalog_path` needs a `str`, not a `Path`.** → `BacktestDataConfig` expects a string.
  → Wrap: `catalog_path=str(CATALOG_PATH)`.
- **Writing the instrument as a bare object fails.** → `write_data` wants an iterable. →
  `catalog.write_data([EURUSD])`.
- **Writing ticks/bars before the instrument.** → The catalog needs the instrument
  definition on disk to interpret precision/scale. → Write the instrument first.
- **Not sorting the DataFrame before `.process(df)`.** → Backtests replay in strict
  timestamp order and can mis-sequence otherwise. → `df = df.sort_index()` first.
- **Overlapping-range writes raise `ValueError`.** → Default disjoint check protects
  integrity. → Ensure disjoint writes, or pass `skip_disjoint_check=True` deliberately.
- **`from_env()` double-nests the path.** → It appends `/catalog` to `NAUTILUS_PATH`. →
  Set `NAUTILUS_PATH` to the *parent* of the catalog folder, not the folder itself.
- **Registering only `register_serializable_type` and expecting catalog writes to work.**
  → That covers msgpack/dict (bus/cache), not Parquet. → Also `register_arrow(...)` — or use
  `@customdataclass`, which registers both for you.
- **Reusing `GreeksData` as a `@customdataclass` name.** → It collides with the shipped
  auto-registered `GreeksData` and raises `KeyError` at class definition. → Pick a globally
  unique class name.
- **Feeding v2/PyO3 wrangler objects into a `BacktestEngine`.** → It expects v1 Cython
  objects. → Use v1 wranglers for engine data, or convert.
- **Assuming `delete_*_range` is reversible.** → Deletions are permanent. → Back up first.
- **Reusing an old catalog dir across runs.** → Stale rows accumulate. → `shutil.rmtree`
  then `mkdir(parents=True)` before rewriting.
- **Assuming `ts_init >= ts_event`.** → Venue/local clock skew breaks that ordering; only
  `ts_init` sort order is guaranteed for replay. → Don't derive latency from the pair.

# Gotchas: Cross-Cutting Non-Obvious Mistakes

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/overview.md
- https://nautilustrader.io/docs/md/latest/concepts/architecture.md
- https://nautilustrader.io/docs/md/latest/concepts/value_types.md
- https://nautilustrader.io/docs/md/latest/concepts/data.md
- https://nautilustrader.io/docs/md/latest/concepts/custom_data.md
- https://nautilustrader.io/docs/md/latest/concepts/instruments/index.md
- https://nautilustrader.io/docs/md/latest/concepts/strategies.md
- https://nautilustrader.io/docs/md/latest/concepts/actors.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/index.md
- https://nautilustrader.io/docs/md/latest/concepts/execution.md
- https://nautilustrader.io/docs/md/latest/concepts/positions.md
- https://nautilustrader.io/docs/md/latest/concepts/accounting.md
- https://nautilustrader.io/docs/md/latest/concepts/cache.md
- https://nautilustrader.io/docs/md/latest/concepts/message_bus.md
- https://nautilustrader.io/docs/md/latest/concepts/backtesting.md
- https://nautilustrader.io/docs/md/latest/concepts/live.md
- https://nautilustrader.io/docs/md/latest/how_to/configure_live_trading.md

## TL;DR

Most Nautilus bugs are not logic errors — they are **contract violations** the
system deliberately refuses to paper over ("corrupt data is worse than no data").
The recurring themes: (1) build prices/sizes through the *instrument*, not raw
floats; (2) `request_*` and `subscribe_*` deliver to **different handlers**;
(3) do framework work in `on_start`, never `__init__`; (4) precision affects
display but not equality; (5) reverse-indexed caches (index 0 = newest); (6) venue
`book_type` + the data you feed must match or orders never fill; (7) NETTING
position PnL lives in *snapshots*; (8) live failures are often *ambiguous*, not
rejections — reconcile, don't assume. This file is the deduplicated catalog. For
depth on any area follow the per-topic reference linked in each section.

---

## Values / precision → [value-types.md](value-types.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Raw `float`/`int` size or price into `order_factory.*` | Not rounded to the instrument's increment; RiskEngine **denies** rather than rounds | `instrument.make_qty(x)` / `instrument.make_price(x)` |
| Assuming `precision` affects equality | `Price(1.23, 2) == Price(1.230, 3)` is **True**; precision is display/serialization only | Compare by value; use precision for formatting |
| Expecting `Quantity + int/Decimal` → `Quantity` | Numeric-tower promotion: `+int`/`+Decimal` → `Decimal`, `+float` → `float`; `*` `/` `%` and `round()` → `Decimal` even same-type | Re-wrap: `Quantity(result, precision)` |
| Negating a `Quantity` | `Quantity` is unsigned; `-qty` → `Decimal`, and `Quantity(-100)` / underflowing subtraction raise `ValueError` | Guard subtractions ≥ 0; use `Price`/`Money` (signed) for negatives |
| Adding `Money` of different currencies | No implicit FX; `ValueError` | Convert to a common currency first |
| `Money.from_str("1000.00")` | Needs currency | `Money.from_str("1000.00 USD")` (`"<amt> <CCY>"`) |
| Treating precision as fixed at 9 dp | Two build modes: high-precision (128-bit, ≤16 dp, default on Linux/macOS wheels) vs standard (64-bit, ≤9 dp, Windows) | Confirm build mode; align instrument precision |
| Mutating a value type in place | All immutable (that's what makes them hashable) | Reassign the returned new instance |

## Data & bars → [data.md](data.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| `subscribe_bars()` immediately after `request_bars()` | With `validate_data_sequence=True`, live stream races the historical response | Subscribe **inside** the request callback: `request_bars(bt, callback=lambda _: self.subscribe_bars(bt))` |
| Registering an indicator *after* `request_bars` | Historical bars won't update it | `register_indicator_for_bars(...)` **before** `request_bars` |
| `subscribe_bars` without the instrument in cache | Subscription needs the instrument definition loaded | Load/`add_instrument`/request instrument first |
| `request_*` output not showing in `on_bar` | Historical requests route to **`on_historical_data`**; only live subscriptions hit `on_bar`/`on_quote_tick`/... | Handle history in `on_historical_data` (branch on `isinstance(data, Bar)`) |
| Info-driven bars (`*_RUNS`, `*_IMBALANCE`) from quotes | Need `aggressor_side` which quotes lack | Aggregate from `TradeTick` |
| Arbitrary time-bar step | Step must divide its parent unit (MINUTE/SECOND divide 60, HOUR divides 24, MONTH divides 12, MILLISECOND divides 1000) | Choose a cleanly-dividing step |
| Composite (`@`) bar with non-`INTERNAL` target | Target (left of `@`) must be built internally | `AAPL.XNAS-5-MINUTE-LAST-INTERNAL@1-MINUTE-EXTERNAL` |
| Bar DataFrame with naive/non-UTC index | Nautilus timestamps are UTC ns | `pd.date_range(..., tz="UTC")` before `BarDataWrangler` |
| Assuming `ts_init >= ts_event` | Clock skew makes ordering non-guaranteed; backtests sort by **`ts_init`** | Don't compute latency from the pair |
| Assuming bar `ts_event` = close time | Only when `time_bars_timestamp_on_close=True` (default); else it's open time | Set the flag explicitly |
| Omitting `F_LAST` on the final order-book delta (even empty snapshots) | Buffered consumers accumulate forever without publishing | Set `F_LAST` on the last delta of each event group |
| Adding v2 (PyO3) wrangler objects to `BacktestEngine` | Engine expects v1 (legacy Cython) objects | Use v1 wranglers for the engine |

**BarType grammar** — `{InstrumentId}-{step}-{aggregation}-{price_type}-{INTERNAL|EXTERNAL}`
(some docs show `[price_type]` bracket form). Examples:
`EUR/USD.SIM-1-MINUTE-LAST-EXTERNAL`, `ETHUSDT.BINANCE-250-TICK-LAST-INTERNAL`,
`ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-EXTERNAL`. **In config dicts pass the string form**, not a structured object.

## Custom data → [custom-data.md](custom-data.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| `Data` subclass without `ts_event`/`ts_init` | Mandatory; these drive backtest ordering | Implement both properties (or use `@customdataclass`) |
| Registered `register_serializable_type` but expect catalog persistence | That covers msgpack/dict (bus/cache) only | Also `register_arrow(...)` for Parquet |
| Publisher/subscriber `DataType` metadata mismatch | Metadata is part of the pub/sub key | Match `DataType(cls, metadata=...)` on both sides |
| Using `DataType.identifier` for routing | `identifier` affects only storage path; equality/topics derive from `type`+`metadata` | Use `metadata` to differentiate routing |
| Signals carrying complex objects | Signals are single `int`/`float`/`str` only | Use `publish_data` + a custom `Data` class |
| Reading the signal *name* in `on_signal` | Name isn't exposed — only `signal.value` | Encode the discriminator in `value` |

## Instruments → [instruments.md](instruments.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Relying on RiskEngine to round | It does **not** round; a 5-dp price on a 2-dp instrument → order denied | `make_price`/`make_qty` |
| `price_increment` precision ≠ `price_precision` | Venues validate identical rules | `price_precision=2` ⇒ `price_increment=Price(0.01, 2)` |
| Modeling a derivative that "looks like" a pair as `CurrencyPair` | `CurrencyPair` is always Spot, never inverse; wrong cost/settlement currency & no expiry | Use `CryptoPerpetual`/`CryptoFuture`/`FuturesContract`/`OptionContract` |
| Not setting `is_inverse`/`settlement_currency` | Linear vs inverse vs quanto is not inferred | linear: `is_inverse=False`+settle quote; inverse: `is_inverse=True`+settle base; quanto: settle a third ccy |
| Fractional `Equity`/`FuturesContract`/`OptionContract` order | Whole units only (size precision 0); `FuturesContract`/`OptionContract` `min_quantity` default **1** (not None) | Integer quantities |
| Reading negative `maker_fee`/`taker_fee` as a cost | Negative = **rebate** | Treat negatives as rebates |
| Passing datetimes/seconds to `*_ns` fields | They are UnixNanos ints | `pd.Timestamp("YYYY-MM-DD", tz="UTC").value` |
| Assuming native venue symbols are globally unique | Only `{symbol}.{venue}` `InstrumentId` is unique | Always identify by `InstrumentId` |
| Trading a `SyntheticInstrument` directly | Local-only, venue `SYNTH`, no book/margin/fees; ≥2 components; final formula must be numeric | Trade the real components; use synthetic ID only for analysis / `trigger_instrument_id` |

## Strategies / config / actors → [strategies.md](strategies.md), [actors.md](actors.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Using `self.clock`/`self.log`/`self.cache` in `__init__` | Clock/logging/wiring not initialized until **after** registration | Only `super().__init__(config)` + plain state in `__init__`; framework calls in `on_start` |
| Forgetting `super().__init__(config)` | Instance not wired | Call parent ctor first |
| Using an indicator before warm-up | Returns meaningless values | Gate: `if not self.indicators_initialized(): return` |
| Duplicate `strategy_id` / `order_id_tag` across instances | `RuntimeError` at registration | Distinct `order_id_tag` (`"001"`, `"002"`) per instance |
| Not checking `cache.instrument(...)` for None (live) | May not be loaded yet | On None: log + `self.stop()` + return |
| Not cancelling timers in `on_stop` | Timers leak across stop/resume | `self.clock.cancel_timer(name)` for every timer |
| Timer/alert without a callback, expecting a named method | TimeEvent falls back to `on_event` | Pass a callback or handle in `on_event` |
| Storing runtime state back into config | Config is construction data (runtime IDs live on the Rust core) | Read via `self.config`; mutable state as instance attrs |
| `modify_order` with unchanged qty/price/trigger | At least one value must differ | Ensure a real change |
| `modify_order` on an exec-algo-controlled order | Only cancelable once under an algo | Cancel, don't modify |
| `manage_gtd_expiry=True` while exec client submits real GTD | Managed timer conflicts with venue-side expiry | Set `use_gtd=False` on the exec client |

## Orders → [orders.md](orders.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Attaching an unsupported instruction/TIF/option | Nautilus **won't submit** — logs an explanatory error | Verify venue/adapter support first |
| `TimeInForce.GTD` without `expire_time` | GTD needs an expiry timestamp | Pass `expire_time=pd.Timestamp(...)` |
| Expecting `post_only` to sometimes take liquidity | It's a hard maker-only constraint; crossing → rejected | Use only on passive resting limits |
| Expecting `reduce_only` to open/flip a position | Only ever reduces | Use for exits; normal order to open |
| Expecting Market/Stop-Market to fill at a known price | They accept slippage/spread; trigger ≠ fill price | Use Limit / Stop-Limit for a price cap (accepting no-fill risk) |
| Confusing STOP_* with *_IF_TOUCHED | Distinct trigger directions | STOP for breakout/protective, IF_TOUCHED for entering at a touched level |
| `display_qty=None` to hide an order | None = **full** display | Set a smaller `display_qty` for iceberg |
| Keeping a Python ref to an emulated order after release | Object transforms (new type + `OrderInitialized`); ref goes stale | Re-query via `Cache` (client order ID is stable) |
| Assuming an emulated order keeps its submitted type | On release: LIMIT/STOP_MARKET/MIT/TS-market → MARKET; STOP_LIMIT/LIT/TS-limit → LIMIT | Design around the released type |
| Emulating a MARKET / MARKET_TO_LIMIT order | Not emulatable | Only set `emulation_trigger` on emulatable types |
| Ignoring `OrderDenied`/`OrderRejected` on bracket children | A rejected protective leg leaves a position unprotected | Handle both events on contingent orders |
| Assuming default OTO releases children only after full parent fill | Backtest default is **partial-trigger** (pro-rata) | Set venue `oto_trigger_mode="FULL"` if you need full-fill gating |

## Execution / OMS → [execution.md](execution.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Custom `position_id` under NETTING | One position per instrument; engine overrides with `{instrument_id}-{strategy_id}` | Let the engine assign it |
| Assuming HEDGING nets/reopens like NETTING | Each HEDGING position has a unique ID, consumes margin independently, never reopens | Track distinct `PositionId`s |
| Assuming the venue honors requested HEDGING | Some venues net regardless | Verify venue OMS; keep strategy/venue OMS aligned |
| Binance Futures in hedge (LONG/SHORT) mode | Nautilus expects one netting position per instrument | Keep Binance in **BOTH** mode |
| Including `PENDING_CANCEL` when selecting own-book orders to cancel | Re-issues cancels → state explosion | Exclude `PENDING_CANCEL` |
| Passing unvalidated keys in `exec_algorithm_params` | Untyped `dict[str, Any]`, not checked | Validate every key inside the algo |
| Reducing `open_check_threshold_ms`/`inflight_check_threshold_ms` below venue latency | Increases overfill/reconciliation races | Keep thresholds above venue latency |
| Expecting `OrderDenied` to carry venue reject codes | Internal denials set `OrderDenied.reason` — a plain human-readable `str` (e.g. quantity/notional exceeds the configured maximum), **not** an enum; venue rejects pass through | Handle `OrderDenied` vs venue `OrderRejected` separately |

## Positions / accounting / portfolio → [portfolio-and-reports.md](portfolio-and-reports.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Expecting NETTING closed PnL lost on reopen | Engine **snapshots** the closed position before reset; Portfolio sums PnL across snapshots | Include `cache.position_snapshots()` in reports (or use `trader.generate_positions_report()`) |
| Confusing `snapshot_positions` with the reopen snapshot mechanism | `snapshot_positions`/`_interval_secs` is OPEN-position telemetry only | Historical snapshotting preserves PnL automatically |
| `unrealized_pnl` on a FLAT position | Returns `Money(0, settlement_ccy)` regardless of price | Only interpret for open positions |
| Inverse-instrument PnL without `base_currency` | Path panics; quanto not handled | Ensure inverse instruments define `base_currency` |
| `net_exposure()` (singular) across mixed base currencies without `target_currency` | Ambiguous → returns **None** | Pass `target_currency` or use plural `net_exposures()` |
| Assuming a failed FX conversion raises | Singular methods return None + log; plural silently omit the key | Check None / missing keys |
| Assuming all open positions are valued | Unpriceable positions are skipped | `missing_price_instruments(venue)` to detect |
| Assuming one price source | Fallback: mark → side quote (BID long / ASK short) → last trade → recent bar close | Populate at least one source |
| Expecting framework to aggregate multi-currency PnL to one base total | No built-in currency conversion | Aggregate per-currency; supply your own xrates |
| `MarginAccount.apply()` merging margin | It **replaces** both margin stores from the event | Adapters must send every live margin entry each update |
| Expecting `reduce_only` to lock funds/margin | It reduces exposure → contributes nothing to locked/initial margin | Don't count it toward available funds |
| Assuming `StandardMarginModel` is default | Default is **`LeveragedMarginModel`** (÷ leverage) | Call `set_margin_model(StandardMarginModel())` for fixed-% behavior |

## Cache → [message-bus.md](message-bus.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Assuming index 0 is oldest | All market data is **reverse-indexed** | Index 0 = most recent |
| Expecting instant Cache consistency (live) | Updates may lag asynchronously | Tolerate brief lag in handlers |
| `cache.add()` with a Python object | Handles **bytes** only | `pickle.dumps`/`loads` yourself; check None on `get` |
| `purge_instrument()` with working orders/open positions | Refuses unless orders terminal & positions closed | Only purge dependency-free instruments |
| Expecting an auto-loop to purge instruments | Only closed orders/positions/account-events auto-purge (via `LiveExecEngineConfig`) | Call `purge_instrument()` manually |
| Expecting `order_book()` on the quote/trade write path | Book is maintained separately via `BookUpdater` | Use `order_book()`/`book_update_count()` |
| One capacity for all bars | `bar_capacity` is **per bar type** | Size accordingly |

## Backtesting → [backtesting.md](backtesting.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Bars loaded with `ts_init` at OPEN time | `bar_execution=True` expects CLOSE time → look-ahead bias | `bars_timestamp_on_close=True` or `ts_init_delta`=bar duration (e.g. `60_000_000_000` for 1-min) |
| Venue `book_type=L2_MBP/L3_MBO` but feeding only quotes/bars | They don't update the book → orders never fill | Feed matching `OrderBookDelta(s)` |
| Subscribing to book deltas under `L1_MBP` (default) | Deltas ignored by the matcher | Set `book_type` to L2/L3 |
| Expecting a trade tick to fill a same-side order | Trades fill the **opposite** side (a SELL aggressor fills your BUYs) | Reason by aggressor side |
| Expecting book depth to decrement after fills | Historical book is immutable; default `liquidity_consumption=False` lets the same liquidity fill repeatedly | Set `liquidity_consumption=True` |
| `Bar.volume` in quote-currency units | Must be **base**-currency units | Convert before loading |
| `run()` after `add_data(sort=False)` without sorting | Unsorted data → `RuntimeError` | Call `sort_data()` (idempotent) once |
| Sorting on every `add_data` (many instruments) | Compounds; slow | `add_data(sort=False)` per call, then one `sort_data()` |
| Precision mismatch data vs instrument | Validated against `price_precision`/`size_precision` → `RuntimeError` | Align via `make_price`/`make_qty` |
| Reports after `dispose()` | In-memory state gone | Generate reports after `run()`, before `dispose()` |
| Assuming `engine.reset()` clears everything | Instruments/data/components persist; only internal state resets | `clear_strategies()`/`clear_data()` as needed |
| Adding instrument/data before the venue | Engine needs venue+account to route | `add_venue` → `add_instrument` → `add_data` → `add_strategy` |
| Passing `instrument` where `instrument_id` expected (or vice versa) | `add_instrument(EURUSD)` vs config `instrument_id=EURUSD.id` | Use the right one |
| Expecting fixed OHLC ordering to reflect intrabar path | Default O→H→L→C regardless of real movement (affects TP-vs-SL) | `bar_adaptive_high_low_ordering=True` (~75–85% vs ~50%) |
| Relying on strategy fill handlers during shutdown | Post-shutdown fills in `on_stop` don't fire handlers | Run fill-reactive logic before `on_stop` returns |
| `str` vs `Path` for `catalog_path` | Expects a string | `str(CATALOG_PATH)` |
| Reusing a catalog dir across runs | Stale data accumulates | `shutil.rmtree` then `mkdir` |

## Catalog / custom data persistence → [data-catalog.md](data-catalog.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Overlapping-time-range writes | Raise `ValueError` to protect integrity | Disjoint writes, or `skip_disjoint_check=True` when intentional |
| `NAUTILUS_PATH` pointed at the catalog dir | `from_env()` appends `/catalog` | Point at the **parent** dir |
| `delete_*_range` assumed reversible | Permanent; partial-overlap files are split | Back up / verify ranges first |
| `catalog.write_data(EURUSD)` bare | Expects an iterable | `write_data([EURUSD])` |
| Writing market data before instrument definitions | Catalog needs instruments present + precision resolution | Write instruments first, then data |

## Live → [live-trading.md](live-trading.md)

| Pitfall | Why it bites | Correct |
|---|---|---|
| Assuming a failed command yields a rejection event | Only *definitive* outcomes emit `OrderRejected/ModifyRejected/CancelRejected`; transport errors/timeouts/disconnects leave orders **in-flight** | Treat ambiguous failures as unresolved; rely on WS updates + reconciliation |
| Assuming a locally denied order reached the venue | `OrderDenied` emits **without** `OrderSubmitted` | Handle as a pre-submission local reject |
| Setting `reconciliation_lookback_mins` small | Older executions still align but with info loss; some venues drop old data | Leave unset (max venue history) + persist all events to cache DB |
| Multiple strategies each caching positions for one account+instrument | Venue reports one **net** account position | Account for account-level netting when partitioning |
| Blocking the event loop (inference, sync I/O, heavy calc in callbacks) | Missed fills, stale data, delayed submits | Offload to executors/threads; keep callbacks fast |
| Multiple `TradingNode`/`BacktestNode` per process | Global singleton state collides | **One node per process**; many strategies in one node; run nodes sequentially |
| Running a live node in Jupyter | Event-loop conflicts, no prod monitoring | Standalone script |
| Relying on OS signal handlers on Windows | Windows asyncio lacks `add_signal_handler` | `try: node.run() except KeyboardInterrupt: pass finally: node.stop(); node.dispose()` |
| Assuming continuous open/position checks run by default | `open_check_interval_secs`/`position_check_interval_secs` default **None** (disabled) | Set intervals explicitly |
| Leaving memory purging off in long-running nodes | All `purge_*` intervals default None → unbounded growth | Set intervals+buffers; `purge_from_database=True` to also trim the DB |
| Confusing VENUE vs RECONCILIATION order tags | VENUE = external order found at venue; RECONCILIATION = system-generated to align positions | Treat accordingly |
| Expecting `PositionStatusReport` to bootstrap positions | Positions derive from fills; it's logged only | Rely on `FillReport`/`OrderStatusReport`/`OrderWithFills` |

## Logging → [architecture.md](architecture.md)

- `init_logging()` **once per process**; running multiple sequential engines requires
  holding the first `engine.get_log_guard()` alive (up to 255 guards).
- `log_components_only=True` with an **empty** `log_component_levels` emits **no logs**.
- `log_level` (stdout) and `log_level_file` (file) are independent — set both.
- TRACE is Rust-only; use DEBUG for Python diagnostics.
- Setting a custom `log_file_name` disables daily rotation unless you also set `log_file_max_size`.

## Install / environment

- Python **3.12–3.14** only (64-bit). Use `uv`, not Conda.
- Use `--extra-index-url` (not `--index-url`) to keep PyPI fallback for transitive deps.
- Windows wheels are standard-precision (no `__int128`); Linux/macOS wheels are high-precision.
- Dev/nightly (`--pre`) wheels are for testing, never live capital.

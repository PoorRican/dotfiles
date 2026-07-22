# Live Trading: TradingNode, Reconciliation, Adapters

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/live.md
- https://nautilustrader.io/docs/md/latest/how_to/configure_live_trading.md
- https://nautilustrader.io/docs/md/latest/concepts/adapters.md
- https://nautilustrader.io/docs/md/latest/integrations/index.md

## TL;DR

A live deployment runs a single `TradingNode` (one per process) configured with a
`TradingNodeConfig`. The node composes the same engines used in backtesting plus
per-venue **data clients** and **execution clients**. **The strategy code is
byte-for-byte identical to backtest** — the same `Strategy`/`Actor` subclasses,
the same `on_*` handlers, the same `subscribe_*`/`request_*`/order-command calls.
What changes is the runtime: live adapters (REST + WebSocket) feed real venues,
and the `LiveExecutionEngine` performs **reconciliation** — aligning the system's
internal event-sourced state with venue truth at startup and continuously
thereafter. You wire an adapter by registering its **client factory** on the node
before `node.build()`, then `node.run()`. See [backtesting.md](backtesting.md) for
the offline counterpart, [strategies.md](strategies.md) for strategy code, and
[execution.md](execution.md) for order lifecycle.

## Same code as backtest

The strategy/actor classes, their config classes, and all order/subscription
calls are unchanged from backtest to live. Only the *node wiring* differs:

| Concern | Backtest | Live |
|---|---|---|
| Container | `BacktestNode` / `BacktestEngine` | `TradingNode` |
| Config | `BacktestRunConfig` | `TradingNodeConfig` |
| Data source | catalog / added data | live data clients (adapters) |
| Execution | simulated matching engine | live exec clients + reconciliation |
| Strategy code | **identical** | **identical** |

Do not fork strategy logic for live. Keep venue/auth differences in config.

## TradingNodeConfig

```python
from nautilus_trader.config import TradingNodeConfig
from nautilus_trader.config import CacheConfig, MessageBusConfig
from nautilus_trader.config import LiveDataEngineConfig, LiveRiskEngineConfig, LiveExecEngineConfig
from nautilus_trader.adapters.binance import BinanceDataClientConfig, BinanceExecClientConfig

config = TradingNodeConfig(
    trader_id="MyTrader-001",
    cache=CacheConfig(),
    message_bus=MessageBusConfig(),
    data_engine=LiveDataEngineConfig(),
    risk_engine=LiveRiskEngineConfig(),
    exec_engine=LiveExecEngineConfig(),
    data_clients={"BINANCE": BinanceDataClientConfig()},
    exec_clients={"BINANCE": BinanceExecClientConfig()},
)
```

`TradingNodeConfig` inherits `NautilusKernelConfig` and composes every
engine/client config. Signature (defaults shown):

```
TradingNodeConfig(
    trader_id='TRADER-001', instance_id=None,
    timeout_connection=60.0, timeout_reconciliation=30.0, timeout_portfolio=10.0,
    timeout_disconnection=10.0, timeout_post_stop=10.0,
    cache=..., message_bus=..., data_engine=..., risk_engine=..., exec_engine=...,
    portfolio=..., data_clients={}, exec_clients={})
```

| Field | Type | Default | Meaning |
|---|---|---|---|
| `trader_id` | str | `TRADER-001` | Unique trader identifier |
| `instance_id` | Optional | None | Optional unique instance id |
| `timeout_connection` | float | 60.0 | Client connection timeout (s) |
| `timeout_reconciliation` | float | 30.0 | Reconciliation timeout (s) |
| `timeout_portfolio` | float | 10.0 | Portfolio init timeout (s) |
| `timeout_disconnection` | float | 10.0 | Disconnection timeout (s) |
| `timeout_post_stop` | float | 10.0 | Post-stop cleanup timeout (s) |
| `data_clients` | dict | `{}` | Data client configs keyed by venue string |
| `exec_clients` | dict | `{}` | Execution client configs keyed by venue string |

`data_clients` / `exec_clients` keys are venue strings (e.g. `"BINANCE"`) or the
adapter's exported key constant (e.g. `DATABENTO`). Values should be the adapter's
**typed** config object (e.g. `DatabentoDataClientConfig`). A plain dict is decoded
against the base `LiveDataClientConfig`/`LiveExecClientConfig` and so can only carry
base fields — adapter-specific keys like `api_key` raise `unknown field`.

## Running the node

```python
from nautilus_trader.live.node import TradingNode

node = TradingNode(config=config)

# Register adapter factories BEFORE build()
node.add_data_client_factory(DATABENTO, DatabentoLiveDataClientFactory)
# node.add_exec_client_factory(VENUE, SomeLiveExecClientFactory)  # for exchanges

node.build()

try:
    node.run()
except KeyboardInterrupt:
    pass
finally:
    try:
        node.stop()
    finally:
        node.dispose()
```

- `node.build()` — constructs engines/clients from config; call **after** all
  factory registrations.
- `node.run()` — starts the event loop (blocking).
- `node.stop()` — graceful stop. `node.dispose()` — release resources after stop.
- `self.shutdown_system(reason=None)` — a **component** method (on `Actor`/`Strategy`,
  not on `TradingNode`); call it from strategy/actor code to issue a programmatic
  shutdown command from within the running system.

The try/except/finally lifecycle above is **required on Windows**, whose asyncio
loops lack `loop.add_signal_handler`; catch `KeyboardInterrupt`, then always
`stop()` then `dispose()`.

## Adding adapter data/exec client factories

An adapter integrates a venue via five components: `HttpClient` (REST),
`WebSocketClient` (streaming), `InstrumentProvider` (loads/parses venue
instrument defs into Nautilus `Instrument` objects), `DataClient` (market-data
subscriptions/requests), and `ExecutionClient` (order submit/modify/cancel).

Wiring pattern (Databento, market-data only):

```python
from nautilus_trader.adapters.databento import DATABENTO
from nautilus_trader.adapters.databento.config import DatabentoDataClientConfig
from nautilus_trader.adapters.databento.factories import DatabentoLiveDataClientFactory
from nautilus_trader.config import InstrumentProviderConfig, TradingNodeConfig
from nautilus_trader.live.node import TradingNode
from nautilus_trader.model.identifiers import InstrumentId

instrument_ids = [InstrumentId.from_str("ESZ6.XCME")]

config = TradingNodeConfig(
    data_clients={
        DATABENTO: DatabentoDataClientConfig(
            api_key=None,  # falls back to DATABENTO_API_KEY env var
            instrument_provider=InstrumentProviderConfig(
                load_ids=frozenset(instrument_ids),
            ),
            instrument_ids=instrument_ids,
            parent_symbols={"GLBX.MDP3": {"ES.FUT"}},
            use_exchange_as_venue=True,
        ),
    },
)

node = TradingNode(config=config)
node.add_data_client_factory(DATABENTO, DatabentoLiveDataClientFactory)
node.build()
```

Always register the factory **before** `node.build()`.

### InstrumentProvider loading

Instruments must be in the cache before subscribing. Configure loading on the
adapter's client config:

```python
from nautilus_trader.config import InstrumentProviderConfig

InstrumentProviderConfig(load_all=True)
# or
InstrumentProviderConfig(load_ids=["BTCUSDT-PERP.BINANCE", "ETHUSDT-PERP.BINANCE"])
```

| Field | Type | Meaning |
|---|---|---|
| `load_all` | bool | Load all venue instruments at start |
| `load_ids` | list[str] | Load only these `InstrumentId` strings |

Some adapters (e.g. Databento) prefer `load_ids` (as a `frozenset`) over
`load_all=True`. See [instruments.md](instruments.md).

### Standalone instrument discovery (no node)

`InstrumentProvider`s can run outside a node for research/backtest discovery:

```python
import asyncio, os
from nautilus_trader.adapters.binance.common.enums import BinanceAccountType, BinanceEnvironment
from nautilus_trader.adapters.binance import get_cached_binance_http_client
from nautilus_trader.adapters.binance.futures.providers import BinanceFuturesInstrumentProvider
from nautilus_trader.common.component import LiveClock

async def main():
    clock = LiveClock()
    client = get_cached_binance_http_client(
        clock=clock,
        account_type=BinanceAccountType.USDT_FUTURES,
        api_key=os.getenv("BINANCE_FUTURES_TESTNET_API_KEY"),
        api_secret=os.getenv("BINANCE_FUTURES_TESTNET_API_SECRET"),
        environment=BinanceEnvironment.TESTNET,
    )
    provider = BinanceFuturesInstrumentProvider(client=client, clock=clock, account_type=BinanceAccountType.USDT_FUTURES)
    await provider.load_all_async()
    print(f"Loaded {len(provider.list_all())} instruments")

if __name__ == "__main__":
    asyncio.run(main())
```

`load_all_async()` is a coroutine; run inside `asyncio.run(...)`.

### Environment / auth

Adapters read secrets from config fields or environment variables. Prefer env
vars over hard-coded keys. Examples:

- Databento: `api_key=None` → `DATABENTO_API_KEY`.
- Binance: `api_key` / `api_secret`; `environment` selects `TESTNET` vs live.

## Reconciliation (LiveExecutionEngine)

The `LiveExecutionEngine` is the **only** engine that reconciles. At startup (and
continuously when configured) it compares venue state against the internal
event-sourced state and generates missing `OrderFilled` events plus
external/reconciliation orders to close gaps. It pulls venue state via three
adapter execution-client methods:

- `generate_order_status_reports()` — venue order-state reports.
- `generate_fill_reports()` — execution/trade (fill) reports.
- `generate_position_status_reports()` — account position reports.

Reconciliation orders carry tags: **`VENUE`** marks external orders discovered at
the venue (placed outside this system); **`RECONCILIATION`** marks synthetic
orders the engine generates to align position discrepancies.

### LiveExecEngineConfig — key fields

```
LiveExecEngineConfig(reconciliation=True, ...)
```

| Field | Type | Default | Meaning |
|---|---|---|---|
| `reconciliation` | bool | True | Enable startup reconciliation with venues |
| `reconciliation_lookback_mins` | Optional int | None | History depth to request; **unset = request max the venue provides** |
| `reconciliation_instrument_ids` | Optional | None | Restrict reconciliation to these instruments |
| `reconciliation_startup_delay_secs` | float | 10.0 | Stabilization delay after startup before continuous checks run |
| `filtered_client_order_ids` | Optional | None | Client order IDs to skip during reconciliation |
| `filter_unclaimed_external_orders` | bool | False | Drop external orders no strategy claimed |
| `filter_position_reports` | bool | False | Drop venue position reports |
| `generate_missing_orders` | bool | True | Synthesize orders (LIMIT preferred, MARKET last resort) to align positions |
| `allow_overfills` | bool | False | Allow fills exceeding order quantity |
| `inflight_check_interval_ms` | int | 2000 | Frequency of in-flight order checks |
| `inflight_check_threshold_ms` | int | 5000 | Age before an in-flight order is queried at the venue |
| `inflight_check_retries` | int | 5 | Retries before a never-acked SUBMITTED order resolves to REJECTED |
| `open_check_interval_secs` | Optional | **None (disabled)** | Frequency of continuous open-order checks |
| `open_check_open_only` | bool | True | Query only open orders (can't distinguish missing vs recently-closed) |
| `open_check_lookback_mins` | int | 60 | Lookback window for open-order queries |
| `open_check_threshold_ms` | int | 5000 | Recent-order protection window; skip reconciliation for orders whose last event is inside it |
| `open_check_missing_retries` | int | 5 | Retries for missing-order detection |
| `max_single_order_queries_per_cycle` | int | 10 | Cap on targeted single-order queries per cycle |
| `single_order_query_delay_ms` | int | 100 | Spacing between single-order queries |
| `position_check_interval_secs` | Optional | **None (disabled)** | Frequency of continuous position checks |
| `position_check_lookback_mins` | int | 60 | Lookback for position fill queries |
| `position_check_threshold_ms` | int | 5000 | Discrepancy threshold before action |
| `position_check_retries` | int | 3 | Retries before stopping reconciliation |
| `graceful_shutdown_on_exception` | bool | False | Graceful shutdown on queue/processing exceptions |
| `qsize` | int | 100000 | Internal queue buffer size |
| `debug` | bool | False | Exec-engine debug logging |

**Continuous open-order and position checks are OFF by default** — set
`open_check_interval_secs` and `position_check_interval_secs` to enable them.

### Memory purging (long-running nodes)

Closed orders/positions/account events accumulate unbounded; **all purge fields
default to `None` (off)**. Enable them for long-lived nodes:

| Field | Meaning |
|---|---|
| `purge_closed_orders_interval_mins` | How often to purge closed orders |
| `purge_closed_orders_buffer_mins` | Min age before a closed order is purged |
| `purge_closed_positions_interval_mins` | How often to purge closed positions |
| `purge_closed_positions_buffer_mins` | Min age before a closed position is purged |
| `purge_account_events_interval_mins` | How often to purge account events |
| `purge_account_events_lookback_mins` | Age threshold for purging account events |
| `purge_from_database` | bool (default False) — also delete from backing DB, not just memory |

```python
LiveExecEngineConfig(
    purge_closed_orders_interval_mins=10,
    purge_closed_orders_buffer_mins=60,
    purge_from_database=True,
)
```

### External orders & strategy claims

Orders discovered via reconciliation that no strategy claims keep strategy ID
`EXTERNAL` but still participate in portfolio/position calculations. A strategy
claims external activity for an instrument via `StrategyConfig.external_order_claims`.

```python
def on_order_event(self, event):
    if event.strategy_id.value == "EXTERNAL":
        ...  # order discovered via reconciliation, unclaimed
```

## Order command outcomes (live semantics)

A failed order command does **not** always yield a rejection event:

| Outcome | Event | Meaning |
|---|---|---|
| Venue confirms rejection | `OrderRejected` / `OrderModifyRejected` / `OrderCancelRejected` | Definitive venue/API rejection |
| Local pre-submission denial | `OrderDenied` | Blocked locally; **no `OrderSubmitted` ever emitted**, never reached venue |
| Fill | `OrderFilled` | Includes inferred/synthetic fills from reconciliation |
| Ambiguous failure | *(none — stays in-flight)* | Transport error, WebSocket failure, timeout, disconnect, parse/batch failure, rate limit → awaits reconciliation |

Treat ambiguous failures as unresolved; rely on WebSocket updates and
reconciliation to settle final state.

## Production safety

- **Error-driven shutdown:** `LiveExecEngineConfig(graceful_shutdown_on_exception=True)`
  (default False) makes the live execution engine follow the normal graceful stop
  path when its queue/processing loop hits an unhandled exception, instead of
  leaving the node running in a degraded state. (There is no node-level
  `shutdown_on_error` knob and no `LiveNodeConfig` type.)

  ```python
  from nautilus_trader.config import LiveExecEngineConfig
  exec_engine = LiveExecEngineConfig(graceful_shutdown_on_exception=True)
  ```

- **Risk engine limits:** configure `LiveRiskEngineConfig` (rate/notional caps,
  pre-trade denials). Orders violating limits are denied locally (`OrderDenied`).
  See [execution.md](execution.md) for the risk-engine denial path.

- **Heartbeats:** `MessageBusConfig(heartbeat_interval_secs=...)` emits periodic
  bus heartbeats.

- **Timeouts:** the `timeout_*` fields on `TradingNodeConfig` bound
  connection/reconciliation/portfolio/disconnection/post-stop phases.

- **Cache / message-bus persistence:** back the cache with a database via
  `CacheConfig(database=DatabaseConfig(type="redis", host=..., port=...))` (the same
  `database=` knob exists on `MessageBusConfig`) so execution events survive
  restarts. Persist **all** execution events to the cache DB so recovery does not
  depend on venue history. `MessageBusConfig` supports `stream_per_topic`,
  `autotrim_mins`, `types_filter`. See [message-bus.md](message-bus.md).

## Available integrations

Adapters supply an `InstrumentProvider`, a `DataClient`, and (for exchanges) an
`ExecutionClient`, wired into a `TradingNode` via a client factory. Common
integrations: **Binance, Bybit, Interactive Brokers (IB), Databento, Coinbase
(International), OKX, Polymarket, dYdX, Hyperliquid, Tardis**. Coverage varies —
some are market-data only (e.g. **Databento** is a `LiveMarketDataClient`, no
execution). Adapters carry a **status** (e.g. stable vs beta); check the
integrations index for the current per-adapter status and supported
capabilities/instrument classes before relying on one in production.

Normalization guarantees across adapters: UNIX epoch-**nanosecond** timestamps,
venue-native symbols, and `_ms`-suffixed millisecond fields — so strategies port
across venues unchanged.

## Requesting / subscribing from a strategy (adapter I/O)

`request_*` delivers one-shot historical/definition data; `subscribe_*` streams
live data. They route to **different** handlers:

```python
class MyStrategy(Strategy):
    def on_start(self) -> None:
        self.request_instrument(InstrumentId.from_str("BTCUSDT-PERP.BINANCE"))     # -> on_instrument
        self.request_bars(BarType.from_str("BTCUSDT-PERP.BINANCE-1-HOUR-LAST-EXTERNAL"))  # -> on_historical_data
        self.subscribe_trade_ticks(InstrumentId.from_str("BTCUSDT-PERP.BINANCE"))  # -> on_trade_tick
        self.subscribe_bars(BarType.from_str("BTCUSDT-PERP.BINANCE-1-MINUTE-LAST-EXTERNAL"))  # -> on_bar
```

Routing map: `request_instrument` → `on_instrument`, `request_bars` →
`on_historical_data`, `subscribe_trade_ticks` → `on_trade_tick`,
`subscribe_bars` → `on_bar`. Some adapters accept a `client_id=` (e.g.
`DATABENTO_CLIENT_ID`) and `params=` (e.g. schema selection). See [data.md](data.md).

### String grammars

| Name | Format | Examples |
|---|---|---|
| `InstrumentId` | `{symbol}.{VENUE}` | `BTCUSDT-PERP.BINANCE`, `ESZ6.XCME`, `AAPL.XNAS` |
| `BarType` | `{InstrumentId}-{step}-{aggregation}-{price_type}-{source}` | `BTCUSDT-PERP.BINANCE-1-HOUR-LAST-EXTERNAL`, `AAPL.XNAS-1-MINUTE-LAST-EXTERNAL` |

## Gotchas

- **One `TradingNode` per process.** Global singleton state makes multiple nodes
  in one process conflict. Add multiple strategies to one node, or run additional
  nodes in separate processes.

- **Never run a live node in Jupyter.** Event-loop conflicts, operational risk,
  and no production monitoring. Run live from a standalone Python script.

- **Never block the event loop.** Model inference, heavy compute, or synchronous
  I/O in `on_*` callbacks causes missed fills, stale data, and delayed
  submissions. Offload long work to executors/threads; keep callbacks fast.

- **Register factories before `node.build()`.** `add_data_client_factory` /
  `add_exec_client_factory` must run before `build()`, or the client won't exist.

- **Subscribe only after the instrument is in the cache.** Configure the
  `InstrumentProvider` (`load_all`/`load_ids`) or call `request_instrument` and
  wait for it to land before `subscribe_*`, else the subscription can't process.

- **Continuous checks default OFF.** `open_check_interval_secs` and
  `position_check_interval_secs` default to `None` (disabled). Set them
  explicitly for continuous open-order/position reconciliation.

- **Don't shrink `reconciliation_lookback_mins` to "limit history."** Older
  executions still generate alignment events but with information loss, and some
  venues drop old data. Leave it unset (request max history) and persist all exec
  events to the cache DB.

- **Don't shrink `open_check_lookback_mins` below 60.** Short windows trigger
  false "missing order" detections. Keep it ≥ 60.

- **`OrderDenied` ≠ venue rejection.** A local denial never emits
  `OrderSubmitted` and never reaches the venue. Handle it as a distinct
  pre-submission outcome.

- **A failed command may not emit any rejection.** Ambiguous failures (timeouts,
  disconnects, rate limits) leave orders in-flight; rely on reconciliation, not
  an assumed `OrderRejected`.

- **`VENUE` vs `RECONCILIATION` tags differ.** `VENUE` = external order placed
  outside the system; `RECONCILIATION` = synthetic alignment order the engine
  generated internally.

- **Expect LIMIT, not MARKET, reconciliation orders.** With
  `generate_missing_orders=True`, the engine prefers LIMIT (price hierarchy:
  calculated reconciliation price → market mid → position average → MARKET only as
  last resort) to preserve PnL accuracy.

- **Fills can precede their order status report.** The engine defers early fills
  until order state exists — don't assume fill ordering.

- **Multiple strategies netting the same account+instrument misalign.** Venues
  report a single account-level net position; per-strategy cached positions can
  diverge during reconciliation. Partition positions accounting for
  account-level netting.

- **Enable memory purging on long-running nodes.** All `purge_*` intervals
  default to `None`; closed orders/positions/account events accumulate unbounded.
  Set intervals + buffers; set `purge_from_database=True` to also clear the DB.

- **Windows has no signal handlers.** Wrap `node.run()` in
  `try/except KeyboardInterrupt` with a `finally` that calls `node.stop()` then
  `node.dispose()`.

See also: [architecture.md](architecture.md) · [backtesting.md](backtesting.md) ·
[execution.md](execution.md) · [strategies.md](strategies.md) ·
[gotchas.md](gotchas.md) · [SKILL.md](../SKILL.md).

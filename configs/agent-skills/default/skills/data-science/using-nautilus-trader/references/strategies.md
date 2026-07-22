# Strategy: Class, Config, Handlers & Lifecycle

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/strategies.md

## TL;DR

`Strategy` is the core user-facing component for trading logic. It **inherits from `Actor`** (see [actors](actors.md)) and adds order management, position tracking, and portfolio access on top of Actor's data handling. Strategies are **event-driven**: you override `on_*` handlers for lifecycle, data, order events, and position events. Each strategy is parameterized by a `StrategyConfig` subclass exposed at runtime via `self.config`. **The same strategy source runs unchanged in backtest and live.** Do not touch framework components (`self.clock`, `self.log`, cache) in `__init__` — only in `on_start` and later; the clock/logging subsystems are wired only *after* registration.

## Strategy + StrategyConfig pattern

Config classes are typed subclasses of `StrategyConfig`, which is a **frozen `msgspec.Struct`** (NOT Pydantic). Fields with no default are required. Config is injected at construction and exposed via `self.config` after `super().__init__(config)`.

**Subclassing rule (msgspec ordering):** a required field cannot follow a field with a default. `StrategyConfig` already declares defaulted fields, and configs commonly mix defaulted and required user fields (as below) — so declare the subclass `kw_only=True` to lift the ordering constraint. Without it, msgspec raises `TypeError: Required field '...' cannot follow optional fields` at class definition. Canonical form: `class MyConfig(StrategyConfig, kw_only=True, frozen=True): ...`.

```python
from decimal import Decimal
from nautilus_trader.config import StrategyConfig
from nautilus_trader.model import Bar, BarType, InstrumentId
from nautilus_trader.trading.strategy import Strategy


class MyStrategyConfig(StrategyConfig, kw_only=True, frozen=True):
    instrument_id: InstrumentId   # e.g. "ETHUSDT-PERP.BINANCE"
    bar_type: BarType             # e.g. "ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-EXTERNAL"
    fast_ema_period: int = 10
    slow_ema_period: int = 20
    trade_size: Decimal
    order_id_tag: str


class MyStrategy(Strategy):
    def __init__(self, config: MyStrategyConfig) -> None:
        super().__init__(config)          # MANDATORY, first line
        self.time_started = None          # plain state only in __init__
        self.count_of_processed_bars: int = 0

    def on_start(self) -> None:
        self.time_started = self.clock.utc_now()
        self.subscribe_bars(self.config.bar_type)

    def on_bar(self, bar: Bar):
        self.count_of_processed_bars += 1


config = MyStrategyConfig(
    instrument_id=InstrumentId.from_str("ETHUSDT-PERP.BINANCE"),
    bar_type=BarType.from_str("ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-EXTERNAL"),
    trade_size=Decimal(1),
    order_id_tag="001",
)
strategy = MyStrategy(config=config)
```

A no-arg skeleton is legal (`super().__init__()`), but the config-driven form above is canonical. For serialization/wiring across a `TradingNode` or `BacktestNode`, use `ImportableStrategyConfig` (see [live-trading](live-trading.md), [backtesting](backtesting.md)).

### Built-in StrategyConfig fields

| Field | Type | Default | Meaning |
|---|---|---|---|
| `order_id_tag` | `str` | next numeric tag from `'000'` | Suffix ensuring unique client order IDs; combined with class name to form strategy ID (tag `'001'` → `MyStrategy-001`). |
| `strategy_id` | `StrategyId \| str` | class name + `order_id_tag` | Unique instance identifier. **Duplicate IDs raise `RuntimeError` at registration.** |
| `manage_stop` | `bool` | `False` | When `True`, `stop()` auto-performs a market exit before stopping. |
| `market_exit_interval_ms` | `int` | `100` | ms between market-exit order attempts. |
| `market_exit_max_attempts` | `int` | `100` | Max market-exit attempts. |
| `market_exit_time_in_force` | `TimeInForce` | `TimeInForce.GTC` | TIF applied to market-exit orders. |
| `market_exit_reduce_only` | `bool` | `True` | Whether market-exit orders are reduce-only. |
| `manage_gtd_expiry` | `bool` | `False` | Strategy manages GTD expiry via internal time alert for venues lacking native GTD. |

(`instrument_id`, `bar_type`, `trade_size`, `fast_ema_period`, `slow_ema_period` above are *example* user fields, not built-ins.)

## Handler / hook catalog

Override only what you need; all default to no-ops.

### Lifecycle hooks

| Handler | Signature | Fires on |
|---|---|---|
| `on_start` | `(self) -> None` | Start: load instruments, register indicators, request/subscribe data. |
| `on_stop` | `(self) -> None` | Stop: cleanup, cancel orders. |
| `on_resume` | `(self) -> None` | Resume from stopped. |
| `on_reset` | `(self) -> None` | Reset: clear state. |
| `on_dispose` | `(self) -> None` | Final teardown. |
| `on_degrade` | `(self) -> None` | Component degrades. |
| `on_fault` | `(self) -> None` | Component faults. |
| `on_save` | `(self) -> dict[str, bytes]` | Return user state for persistence. |
| `on_load` | `(self, state: dict[str, bytes]) -> None` | Restore state saved by `on_save`. |

### Data handlers

| Handler | Signature |
|---|---|
| `on_bar` | `(self, bar: Bar) -> None` |
| `on_quote_tick` | `(self, tick: QuoteTick) -> None` |
| `on_trade_tick` | `(self, tick: TradeTick) -> None` |
| `on_order_book_deltas` | `(self, deltas: OrderBookDeltas) -> None` |
| `on_order_book` | `(self, order_book: OrderBook) -> None` |
| `on_instrument` | `(self, instrument: Instrument) -> None` |
| `on_data` | `(self, data: Data) -> None` — generic/custom data (see [custom-data](custom-data.md)) |
| `on_signal` | `(self, signal: Data) -> None` — signal Data object |

### Order & position event handlers

| Handler | Signature |
|---|---|
| `on_order_accepted` | `(self, event: OrderAccepted) -> None` |
| `on_order_rejected` | `(self, event: OrderRejected) -> None` |
| `on_order_filled` | `(self, event: OrderFilled) -> None` |
| `on_order_event` | `(self, event: OrderEvent) -> None` — catch-all for any order event |
| `on_position_opened` | `(self, event: PositionOpened) -> None` |
| `on_position_changed` | `(self, event: PositionChanged) -> None` |
| `on_position_closed` | `(self, event: PositionClosed) -> None` |
| `on_event` | `(self, event: Event) -> None` — catch-all for *any* event |

Full order-event families (`OrderSubmitted`, `OrderCanceled`, `OrderModifyRejected`, etc.) are documented in [orders](orders.md) and [execution](execution.md); route through `on_order_event`/`on_event` for the ones without a dedicated hook.

## on_start: recommended startup sequence

```python
def on_start(self) -> None:
    self.instrument = self.cache.instrument(self.instrument_id)
    if self.instrument is None:
        self.log.error(f"Could not find instrument for {self.instrument_id}")
        self.stop()                       # transitions strategy to STOPPED
        return

    # Register indicators BEFORE subscribing (ordering gotcha, see below)
    self.register_indicator_for_bars(self.bar_type, self.fast_ema)
    self.register_indicator_for_bars(self.bar_type, self.slow_ema)

    # Seed history, then subscribe live inside the callback.
    # `start` is a REQUIRED positional; kwarg is `update_catalog` (not update_catalog_mode).
    self.request_bars(
        self.bar_type,
        start=self.clock.utc_now() - pd.Timedelta(days=1),
        callback=lambda _: self.subscribe_bars(self.bar_type),
    )
    self.subscribe_quote_ticks(self.instrument_id)
```

## Clock & timers

Always use `self.clock`, never wall-clock, so timers behave identically in backtest and live.

```python
import pandas as pd

now: pd.Timestamp = self.clock.utc_now()        # current UTC as pd.Timestamp
unix_nanos: int   = self.clock.timestamp_ns()   # current UNIX time in ns

# One-shot TimeEvent
self.clock.set_time_alert(
    name="MyTimeAlert1",
    alert_time=self.clock.utc_now() + pd.Timedelta(minutes=1),
)

# Repeating TimeEvent
self.clock.set_timer(name="MyTimer1", interval=pd.Timedelta(minutes=1))
```

`TimeEvent`s route to the strategy's timer handler; see [actors](actors.md) for the `on_event` / registered-callback mechanics.

## Cache & portfolio access

```python
# Cache lookups (return None if absent)
self.cache.instrument(instrument_id)          # -> Instrument | None
self.cache.quote_tick(instrument_id)          # -> QuoteTick | None  (last cached)
self.cache.bar(bar_type)                       # -> Bar | None       (last cached)
self.cache.order(client_order_id)             # -> Order | None
self.cache.position(position_id)              # -> Position | None

# Portfolio queries
self.portfolio.net_position(instrument_id)    # -> decimal.Decimal (signed qty)
self.portfolio.is_flat(instrument_id)         # -> bool
self.portfolio.is_completely_flat()           # -> bool (no open positions anywhere)
self.portfolio.unrealized_pnl(instrument_id)  # -> Money
```

See [portfolio-and-reports](portfolio-and-reports.md) for the full portfolio surface.

## Trading commands & order construction

Build correctly-precisioned values with `instrument.make_qty()` / `instrument.make_price()`. Full order types, TIF, and emulation are in [orders](orders.md).

```python
from nautilus_trader.model.enums import OrderSide, TimeInForce, TriggerType
from nautilus_trader.model import ExecAlgorithmId, Quantity

# Emulated LimitOrder
order = self.order_factory.limit(
    instrument_id=self.instrument_id,
    order_side=OrderSide.BUY,
    quantity=self.instrument.make_qty(self.trade_size),
    price=self.instrument.make_price(5000.00),
    emulation_trigger=TriggerType.LAST_PRICE,   # routes through OrderEmulator
)
self.submit_order(order)

# MarketOrder routed to an execution algorithm (e.g. TWAP)
mkt = self.order_factory.market(
    instrument_id=self.instrument_id,
    order_side=OrderSide.BUY,
    quantity=self.instrument.make_qty(self.trade_size),
    time_in_force=TimeInForce.FOK,              # explicit choice; OrderFactory default is GTC
    exec_algorithm_id=ExecAlgorithmId("TWAP"),
    exec_algorithm_params={"horizon_secs": 20, "interval_secs": 2.5},
)
self.submit_order(mkt)

# Modify (at least one value MUST differ from original); kwargs are quantity/price/trigger_price
self.modify_order(order, quantity=Quantity.from_int(5))

# Cancels
self.cancel_order(order)
self.cancel_orders(my_order_list)   # list[Order]
self.cancel_all_orders(self.instrument_id)   # instrument_id is REQUIRED
```

| Command | Signature |
|---|---|
| `submit_order` | `(self, order: Order) -> None` |
| `modify_order` | `(self, order, quantity: Quantity\|None=None, price: Price\|None=None, trigger_price: Price\|None=None, client_id=None, params=None) -> None` |
| `cancel_order` | `(self, order: Order) -> None` |
| `cancel_orders` | `(self, orders: list[Order], client_id=None, params=None) -> None` |
| `cancel_all_orders` | `(self, instrument_id, order_side=OrderSide.NO_ORDER_SIDE, client_id=None, params=None) -> None` — `instrument_id` REQUIRED |
| `market_exit` | `(self) -> None` — flatten via reduce-only market orders; cancels non-reduce-only orders |

Additional commands (`submit_order_list`, `close_position`, `close_all_positions`) exist for order lists and position flattening — see [orders](orders.md) / [execution](execution.md) for exact signatures.

### Market exit with hooks & guard

```python
self.market_exit()

class MyStrategy(Strategy):
    def on_market_exit(self) -> None:   # called at start of exit
        self.log.info("Beginning market exit...")

    def post_market_exit(self) -> None: # called after exit completes
        self.log.info("Market exit complete")

    def on_quote_tick(self, tick) -> None:
        if self.is_exiting():           # -> bool
            return                      # skip order logic while flattening
        # ... normal order logic
```

## Single strategy, multiple instruments

One `Strategy` instance can subscribe to and trade **many** `instrument_id`s concurrently. Key all per-instrument state by `InstrumentId`, and (if you need per-instrument order-ID namespacing) use distinct order tags.

```python
from nautilus_trader.indicators import ExponentialMovingAverage

class MultiConfig(StrategyConfig, kw_only=True, frozen=True):
    instrument_ids: list[InstrumentId]
    trade_size: Decimal
    order_id_tag: str

class MultiStrategy(Strategy):
    def __init__(self, config: MultiConfig) -> None:
        super().__init__(config)
        self.emas: dict[InstrumentId, ExponentialMovingAverage] = {}
        self.positions_state: dict[InstrumentId, int] = {}

    def on_start(self) -> None:
        for iid in self.config.instrument_ids:
            ema = ExponentialMovingAverage(20)
            bar_type = BarType.from_str(f"{iid}-1-MINUTE-LAST-EXTERNAL")
            self.register_indicator_for_bars(bar_type, ema)  # BEFORE subscribe
            self.subscribe_bars(bar_type)
            self.emas[iid] = ema

    def on_bar(self, bar: Bar) -> None:
        iid = bar.bar_type.instrument_id       # dispatch by instrument
        ema = self.emas[iid]
        # ... per-instrument logic keyed on iid
```

**One-strategy-multiple-instruments vs one-strategy-per-instrument:**

| Pattern | When |
|---|---|
| **One instance, many instruments** (keyed dicts) | Instruments share logic/parameters; you want shared state, fewer components, simpler cross-instrument coordination. Dispatch handlers via `bar.bar_type.instrument_id` / `tick.instrument_id`. |
| **One instance per instrument** | Instruments need independent config, isolation, or per-instrument lifecycle. Each instance needs a **unique `strategy_id` / `order_id_tag`**. |

**Uniqueness rule (both patterns):** every `Strategy` instance registered on a node needs a unique strategy ID; duplicate strategy IDs raise `RuntimeError` at registration. With the per-instrument pattern, give each instance a distinct `order_id_tag` (`"001"`, `"002"`, …) or explicit `strategy_id`.

## String grammars

| Name | Format | Examples |
|---|---|---|
| `InstrumentId` | `{symbol}.{VENUE}` | `ETHUSDT-PERP.BINANCE` |
| `BarType` | `{InstrumentId}-{step}-{aggregation}-{price_type}-{aggregation_source}` | `ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-EXTERNAL` |
| `StrategyId` | `{ClassName}-{order_id_tag}` | `MyStrategy-001`; `MyStrategy-000` (default when tag omitted) |

Construct via `InstrumentId.from_str(...)` / `BarType.from_str(...)`. See [value-types](value-types.md) and [data](data.md) for the full grammar.

## Gotchas

- **Framework calls in `__init__`** → the clock and logging subsystems are not initialized until *after* strategy registration (which happens after `__init__`). Only call `super().__init__(config)` and set plain state in `__init__`; do all `self.clock` / `self.log` / cache interactions in `on_start` onward.
- **Forgetting `super().__init__()`** → the instance is not wired to the framework. Always call the parent constructor as the first line.
- **`subscribe_bars` directly in `on_start` without a preceding `request_bars`** → with `validate_data_sequence=True`, live bars can fail sequence validation, and direct subscription assumes the instrument was already loaded. Seed history first: `request_bars(bar_type, callback=lambda _: self.subscribe_bars(bar_type))`.
- **Registering an indicator AFTER `subscribe_bars`** → the indicator misses bars / isn't auto-updated. **`register_indicator_for_bars(bar_type, indicator)` must run BEFORE `subscribe_bars(bar_type)`.**
- **`modify_order` with unchanged qty/price/trigger** → invalid; at least one value must actually differ from the original.
- **Modifying an order under an execution algorithm** → not allowed. Exec-algorithm-controlled orders can only be canceled, never directly modified.
- **Reusing `strategy_id` / `order_id_tag` across instances** → duplicate strategy IDs raise `RuntimeError` at registration. Give each instance a distinct `order_id_tag` or explicit `strategy_id`.
- **Submitting non-reduce-only orders during a market exit** → automatically denied. For an order list, if *any* order is non-reduce-only the ENTIRE list is denied (to preserve interdependencies). Guard with `if self.is_exiting(): return` and send only reduce-only orders while exiting.
- **`manage_gtd_expiry=True` while the exec client also submits real GTD to the venue** (e.g. Binance Futures native GTD) → managed and venue-side expiry conflict. Set `use_gtd=False` on the execution client config when using `manage_gtd_expiry=True`.
- **Assuming a managed GTD timer survives after the order leaves the strategy** → any managed GTD timer is canceled once the command leaves the strategy (e.g. on cancel). Rely on the framework's managed lifecycle; don't assume the internal time alert persists past order handoff.
- **Not checking `cache.instrument()` for `None` in live** → direct lookups/subscriptions assume the instrument was already loaded by the provider or a prior request. Check for `None`, log an error, `self.stop()` and return (as in the `on_start` pattern).

See also: [architecture](architecture.md), [actors](actors.md), [orders](orders.md), [execution](execution.md), [backtesting](backtesting.md), [live-trading](live-trading.md), [gotchas](gotchas.md), and the master [SKILL.md](../SKILL.md).

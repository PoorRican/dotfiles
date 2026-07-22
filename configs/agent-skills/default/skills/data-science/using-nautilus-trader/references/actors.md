# Actors & Non-Trading Components

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/actors.md

## TL;DR

`Actor` is NautilusTrader's base component for **data handling, event management, and state management** — everything a [Strategy](strategies.md) does *except order management*. A `Strategy` **is** an `Actor` (it subclasses it and adds order/position management), so anything below is also true of strategies. Reach for a bare `Actor` when you want to consume data, compute features/indicators, run timers, and publish signals/custom data onto the [message bus](message-bus.md) — but you have no orders to submit. Actors get the same shared system handles as strategies: `self.cache`, `self.portfolio`, `self.clock`, `self.log`, `self.msgbus`. Configuration is a typed `ActorConfig` subclass; runtime state lives as instance attributes, never written back into the config.

The single most important architectural fact: **real-time subscriptions and historical requests route to different handlers.** `subscribe_bars()` → `on_bar()`; `request_bars()` → `on_historical_data()`.

## Actor vs Strategy — when to use which

| Use a bare `Actor` | Use a [`Strategy`](strategies.md) |
|---|---|
| Feature / indicator computation, signal publishing | Anything that submits, modifies, or cancels orders |
| Data enrichment, custom-data producers | Anything holding positions or reading fills to drive trading |
| Monitoring / telemetry (e.g. fill monitors) | Full trading logic |
| No `order_factory`, no position management | Has `submit_order`, `order_factory`, position handlers |

An Actor can still **observe** order fills/cancels for an instrument via the message bus (see below) without any ability to place orders.

## Lifecycle state machine

`PRE_INITIALIZED → RUNNING` (optionally `DEGRADED` / `FAULTED`) `→ DISPOSED`. Transitions invoke `on_*` handlers. Override only what you need.

| Handler | Signature | When / use for |
|---|---|---|
| `on_start` | `on_start(self) -> None` | Starting. **Place data subscriptions here.** |
| `on_stop` | `on_stop(self) -> None` | Stopping. **Cancel timers, unsubscribe** to avoid leaks. |
| `on_resume` | `on_resume(self) -> None` | Resuming from stopped. |
| `on_reset` | `on_reset(self) -> None` | Reset indicators/state; called between backtest runs. |
| `on_degrade` | `on_degrade(self) -> None` | Entering degraded state. |
| `on_fault` | `on_fault(self) -> None` | Fault encountered. |
| `on_dispose` | `on_dispose(self) -> None` | Final cleanup on disposal. |

Data / event handlers:

| Handler | Signature | Fed by |
|---|---|---|
| `on_bar` | `on_bar(self, bar: Bar) -> None` | `subscribe_bars()` (real-time) |
| `on_historical_data` | `on_historical_data(self, data: Data) -> None` | `request_*()` methods (historical) |
| `on_order_filled` | `on_order_filled(self, event: OrderFilled) -> None` | `subscribe_order_fills()` |
| `on_order_canceled` | `on_order_canceled(self, event: OrderCanceled) -> None` | `subscribe_order_cancels()` |
| `on_event` | `on_event(self, event) -> None` | Fallback; receives `TimeEvent` when a timer/alert callback is omitted |

## ActorConfig

```python
from nautilus_trader.config import ActorConfig
```

| Field | Type | Default | Meaning |
|---|---|---|---|
| `component_id` | `str \| None` | `None` | Optional registration ID. If omitted the system derives a runtime ID. |
| `log_events` | `bool` | `True` | Emit component-lifecycle events to the log. |
| `log_commands` | `bool` | `True` | Emit received commands to the log. |

Subclass to declare typed fields. Config is **construction data only** — read it via `self.config`; keep mutable runtime state as instance attributes.

```python
class MyActorConfig(ActorConfig):
    instrument_id: InstrumentId   # e.g. "ETHUSDT-PERP.BINANCE"
    bar_type: BarType             # e.g. "ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-INTERNAL"
    lookback_period: int = 10
```

## Canonical minimal Actor

```python
from nautilus_trader.config import ActorConfig
from nautilus_trader.model import InstrumentId
from nautilus_trader.model import Bar, BarType
from nautilus_trader.common.actor import Actor


class MyActorConfig(ActorConfig):
    instrument_id: InstrumentId   # example value: "ETHUSDT-PERP.BINANCE"
    bar_type: BarType             # example value: "ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-INTERNAL"
    lookback_period: int = 10


class MyActor(Actor):
    def __init__(self, config: MyActorConfig) -> None:
        super().__init__(config)              # REQUIRED first — wires registration/system

        # Custom runtime state
        self.count_of_processed_bars: int = 0

    def on_start(self) -> None:
        self.subscribe_bars(self.config.bar_type)

    def on_bar(self, bar: Bar) -> None:
        self.count_of_processed_bars += 1
```

## Real-time subscription vs historical request

These are **two separate data flows with separate handlers** — the #1 source of confusion.

```python
def on_start(self) -> None:
    # Historical → arrives in on_historical_data()
    self.request_bars(
        bar_type=self.bar_type,
        start=None,               # pd.Timestamp | None — REQUIRED positional
        end=None,                 # pd.Timestamp | None
        limit=0,                  # int
        callback=None,            # Callable[[UUID4], None] | None — fires on completion
        update_catalog=False,     # bool — write fetched bars back to the catalog
        params=None,              # dict[str, Any] | None
    )

    # Real-time → arrives in on_bar()
    self.subscribe_bars(
        bar_type=self.bar_type,
        client_id=None,       # ClientId | None
        update_catalog=False, # bool
        params=None,          # dict[str, Any] | None
    )

def on_historical_data(self, data: Data) -> None:
    if isinstance(data, Bar):
        self.log.info(f"Historical bar: {data}")

def on_bar(self, bar: Bar) -> None:
    self.log.info(f"Real-time bar: {bar}")
```

Key signatures:

```python
subscribe_bars(bar_type: BarType, client_id: ClientId | None = None, update_catalog: bool = False,
               params: dict[str, Any] | None = None)

request_bars(bar_type: BarType, start: pd.Timestamp, end: pd.Timestamp | None = None, limit: int = 0,
             client_id: ClientId | None = None, callback: Callable[[UUID4], None] | None = None,
             update_catalog: bool = False, join_request: bool = False,
             request_id: UUID4 | None = None, params: dict[str, Any] | None = None)
```

`on_historical_data` handles the union of all `request_*` output — branch on `isinstance(data, Bar)` (and other types). See [data.md](data.md) for the full subscribe/request surface and [custom-data.md](custom-data.md) for publishing your own data types.

## Timers and time alerts

```python
from datetime import timedelta

def on_start(self) -> None:
    self.clock.set_timer(
        "my_timer",
        timedelta(seconds=5),
        callback=self._on_timer,        # recurring; fires every 5s
    )
    self.clock.set_time_alert(
        "my_alert",
        self.clock.utc_now() + timedelta(minutes=1),
        callback=self._on_alert,        # one-shot at a specific time
    )

def on_stop(self) -> None:
    self.clock.cancel_timer("my_timer")  # ALWAYS cancel — timers leak across stop/resume

def _on_timer(self, event: TimeEvent) -> None:
    self.log.info("Timer fired!")

def _on_alert(self, event: TimeEvent) -> None:
    self.log.info("Alert triggered!")
```

| Method | Signature |
|---|---|
| set recurring timer | `self.clock.set_timer(name: str, interval: timedelta, callback: Callable[[TimeEvent], None])` |
| set one-shot alert | `self.clock.set_time_alert(name: str, alert_time, callback: Callable[[TimeEvent], None])` |
| cancel | `self.clock.cancel_timer(name: str)` |
| current UTC | `self.clock.utc_now()` |

If `callback` is omitted, the `TimeEvent` is delivered to `on_event()` instead of a dedicated method.

## Observing order fills/cancels (message-bus only)

An Actor can watch order events for an instrument **without managing orders**. These route through the [message bus](message-bus.md) (not the data engine), so handlers fire only while the actor is running.

```python
from nautilus_trader.model.events import OrderFilled


class FillMonitorActor(Actor):
    def __init__(self, config: MyActorConfig) -> None:
        super().__init__(config)
        self.fill_count = 0
        self.total_volume = 0.0

    def on_start(self) -> None:
        self.subscribe_order_fills(self.config.instrument_id)

    def on_order_filled(self, event: OrderFilled) -> None:
        self.fill_count += 1
        self.total_volume += float(event.last_qty)
        self.log.info(
            f"Fill: {event.order_side} {event.last_qty} @ {event.last_px}, "
            f"total fills: {self.fill_count}, volume: {self.total_volume}"
        )

    def on_stop(self) -> None:
        self.unsubscribe_order_fills(self.config.instrument_id)
```

| Method | Signature | Routes to |
|---|---|---|
| `subscribe_order_fills` | `subscribe_order_fills(instrument_id: InstrumentId)` | `on_order_filled()` |
| `subscribe_order_cancels` | `subscribe_order_cancels(instrument_id: InstrumentId)` | `on_order_canceled()` |
| `unsubscribe_order_fills` | `unsubscribe_order_fills(instrument_id: InstrumentId)` | — |
| `unsubscribe_order_cancels` | `unsubscribe_order_cancels(instrument_id: InstrumentId)` | — |

## Registering actors on a node/engine

Actors register via config on the engine/node, alongside strategies. For a `BacktestEngine`, add actor instances directly; for config-driven `BacktestNode` / live `TradingNode`, pass an `ImportableActorConfig` list. See [backtesting.md](backtesting.md) and [live-trading.md](live-trading.md) for the exact wiring (`engine.add_actor(...)` / `actors=[...]` in the run config). The `component_id` field controls the registered identity.

## String grammars

| Name | Format | Examples |
|---|---|---|
| `BarType` | `{instrument_id}-{step}-{aggregation}-{price_type}-{source}` | `ETHUSDT-PERP.BINANCE-15-MINUTE-LAST-INTERNAL`, `AAPL.XNAS-1-MINUTE-LAST-EXTERNAL` |
| `InstrumentId` | `{symbol}.{venue}` | `ETHUSDT-PERP.BINANCE`, `AAPL.XNAS` |

## Gotchas

- **Expecting `request_bars()` results in `on_bar()`.** Historical requests route to `on_historical_data()`; only real-time subscriptions route to `on_bar()`. If you see "received bars" logs but `on_bar()` is silent, check `on_historical_data()` and branch on `isinstance(data, Bar)`.
- **Not cancelling timers in `on_stop()`.** Timers persist across stop/resume cycles and leak resources. Call `self.clock.cancel_timer(name)` for every timer you set.
- **Omitting the callback but expecting a dedicated method.** If `set_timer`/`set_time_alert` has no `callback`, the `TimeEvent` goes to `on_event()` — either pass an explicit callback or handle it there.
- **Storing runtime state back into config.** Config is construction data only; runtime IDs live on the actor core (Rust). Read settings via `self.config`; keep mutable state as instance attributes.
- **Expecting fill/cancel events while stopped.** `subscribe_order_fills`/`subscribe_order_cancels` use only the message bus; handlers fire only while the actor is running. Unsubscribe in `on_stop()`.
- **Combining a separate `subscribe_bars()` with a historical request under `validate_data_sequence=True`.** The real-time stream must start only after history loads. Use the `request_bars()` completion `callback` to begin the live stream rather than issuing an independent `subscribe_bars()`.
- **Forgetting `super().__init__(config)`.** It must be the first call in your `__init__` — the base `Actor` needs the config for registration and system wiring.

See also: [strategies.md](strategies.md) (Actor + order management), [message-bus.md](message-bus.md), [data.md](data.md), [custom-data.md](custom-data.md), [architecture.md](architecture.md), and the master [SKILL.md](../SKILL.md).

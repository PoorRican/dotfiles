# Message Bus, Cache, Events & Custom Streams

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/message_bus.md
- https://nautilustrader.io/docs/md/latest/concepts/cache.md
- https://nautilustrader.io/docs/md/latest/concepts/events.md

## TL;DR

NautilusTrader is event-driven: every state change is an **event object** routed through the **MessageBus** by string topic. Actors/Strategies rarely touch the bus directly — they use high-level helpers (`publish_data`/`subscribe_data`, `publish_signal`/`subscribe_signal`) and typed handlers (`on_data`, `on_signal`, `on_order_filled`, `on_position_opened`, ...). Under the hood these are `msgbus.publish(topic, msg)` / `msgbus.subscribe(topic, handler)` calls on well-known topics. The **Cache** is the central in-memory store the bus writes to before publishing: instruments, orders, positions, accounts, and reverse-indexed market data (`index 0 = most recent`). Reach for the bus for custom pub/sub; reach for the cache for current state and bounded recent history. For structured custom payloads see [custom-data.md](custom-data.md).

---

## MessageBus mental model

- Central **pub/sub + request/response** backbone connecting Actors, Strategies, and engines by **string topics**.
- Supports **wildcard** topic subscription patterns (`*` matches multiple chars, `?` a single char) so a subscriber can catch a family of topics.
- Can be backed by **Redis** (external DB) and can **stream messages externally** with pluggable encodings (JSON, MessagePack).
- Messages are treated as **immutable** — critical for backtest ordering, replay, and audit.
- Data subscriptions (`subscribe_bars`, `subscribe_quote_ticks`, etc.) ride the same bus on `data.*` topics; the high-level helpers just wrap `publish`/`subscribe`.

### Core bus API

| Call | Signature | Purpose |
|---|---|---|
| `msgbus.publish` | `publish(topic: str, message: object) -> None` | Publish any message to a named topic. |
| `msgbus.subscribe` | `subscribe(topic: str, handler: Callable) -> None` | Subscribe a handler to a topic (supports wildcards). |
| `msgbus.request` | request/response by endpoint | Send a request expecting a correlated reply routed by correlation-ID. |
| `msgbus.send` | send to an endpoint | Point-to-point send to a registered endpoint. |
| `msgbus.register` | register an endpoint handler | Register a handler as a named endpoint (for `send`/`request`). |

> Prefer the Actor/Strategy helpers below over raw `publish`/`subscribe` unless you need arbitrary topics or custom `Event` types.

### Actor/Strategy helpers

| Helper | Signature | Delivered to |
|---|---|---|
| `publish_data` | `publish_data(data_type: DataType, data: Data) -> None` | subscribers' `on_data` |
| `subscribe_data` | `subscribe_data(data_type: DataType) -> None` | `on_data(self, data)` |
| `publish_signal` | `publish_signal(name: str, value, ts_event: int = 0) -> None` | subscribers' `on_signal` |
| `subscribe_signal` | `subscribe_signal(name: str) -> None` | `on_signal(self, signal)` |

---

## Topic naming grammar

Topic names are tracked **manually** — a typo silently drops messages. Centralize them as constants.

| Topic kind | Format | Examples |
|---|---|---|
| Live data | `data.<kind>...` | `data.book.deltas.XCME.ESZ24`, `data.response` |
| Pipeline (replayed) data | `data.pipeline.<kind>...` | `data.pipeline.book.deltas.XCME.ESZ24` |
| Event | `events.<category>.<id>` | `events.order.S-001` |

`data.response` is a **capture channel only** — correlated request/response replies do **not** arrive here; they route through correlation-ID-keyed handlers.

---

## Signals (lightweight single-value notifications)

Signals carry a **single** `int`/`float`/`str` value. In `on_signal` you can only read `signal.value` and `signal.ts_event` — the **signal name is NOT accessible**, so encode the discriminator in the value.

```python
import types
from nautilus_trader.core.datetime import unix_nanos_to_dt
from nautilus_trader.common.enums import LogColor

signals = types.SimpleNamespace()
signals.NEW_HIGHEST_PRICE = "NewHighestPriceReached"
signals.NEW_LOWEST_PRICE = "NewLowestPriceReached"

# Subscribe (in Actor/Strategy on_start)
self.subscribe_signal(signals.NEW_HIGHEST_PRICE)
self.subscribe_signal(signals.NEW_LOWEST_PRICE)

# Publish
self.publish_signal(
    name=signals.NEW_HIGHEST_PRICE,
    value=signals.NEW_HIGHEST_PRICE,   # value IS the discriminator
    ts_event=bar.ts_event,
)

# Handler — match on value, not name
def on_signal(self, signal):
    match signal.value:
        case signals.NEW_HIGHEST_PRICE:
            self.log.info(f"New high | {signal.value} | {unix_nanos_to_dt(signal.ts_event)}", color=LogColor.GREEN)
        case signals.NEW_LOWEST_PRICE:
            self.log.info(f"New low | {signal.value} | {unix_nanos_to_dt(signal.ts_event)}", color=LogColor.RED)
```

For structured payloads use `publish_data` with a custom `Data` class instead — see below and [custom-data.md](custom-data.md).

## Custom Data on the bus

```python
from nautilus_trader.core.data import Data
from nautilus_trader.model.custom import customdataclass
from nautilus_trader.model.data import DataType

# NOTE: names must be globally unique — `GreeksData` ships auto-registered in
# nautilus_trader.model.greeks_data and re-using it raises KeyError at class def.
@customdataclass  # adds ts_event/ts_init + to_dict/from_dict/to_bytes/to_arrow
class OptionGreeks(Data):
    delta: float
    gamma: float

# Publish (Actor/Strategy) — pass DataType(T), never a bare class
data = OptionGreeks(delta=0.75, gamma=0.1,
                    ts_event=1_630_000_000_000_000_000,
                    ts_init=1_630_000_000_000_000_000)
self.publish_data(DataType(OptionGreeks), data)

# Subscribe (Actor/Strategy on_start)
self.subscribe_data(DataType(OptionGreeks))

# Handler
def on_data(self, data: Data):
    if isinstance(data, OptionGreeks):
        self.log.info(f"Delta: {data.delta}, Gamma: {data.gamma}")
```

`ts_event`/`ts_init` are **nanoseconds** and required — they drive backtest ordering. See [custom-data.md](custom-data.md).

## Custom Events (arbitrary component-to-component)

```python
from nautilus_trader.core.message import Event

class Each10thBarEvent(Event):
    TOPIC = "each_10th_bar"   # define TOPIC as a class attribute
    def __init__(self, bar):
        self.bar = bar

# Subscribe (in a component)
self.msgbus.subscribe(Each10thBarEvent.TOPIC, self.on_each_10th_bar)

# Publish
self.msgbus.publish(Each10thBarEvent.TOPIC, Each10thBarEvent(bar))

# Handler
def on_each_10th_bar(self, event: Each10thBarEvent):
    self.log.info(f"Received 10th bar: {event.bar}")
```

Lowest level of all: `self.msgbus.publish("MyTopic", "MyMessage")`.

---

## MessageBusConfig (encoding, external streaming, Redis)

Passed as the `message_bus` field of `TradingNodeConfig` (and backtest configs). Key fields:

| Field | Type / default | Meaning |
|---|---|---|
| `database` | `Optional[DatabaseConfig]` = `None` | Backing DB (e.g. `DatabaseConfig(type="redis")`); this is the only Redis knob. |
| `encoding` | `str` = `json` | Message serialization (`json`, `msgpack`). |
| `timestamps_as_iso8601` | `bool` = `False` | Serialize ts as ISO8601 vs raw nanos. |
| `buffer_interval_ms` | `Optional[int]` | Buffering interval for outbound stream writes. |
| `autotrim_mins` | `Optional[int]` | **Max stream width** for Redis auto-trim (≈+1 min; trimmed ≤ once/min) — not wall-clock trimming. |
| `use_trader_prefix` / `use_trader_id` / `use_instance_id` | `bool` | Components included in stream keys. |
| `streams_prefix` | `str` = `streams` | Prefix for external stream keys. |
| `stream_per_topic` | `bool` = `True` | One Redis stream per topic; **set `False` for Redis** (no wildcard streams). |
| `external_streams` | `Optional[List[str]]` | External stream keys to consume/republish inbound messages from. |
| `types_filter` | `Optional[List[type]]` | Message types to **exclude** from external streaming. |
| `heartbeat_interval_secs` | `Optional[int]` | Heartbeat publish interval. |

There is **no** `RedisMessageBusConfig`. Redis is configured via `database=DatabaseConfig(type="redis", ...)` whose fields include `connection_timeout` / `response_timeout`. Streams require **Redis ≥ 6.2**.

```python
from nautilus_trader.config import MessageBusConfig
from nautilus_trader.model.data import QuoteTick, TradeTick

# Exclude high-volume types from external streams
message_bus = MessageBusConfig(types_filter=[QuoteTick, TradeTick])
```

### Serializing custom types for streaming / Redis

Unregistered inbound payload types are **skipped without decoding**. Register custom types so they serialize:

```python
from nautilus_trader.serialization.base import register_serializable_type
register_serializable_type(cls, to_dict, from_dict)
# to_dict: Callable[[Any], dict]; from_dict: Callable[[dict], Any]
```

Some types (full book snapshots, greeks, option-chain slices, DeFi pool swaps) lack Serde serialization and are **not** forwarded. Use JSON or MessagePack for custom payloads (SBE/Cap'n Proto only cover market data with the Rust features enabled).

### External streaming consumer node

Set `LiveDataEngineConfig.external_clients` = list of `ClientId`s for the external streaming clients. This makes the `DataEngine` filter their subscription commands (avoiding duplicate subscription requests) and register inbound types for republishing.

---

## The Cache

Central **in-memory database** accessed via `self.cache` from actors/strategies. Stores market data (order books, quotes, trades, bars), trading objects (orders, positions, accounts, instruments, currencies), and arbitrary custom bytes. **Reverse indexing: index 0 = most recent.** Optional Redis/PostgreSQL backing.

> Write-path note: quotes/trades/bars are written to the Cache **before** being published to subscribers, so they are visible in handlers. Order books are the exception — maintained separately via `BookUpdater`, not on the main data-write path.

### Query API

**Market data (reverse-indexed):**

| Method | Signature | Returns |
|---|---|---|
| `bar` | `bar(bar_type, index=0)` | `Bar | None` (0 = latest) |
| `bars` | `bars(bar_type)` | `list[Bar]` (0 = latest) |
| `bar_count` / `has_bars` | `(bar_type)` | `int` / `bool` |
| `quote_tick` / `quote_ticks` | `(instrument_id, index=0)` / `(instrument_id)` | `QuoteTick | None` / `list` |
| `trade_tick` / `trade_ticks` | `(instrument_id, index=0)` / `(instrument_id)` | `TradeTick | None` / `list` |
| `order_book` / `has_order_book` / `book_update_count` | `(instrument_id)` | `OrderBook | None` / `bool` / `int` |
| `price` | `price(instrument_id, price_type)` | `Price | None` (BID/ASK/MID/LAST) |
| `bar_types` | `bar_types(instrument_id, price_type, aggregation_source)` | `list[BarType]` |

**Orders:** `order(client_order_id)`, `orders(venue=None, strategy_id=None, instrument_id=None)`, `orders_open(instrument_id=None)`, `orders_closed()`, `orders_emulated()`, `orders_inflight()`, `orders_total_count(venue=None)` (analogous `*_count` for open/closed/emulated/inflight; some accept `side=OrderSide`).

**Positions:** `position(position_id)`, `positions(venue=None, instrument_id=None, strategy_id=None, side=None)`, `positions_open()`, `positions_closed()`, `orders_for_position(position_id)`, `position_for_order(client_order_id)`, `position_snapshots(position_id)`.

**Accounts:** `account(account_id)`, `account_for_venue(venue)`, `account_id(venue)`.

**Instruments:** `instrument(instrument_id)`, `instruments(venue=None, underlying=None)`, `instrument_ids(venue=None)`.

**Custom bytes:** `add(key, value)` / `get(key) -> bytes | None` — **bytes only**, serialize yourself; shareable across strategies.

**Purging:** `purge_instrument(instrument_id)`, `purge_order(client_order_id)`, `purge_position(position_id)`, `purge_closed_orders(ts_now, buffer_secs)`, `purge_closed_positions(ts_now, buffer_secs)`, `purge_account_events(ts_now, lookback_secs)`.

### BarType grammar

```
{instrument_id}-{step}-{aggregation}-{price_type}-{aggregation_source}
```
Examples: `ESZ4.CME-1-MINUTE-LAST-EXTERNAL`, `AAPL.NASDAQ-1-MINUTE-LAST-EXTERNAL`. Build with `BarType.from_str(...)`.

### Canonical read patterns

```python
def on_bar(self, bar: Bar) -> None:
    last_bar = self.cache.bar(self.bar_type, index=0)      # most recent
    previous_bar = self.cache.bar(self.bar_type, index=1)

    bars = self.cache.bars(self.bar_type)[:3]              # window; guard length
    if len(bars) < 3:
        return
    current_bar, prev_bar, prev_prev_bar = bars

    latest_quote = self.cache.quote_tick(self.instrument_id)
    if latest_quote is not None:
        spread = latest_quote.ask_price - latest_quote.bid_price

    open_orders = self.cache.orders_open(instrument_id=self.instrument_id)
```

```python
from nautilus_trader.model.enums import PriceType, AggregationSource

price = self.cache.price(instrument_id=instrument_id, price_type=PriceType.MID)
bar_types = self.cache.bar_types(
    instrument_id=instrument_id,
    price_type=PriceType.LAST,
    aggregation_source=AggregationSource.EXTERNAL,
)
```

```python
import pickle
# Producer
self.cache.add("shared_strategy_info", pickle.dumps({"trading_enabled": True}))
# Consumer (another strategy)
data_bytes = self.cache.get("shared_strategy_info")
if data_bytes is not None:
    shared = pickle.loads(data_bytes)
```

### CacheConfig (key fields)

Passed as the `cache` field of `BacktestEngineConfig` / `TradingNodeConfig`.

| Field | Default | Meaning |
|---|---|---|
| `tick_capacity` | `10000` | Max quote/trade ticks retained **per instrument** (oldest dropped). |
| `bar_capacity` | `10000` | Max bars retained **per bar type, independently** (oldest dropped). |
| `database` | `None` | Backing `DatabaseConfig` (e.g. `type="redis"`); this is the only Redis/Postgres knob. |
| `encoding` | `msgpack` | Encoding for persisted objects (`msgpack`, `json`). |
| `timestamps_as_iso8601` | `false` | Persist ts as ISO8601 vs int. |
| `persist_account_events` | `true` | Persist account state events. |
| `buffer_interval_ms` | `None` | Buffering interval for DB writes. |
| `use_trader_prefix` | `true` | Prefix keys with trader id. |
| `use_instance_id` | `false` | Include instance id in keys. |
| `flush_on_start` | `false` | Flush backing DB on startup. |
| `drop_instruments_on_reset` | `true` | Drop instruments on reset. |

```python
from nautilus_trader.config import CacheConfig, BacktestEngineConfig
engine_config = BacktestEngineConfig(cache=CacheConfig(tick_capacity=10_000, bar_capacity=5_000))
```

There is **no** `RedisCacheConfig` / `PostgresCacheConfig`. Backing stores are configured via `database=DatabaseConfig(type="redis"|"postgres", host=..., port=..., connection_timeout=..., response_timeout=...)`.

### Automatic purging in live (LiveExecEngineConfig)

Bulk purging is automatic **only** for closed orders/positions/account events — **instrument purging has no automatic loop** (call `cache.purge_instrument(...)` from a strategy/actor lifecycle).

```python
from nautilus_trader.config import LiveExecEngineConfig
exec_engine = LiveExecEngineConfig(
    purge_closed_orders_interval_mins=15,   purge_closed_orders_buffer_mins=60,
    purge_closed_positions_interval_mins=15, purge_closed_positions_buffer_mins=60,
    purge_account_events_interval_mins=15,   purge_account_events_lookback_mins=60,
)
```

**Cache vs [Portfolio](portfolio-and-reports.md):** Cache = stored objects/history (`position_snapshots`); Portfolio = aggregated live analytics (`portfolio.net_exposure(instrument_id)`).

---

## Events

Every state change is an event flowing through the bus to handlers. Four categories:

| Category | Source | Example events |
|---|---|---|
| Order | `ExecutionEngine` | `OrderAccepted`, `OrderFilled`, `OrderCanceled`, `OrderUpdated`, `OrderModifyRejected`, `OrderCancelRejected`, `OrderExpired` |
| Position | derived from fills | `PositionOpened`, `PositionChanged`, `PositionClosed` |
| Account | `ExecutionClient` / `Portfolio` | `AccountState` (balance/margin snapshot) |
| Time | `Clock` | `TimeEvent` (timers, alerts) |

### Handler dispatch (specific → general)

Multiple handlers can fire for **one** event, from most-specific to most-general:

- Order: `on_order_filled` / `on_order_accepted` / `on_order_canceled` → `on_order_event` → `on_event`
- Position: `on_position_opened` / `on_position_changed` / `on_position_closed` → `on_position_event` → `on_event`

Put per-event logic in the specific handler and cross-cutting logic in the catch-alls; do not duplicate.

### Causality & lifecycle

- Position events are **derived from `OrderFilled`** — fills are the source of truth. `OrderFilled` carries `last_qty`, `last_px`, `trade_id`, `commission`.
- First fill → `PositionOpened`; subsequent fills → `PositionChanged`; fill to zero qty → `PositionClosed`.
- A fill that **flips** long↔short emits **both** `PositionClosed` then `PositionOpened` (not a single `PositionChanged`).
- Pending transitions can fail: `OrderModifyRejected` (`PendingUpdate → Accepted`) and `OrderCancelRejected` (`PendingCancel → Accepted`) leave the order **live**. Only `OrderCanceled`/`OrderExpired`/`OrderFilled` leave the working state.

### Actor observation without owning orders

Actors can observe execution events for instruments they don't trade:

- `subscribe_order_fills()` → `on_order_filled`
- `subscribe_order_cancels()` → `on_order_canceled`

### Correlating orders and positions via Cache

```python
orders = self.cache.orders_for_position(position.id)          # fills that built the position
position = self.cache.position_for_order(order.client_order_id) # position an order belongs to
opening_order_id = position.opening_order_id                   # stored on the Position
```

### Timers

`clock.set_timer(...)` (repeating) and `clock.set_time_alert(...)` (one-shot) fire `TimeEvent`s to a callback.

---

## Gotchas

- **Mutating a message after creation** (including container fields like params maps) → breaks replay/debug/audit; messages are immutable. Create a new message; keep workflow state in component-owned context keyed by message/request ID.
- **Reading the signal name in `on_signal`** → the name is not accessible, only `signal.value`. Encode the discriminator in the value and `match` on it.
- **Publishing a complex object as a signal** → signals only carry a single `int`/`float`/`str`. Use `publish_data` with a custom `Data` class.
- **Custom Data with bad/missing `ts_event`/`ts_init`** → corrupts backtest ordering. Set both (nanoseconds); `@customdataclass` adds them.
- **Subscribing to `data.response` for replies** → it's a capture channel only; responses route through correlation-ID-keyed handlers.
- **Assuming custom types auto-serialize for streaming/Redis** → unregistered inbound types are silently skipped; some types have no Serde and aren't forwarded. Register via `register_serializable_type` with `to_dict`/`from_dict`; use JSON/MessagePack.
- **`stream_per_topic=True` with Redis** → Redis has no wildcard stream topics. Set `False`.
- **Redis < 6.2 for streaming** → streams need ≥ 6.2.
- **Not setting `LiveDataEngineConfig.external_clients` on the consumer** → DataEngine issues duplicate subscription requests and won't republish inbound external types.
- **Reading `autotrim_mins` as wall-clock trimming** → it's a max stream width (≈+1 min; trimmed ≤ once/min).
- **Topic-string typos** → silently missed messages; centralize as `TOPIC` constants / a namespace.
- **Assuming index 0 is the oldest bar/tick** → it's the most recent; higher index = further back.
- **Expecting instant Cache visibility in live** → live updates may lag briefly (async); tolerate lag in handlers.
- **`purge_instrument()` with working orders / open positions** → refuses if any order is non-terminal or position non-closed. Purge only when terminal/closed.
- **Expecting an automatic loop to purge instruments** → only closed orders/positions/account events auto-purge; drive instrument purging manually.
- **Passing Python objects to `cache.add()`** → bytes only; `pickle.dumps`/`loads` yourself and check `None` on `get`.
- **Treating the Cache as a full database** → it's fixed-capacity in-memory; use a real DB for large/complex queries.
- **Expecting `order_book()` on the quotes/trades/bars write path** → book state is maintained separately via `BookUpdater`.
- **Assuming one bar-capacity limit covers all bars** → each bar type has its own independent capacity.
- **Assuming one handler per event** → dispatch is specific → category → `on_event`; multiple fire.
- **Expecting a single event on a position flip** → a reversal emits `PositionClosed` then `PositionOpened`.
- **Assuming a pending update/cancel succeeded** → a rejection returns the order to `Accepted`.

---

See also: [custom-data.md](custom-data.md), [data.md](data.md), [actors.md](actors.md), [strategies.md](strategies.md), [orders.md](orders.md), [execution.md](execution.md), [portfolio-and-reports.md](portfolio-and-reports.md), [live-trading.md](live-trading.md), [gotchas.md](gotchas.md), and the master [SKILL.md](../SKILL.md).

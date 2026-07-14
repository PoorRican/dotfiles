# Orders: Types, Factory, Advanced Features, Lifecycle

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/orders/index.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/market.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/limit.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/stop_market.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/stop_limit.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/advanced.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/emulated.md
- https://nautilustrader.io/docs/md/latest/concepts/orders/trailing_stop_market.md

## TL;DR

Every `Strategy` has a `self.order_factory` (an `OrderFactory`) that builds order objects and auto-assigns trader ID, strategy ID, init ID, and timestamps. All nine order types conceptually derive from **MARKET** (immediate, execution-certain, price-uncertain) and **LIMIT** (resting, price-certain, execution-uncertain); conditional/trailing types add a `trigger_price`/`activation_price` + `trigger_type` and/or trailing peg logic. Build the order, then `self.submit_order(order)` (or `self.submit_order_list(order_list)` for brackets/contingencies). A hard system rule: **if an order carries an instruction the venue does not support, Nautilus does NOT submit it — it logs a clear explanatory error.** Where a venue lacks native support, set `emulation_trigger` to have the local `OrderEmulator` hold and release the order as a plain MARKET/LIMIT. See also [execution](execution.md), [instruments](instruments.md), [strategies](strategies.md), [gotchas](gotchas.md), and the master [SKILL.md](../SKILL.md).

## Order Types (OrderType enum)

`from nautilus_trader.model.enums import OrderType`

| OrderType | Factory method | On trigger/fill becomes | FIX OrdType |
|---|---|---|---|
| `MARKET` | `order_factory.market` | fills immediately at best price | 1 |
| `LIMIT` | `order_factory.limit` | rests, fills at price or better | 2 |
| `STOP_MARKET` | `order_factory.stop_market` | places MARKET when triggered | 3 |
| `STOP_LIMIT` | `order_factory.stop_limit` | places LIMIT (at `price`) when triggered | 4 |
| `MARKET_TO_LIMIT` | `order_factory.market_to_limit` | MARKET; unfilled remainder resubmitted as LIMIT at executed price | K |
| `MARKET_IF_TOUCHED` | `order_factory.market_if_touched` | places MARKET when `trigger_price` touched | J |
| `LIMIT_IF_TOUCHED` | `order_factory.limit_if_touched` | places LIMIT (at `price`) when touched | — |
| `TRAILING_STOP_MARKET` | `order_factory.trailing_stop_market` | MARKET when trailing trigger fires | 3 |
| `TRAILING_STOP_LIMIT` | `order_factory.trailing_stop_limit` | LIMIT (at `price`) when trailing trigger fires | 4 |

Order objects live in `nautilus_trader.model.orders` (`MarketOrder`, `LimitOrder`, `StopMarketOrder`, `StopLimitOrder`, `MarketToLimitOrder`, `MarketIfTouchedOrder`, `LimitIfTouchedOrder`, `TrailingStopMarketOrder`, `TrailingStopLimitOrder`, `OrderList`).

**Stop vs If-Touched:** both are conditional/triggered, but a STOP triggers when price moves *through* the level (breakout/protective), while IF_TOUCHED triggers when a level is *touched from the other direction* (enter buy below / sell above market). They are distinct order types.

## Basic Types

### Market — immediate fill at best price
```python
from nautilus_trader.model.enums import OrderSide, TimeInForce
from nautilus_trader.model import InstrumentId, Quantity
from nautilus_trader.model.orders import MarketOrder

order: MarketOrder = self.order_factory.market(
    instrument_id=InstrumentId.from_str("AUD/USD.IDEALPRO"),
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(100_000),
    time_in_force=TimeInForce.IOC,  # optional (default GTC)
    reduce_only=False,              # optional (default False)
    tags=["ENTRY"],                 # optional (default None)
)
self.submit_order(order)
```
Signature: `market(instrument_id, order_side, quantity, time_in_force=GTC, reduce_only=False, tags=None) -> MarketOrder`. Fill price is unpredictable (spread + slippage) — use only in liquid instruments.

### Limit — resting maker
```python
from nautilus_trader.model import Price
from nautilus_trader.model.orders import LimitOrder

order: LimitOrder = self.order_factory.limit(
    instrument_id=InstrumentId.from_str("ETHUSDT-PERP.BINANCE"),
    order_side=OrderSide.SELL,
    quantity=Quantity.from_int(20),
    price=Price.from_str("5_000.00"),
    time_in_force=TimeInForce.GTC,  # optional (default GTC)
    expire_time=None,               # optional (default None)
    post_only=True,                 # optional (default False)
    reduce_only=False,              # optional (default False)
    display_qty=None,               # optional (None = full display; smaller = iceberg)
    tags=None,
)
```
Signature: `limit(instrument_id, order_side, quantity, price, time_in_force=GTC, expire_time=None, post_only=False, reduce_only=False, display_qty=None, tags=None) -> LimitOrder`. No execution guarantee.

### Stop-Market — protective / breakout
```python
from nautilus_trader.model.enums import TriggerType
from nautilus_trader.model.orders import StopMarketOrder

order: StopMarketOrder = self.order_factory.stop_market(
    instrument_id=InstrumentId.from_str("BTCUSDT.BINANCE"),
    order_side=OrderSide.SELL,
    quantity=Quantity.from_int(1),
    trigger_price=Price.from_int(100_000),
    trigger_type=TriggerType.LAST_PRICE,  # optional (default DEFAULT)
    time_in_force=TimeInForce.GTC,
    expire_time=None,
    reduce_only=False,
    tags=None,
)
```
Signature: `stop_market(instrument_id, order_side, quantity, trigger_price, trigger_type=DEFAULT, time_in_force=GTC, expire_time=None, reduce_only=False, tags=None) -> StopMarketOrder`. Fill may slip past `trigger_price` in fast/gapping markets.

### Stop-Limit — trigger + worst-fill cap
```python
import pandas as pd
from nautilus_trader.model.orders import StopLimitOrder

order: StopLimitOrder = self.order_factory.stop_limit(
    instrument_id=InstrumentId.from_str("GBP/USD.CURRENEX"),
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(50_000),
    price=Price.from_str("1.30000"),
    trigger_price=Price.from_str("1.30010"),
    trigger_type=TriggerType.BID_ASK,     # optional (default DEFAULT)
    time_in_force=TimeInForce.GTD,        # requires expire_time
    expire_time=pd.Timestamp("2022-06-06T12:00"),
    post_only=True,
    reduce_only=False,
    tags=None,
)
```
Signature: `stop_limit(instrument_id, order_side, quantity, price, trigger_price, trigger_type=DEFAULT, time_in_force=GTC, expire_time=None, post_only=False, reduce_only=False, tags=None) -> StopLimitOrder`. May not fill if the market gaps through both trigger and limit.

## Conditional & Advanced Types

### Market-To-Limit
`market_to_limit(instrument_id, order_side, quantity, time_in_force=GTC, reduce_only=False, display_qty=None, tags=None) -> MarketToLimitOrder`. Submits as MARKET at best price only (no sweeping deeper levels); any unfilled remainder is resubmitted as a LIMIT at the executed price. No price/trigger params.

### Limit-If-Touched
```python
order = self.order_factory.limit_if_touched(
    instrument_id=InstrumentId.from_str("BTCUSDT-PERP.BINANCE"),
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(5),
    price=Price.from_str("30_100"),
    trigger_price=Price.from_str("30_150"),
    trigger_type=TriggerType.LAST_PRICE,   # optional (default DEFAULT)
    time_in_force=TimeInForce.GTD,
    expire_time=pd.Timestamp("2022-06-06T12:00"),
    post_only=True,
    reduce_only=False,
    tags=["TAKE_PROFIT"],
)
```
`limit_if_touched(instrument_id, order_side, quantity, price, trigger_price, trigger_type=DEFAULT, time_in_force=GTC, expire_time=None, post_only=False, reduce_only=False, tags=None) -> LimitIfTouchedOrder`.

### Market-If-Touched
`market_if_touched(instrument_id, order_side, quantity, trigger_price, trigger_type=DEFAULT, time_in_force=GTC, expire_time=None, reduce_only=False, tags=None) -> MarketIfTouchedOrder`. Fires a MARKET when `trigger_price` is touched; fill price not guaranteed.

### Trailing-Stop-Market
```python
from decimal import Decimal
from nautilus_trader.model.enums import TrailingOffsetType
from nautilus_trader.model.orders import TrailingStopMarketOrder

order: TrailingStopMarketOrder = self.order_factory.trailing_stop_market(
    instrument_id=InstrumentId.from_str("ETHUSD-PERP.BINANCE"),
    order_side=OrderSide.SELL,
    quantity=Quantity.from_int(10),
    activation_price=Price.from_str("5_000"),
    trigger_type=TriggerType.LAST_PRICE,
    trailing_offset=Decimal(100),
    trailing_offset_type=TrailingOffsetType.BASIS_POINTS,
    time_in_force=TimeInForce.GTC,
    expire_time=None,
    reduce_only=True,
    tags=["TRAILING_STOP-1"],
)
```
`trailing_stop_market(instrument_id, order_side, quantity, trailing_offset, activation_price=None, trigger_price=None, trigger_type=DEFAULT, trailing_offset_type=PRICE, time_in_force=GTC, expire_time=None, reduce_only=False, tags=None) -> TrailingStopMarketOrder`. `trailing_offset` is a **required `Decimal` positional**; `trailing_offset_type` defaults to `PRICE`, `trigger_type` to `DEFAULT`. Only `trailing_offset` (no `limit_offset`).

### Trailing-Stop-Limit
```python
order: TrailingStopLimitOrder = self.order_factory.trailing_stop_limit(
    instrument_id=InstrumentId.from_str("AUD/USD.CURRENEX"),
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(1_250_000),
    price=Price.from_str("0.71000"),
    activation_price=Price.from_str("0.72000"),
    trigger_type=TriggerType.BID_ASK,
    limit_offset=Decimal("0.00050"),
    trailing_offset=Decimal("0.00100"),
    trailing_offset_type=TrailingOffsetType.PRICE,
    time_in_force=TimeInForce.GTC,
    expire_time=None,
    reduce_only=True,
    tags=["TRAILING_STOP"],
)
```
`trailing_stop_limit(instrument_id, order_side, quantity, limit_offset, trailing_offset, price=None, activation_price=None, trigger_price=None, trigger_type=DEFAULT, trailing_offset_type=PRICE, time_in_force=GTC, expire_time=None, reduce_only=False, tags=None) -> TrailingStopLimitOrder`. `limit_offset` and `trailing_offset` are both **required `Decimal` positionals**; `trailing_offset_type` defaults to `PRICE`, `trigger_type` to `DEFAULT`. `trailing_offset` = how far the trigger trails; `limit_offset` = limit-price offset from trigger. Both trigger and limit update with the market until triggered. Use `Decimal` for offsets.

## Execution Instructions & Options

| Param | Type | Meaning |
|---|---|---|
| `post_only` | bool | Order only **provides** (maker) liquidity; if it would cross the book it is rejected, never executed as taker. |
| `reduce_only` | bool | Order can only **reduce** an existing position; cannot open or flip exposure. Use for exits/TP/SL. |
| `display_qty` | Quantity\|None | Iceberg: displayed portion. `None` = full display; a smaller value hides the rest. |
| `quote_quantity` | bool | Interpret `quantity` in quote-currency terms (venue-dependent; converted to base at execution). |
| `trigger_type` | TriggerType | Which price feed triggers a conditional/stop order. |
| `trigger_price` | Price | Level that triggers a stop / if-touched order. |
| `activation_price` | Price | Level at which a trailing stop begins trailing. |
| `trailing_offset` / `limit_offset` | Decimal | Trail distance / limit offset. |
| `trailing_offset_type` | TrailingOffsetType | Units of the offset. |
| `emulation_trigger` | TriggerType | If set, order is held/emulated locally (see below). |
| `tags` | list[str] | Free-form labels (e.g. `["ENTRY"]`). |

### TimeInForce
`from nautilus_trader.model.enums import TimeInForce`

| Value | Meaning |
|---|---|
| `GTC` | Good-Till-Canceled (default). |
| `IOC` | Immediate-Or-Cancel — fill what you can now, cancel the rest. |
| `FOK` | Fill-Or-Kill — fill entirely now or cancel. |
| `GTD` | Good-Till-Date — **requires `expire_time`** (a `pd.Timestamp`). |
| `DAY` | Valid for the trading day. |
| `AT_THE_OPEN` | Active at market open. |
| `AT_THE_CLOSE` | Active at market close. |

### TriggerType
`DEFAULT` (venue/emulator chooses), `LAST_PRICE`, `BID_ASK`, `DOUBLE_LAST`, `DOUBLE_BID_ASK`, `LAST_OR_BID_ASK`, `MID_POINT`, `MARK_PRICE`, `INDEX_PRICE`. (`NO_TRIGGER` is used internally for non-triggered orders.)

### TrailingOffsetType
`NO_TRAILING_OFFSET`, `PRICE` (absolute price points), `BASIS_POINTS` (bps of market price), `TICKS`, `PRICE_TIER`. **There is no `DEFAULT` member** — the `OrderFactory` trailing-stop methods default `trailing_offset_type=PRICE`. Same numeric offset means very different distances depending on type.

## Order Lists, Brackets & Contingencies

An `OrderList` groups linked orders under a shared `order_list_id` with a `ContingencyType` (FIX tag 1385):

| ContingencyType | Behavior |
|---|---|
| `OTO` (One-Triggers-Other) | Child orders activate when the parent (entry) fills. |
| `OCO` (One-Cancels-Other) | Filling/canceling one cancels the others. |
| `OUO` (One-Updates-Other) | Updating one order updates the linked orders. |

### Bracket order
```python
from nautilus_trader.model.orders import OrderList

bracket: OrderList = self.order_factory.bracket(
    instrument_id=InstrumentId.from_str("ETHUSDT-PERP.BINANCE"),
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(10),
    tp_price=Price.from_str("3300.00"),          # take-profit LIMIT (default)
    sl_trigger_price=Price.from_str("2800.00"),  # stop-loss STOP_MARKET (default)
)
self.submit_order_list(bracket)
```
Bundles `[entry, stop-loss, take-profit]` with contingency linkage. `tp_price` defaults to a LIMIT take-profit; `sl_trigger_price` defaults to a STOP_MARKET stop-loss. Submit the whole list with `self.submit_order_list(order_list)`.

**OTO trigger mode (backtest):** `BacktestVenueConfig.oto_trigger_mode` defaults to `"PARTIAL"` — children release pro-rata with each partial fill. Set `"FULL"` to release children only after the parent is **completely** filled (protection tradeoff: FULL exposes an unprotected window until the parent completes; PARTIAL protects sooner).

## Emulated Orders

When a venue lacks native support for an order type, set `emulation_trigger=<TriggerType>` so the local `OrderEmulator` holds the order (status `EMULATED`) and releases it as a plain MARKET/LIMIT once its trigger condition is met against subscribed market data (via a `MatchingCore`). Query emulated orders through the **Cache**, never a Python reference:

- `cache.orders_emulated(...)` — all currently emulated orders
- `cache.is_order_emulated(...)` — is a given order emulated
- `cache.orders_emulated_count(...)` — count
- `order.is_emulated` — property (bool)

**Emulatable types:** LIMIT, STOP_MARKET, STOP_LIMIT, MARKET_IF_TOUCHED, LIMIT_IF_TOUCHED, TRAILING_STOP_MARKET, TRAILING_STOP_LIMIT. **Not emulatable:** MARKET, MARKET_TO_LIMIT.

**Release transformation:** on release `emulation_trigger` is set to `NONE` and the type changes —
- LIMIT / MARKET_IF_TOUCHED / STOP_MARKET / TRAILING_STOP_MARKET → release as **MARKET**
- STOP_LIMIT / LIMIT_IF_TOUCHED / TRAILING_STOP_LIMIT → release as **LIMIT**

The client order ID is retained for the entire lifecycle. Emulated orders pass risk checks **twice**: at submission (before reaching the emulator) and again at release (before the ExecutionEngine/venue).

## Order Lifecycle (OrderStatus)

`from nautilus_trader.model.enums import OrderStatus`

States: `INITIALIZED`, `DENIED`, `EMULATED`, `RELEASED`, `SUBMITTED`, `ACCEPTED`, `REJECTED`, `CANCELED`, `EXPIRED`, `TRIGGERED`, `PENDING_UPDATE`, `PENDING_CANCEL`, `PARTIALLY_FILLED`, `FILLED`.

Typical event sequence (events are `OrderInitialized`, `OrderSubmitted`, `OrderAccepted`, `OrderRejected`, `OrderCanceled`, `OrderTriggered`, `OrderFilled`, ...):

```
Initialized ──> Submitted ──> Accepted ──> (PartiallyFilled) ──> Filled
                    │              │
                    │              ├──> Canceled
                    │              └──> Triggered ──> Filled   (stop/conditional)
                    └──> Rejected
Initialized ──> Denied                          (failed local risk checks)
Initialized ──> Emulated ──> Released ──> Submitted ...   (emulated path)
```

**Status categories** (query the right set):

| Category | States |
|---|---|
| Active local | `INITIALIZED`, `EMULATED`, `RELEASED` |
| In-flight | `SUBMITTED`, `PENDING_UPDATE`, `PENDING_CANCEL` |
| Open (working) | `ACCEPTED`, `TRIGGERED`, `PENDING_UPDATE`, `PENDING_CANCEL`, `PARTIALLY_FILLED` |
| Closed / terminal | `DENIED`, `REJECTED`, `CANCELED`, `EXPIRED`, `FILLED` |

## Submit / Modify / Cancel

From within a `Strategy`:
- `self.submit_order(order)` — submit a single order.
- `self.submit_order_list(order_list)` — submit a bracket / contingency group atomically.
- Modify (amend price/qty/trigger) and cancel via the strategy's order-management methods (e.g. `self.modify_order(...)`, `self.cancel_order(...)`, `self.cancel_all_orders(...)`); the venue moves the order through `PENDING_UPDATE` / `PENDING_CANCEL`. See [strategies](strategies.md) and [execution](execution.md).

## Grammar tables

| Type | Format | Examples |
|---|---|---|
| `InstrumentId` | `{symbol}.{VENUE}` | `BTCUSDT-PERP.BINANCE`, `ETHUSDT-PERP.BINANCE`, `USD/JPY.IDEALPRO`, `AUD/USD.CURRENEX`, `AUD/USD.IDEALPRO` |

## Gotchas

- **Unsupported instruction → order not submitted.** Nautilus will NOT silently drop an unsupported instruction/TIF/option; it refuses to submit and logs an explanatory error. → Confirm the venue/adapter supports the order type, TIF, and options (`post_only`, `reduce_only`, `display_qty`, `trigger_type`, ...) before submitting, or use emulation.
- **`GTD` without `expire_time`.** GTD needs an expiry timestamp to know when to cancel the remainder. → Always pass `expire_time=pd.Timestamp(...)` with `TimeInForce.GTD`.
- **`post_only` treated as a hint.** A `post_only` order that would take liquidity is **rejected**, not executed as taker. → Use `post_only=True` only on passive resting limits.
- **`reduce_only` expected to open/flip.** It can only reduce existing exposure. → Use it for exits/TP/SL; use a normal order to open.
- **`display_qty=None` thought to hide the order.** `None` = full display. → Set a smaller `display_qty` for iceberg behavior.
- **Trusting a Market / Stop-Market / Market-If-Touched fill to equal a known price.** They place plain MARKET orders — slippage in fast/gapping markets. → Use the LIMIT / Stop-Limit / *-If-Touched-Limit variants when a worst-fill cap matters.
- **Assuming Stop-Limit / Limit-If-Touched / Trailing-Stop-Limit always fill once triggered.** After triggering they place a LIMIT; a gap through the limit leaves the position unprotected. → Use the market-based variant when guaranteed exit matters more than price.
- **Confusing `trailing_offset` with `limit_offset`.** `trailing_offset` sets trigger trail distance; `limit_offset` sets limit placement relative to trigger. `trailing_stop_market` has only `trailing_offset`. → Set both explicitly on trailing-stop-limit.
- **Misreading offset units.** Magnitude depends on `trailing_offset_type` (`PRICE` = absolute points, `BASIS_POINTS` = bps). → Always pair the `Decimal` offset with the intended `TrailingOffsetType`; use `Decimal` to avoid float error.
- **Holding a Python reference to an emulated order.** On release the object transforms (type changes, new `OrderInitialized` applied) — the reference goes stale. → Always query via the Cache by client order ID.
- **Trying to emulate MARKET / MARKET_TO_LIMIT.** These cannot be emulated. → Only set `emulation_trigger` on emulatable types.
- **Ignoring `OrderDenied` / `OrderRejected` on contingent legs.** A rejected protective child (e.g. insufficient margin) while the entry fills leaves the position unprotected. Children auto-cancel if the parent is canceled, but a *rejected* protective child must be handled explicitly. → Handle both events for brackets/contingencies.
- **Mixed-instrument order lists.** Contingent risk checks apply a single-instrument bound (from the first order's `instrument_id`); position-based requests are denied across instruments, and some adapters misroute non-first orders. → Keep an order list to one instrument when relying on position-based requests.
- **Default backtest OTO releases children pro-rata (`PARTIAL`), not after full fill.** Full-trigger exposes an unprotected window. → Set `oto_trigger_mode="FULL"` on the venue config if you want children only after the parent completes.
- **Forgetting emulated orders pass risk checks twice** (submission + release) — denial can occur at either stage.
- **Overlooking bracket order margin.** Protective legs consume additional order margin beyond a bare entry. → Budget for it.

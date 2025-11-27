# Orders Guide

## Overview

NautilusTrader supports a comprehensive set of order types, from basic market and limit orders to advanced contingent orders. Orders are created using the `OrderFactory` and submitted through strategies.

**Location:** `nautilus_trader.model.orders`

## Order Types

### Market Order

Executes immediately at the best available price.

```python
from nautilus_trader.model.enums import OrderSide
from nautilus_trader.model.objects import Quantity

order = self.order_factory.market(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
)
self.submit_order(order)
```

### Limit Order

Executes at specified price or better.

```python
from nautilus_trader.model.enums import TimeInForce
from nautilus_trader.model.objects import Price

order = self.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.00"),
    time_in_force=TimeInForce.GTC,  # Good Till Cancelled
)
```

### Stop Market Order

Triggers a market order when price reaches trigger level.

```python
order = self.order_factory.stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.00"),
    trigger_type=TriggerType.LAST_PRICE,
)
```

### Stop Limit Order

Triggers a limit order when price reaches trigger level.

```python
order = self.order_factory.stop_limit(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.00"),
    price=Price.from_str("48900.00"),  # Limit price after trigger
    trigger_type=TriggerType.LAST_PRICE,
)
```

### Limit If Touched (LIT)

Triggers a limit order when price touches a level (opposite direction of stop).

```python
order = self.order_factory.limit_if_touched(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49500.00"),
    price=Price.from_str("49600.00"),
)
```

### Market If Touched (MIT)

Triggers a market order when price touches a level.

```python
order = self.order_factory.market_if_touched(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49500.00"),
)
```

### Trailing Stop Market

Stop that follows price at a fixed distance.

```python
from nautilus_trader.model.objects import Price

order = self.order_factory.trailing_stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.00"),
    trailing_offset=Price.from_str("500.00"),  # Trail by $500
    trailing_offset_type=TrailingOffsetType.PRICE,
)
```

### Trailing Stop Limit

Trailing stop with limit order after trigger.

```python
order = self.order_factory.trailing_stop_limit(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.00"),
    price=Price.from_str("48900.00"),
    trailing_offset=Price.from_str("500.00"),
    trailing_offset_type=TrailingOffsetType.PRICE,
)
```

## Time In Force Options

```python
from nautilus_trader.model.enums import TimeInForce

TimeInForce.GTC   # Good Till Cancelled
TimeInForce.IOC   # Immediate Or Cancel
TimeInForce.FOK   # Fill Or Kill
TimeInForce.DAY   # Day order (expires at session close)
TimeInForce.GTD   # Good Till Date (specify expire_time)
TimeInForce.AT_THE_OPEN   # Execute at market open
TimeInForce.AT_THE_CLOSE  # Execute at market close
```

### GTD Example

```python
import pandas as pd

order = self.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.00"),
    time_in_force=TimeInForce.GTD,
    expire_time=pd.Timestamp("2024-12-31 23:59:59", tz="UTC"),
)
```

## Trigger Types

```python
from nautilus_trader.model.enums import TriggerType

TriggerType.DEFAULT      # Venue default
TriggerType.LAST_PRICE   # Last trade price
TriggerType.BID_ASK      # Bid for sells, ask for buys
TriggerType.DOUBLE_LAST  # Two consecutive prices through trigger
TriggerType.DOUBLE_BID_ASK  # Two consecutive bid/ask through trigger
TriggerType.MID_POINT    # Mid-point of bid/ask
TriggerType.MARK_PRICE   # Mark price (derivatives)
TriggerType.INDEX_PRICE  # Index price (derivatives)
```

## Contingent Orders

### One-Cancels-Other (OCO)

When one order fills, the other is cancelled.

```python
# Take profit order
tp_order = self.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("55000.00"),
    contingency_type=ContingencyType.OCO,
)

# Stop loss order (linked to TP)
sl_order = self.order_factory.stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("48000.00"),
    contingency_type=ContingencyType.OCO,
    linked_order_ids=[tp_order.client_order_id],
)

# Link TP to SL
tp_order.linked_order_ids = [sl_order.client_order_id]

# Submit both
self.submit_order(tp_order)
self.submit_order(sl_order)
```

### One-Triggers-Other (OTO)

When one order fills, another is activated.

```python
# Entry order
entry = self.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.00"),
)

# Stop loss (triggers when entry fills)
stop_loss = self.order_factory.stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("48000.00"),
    contingency_type=ContingencyType.OTO,
    linked_order_ids=[entry.client_order_id],
)

self.submit_order(entry)
# Stop loss is submitted automatically when entry fills
```

### Bracket Order (Entry + TP + SL)

```python
def submit_bracket(self, entry_price, stop_price, target_price):
    # Entry order
    entry = self.order_factory.limit(
        instrument_id=self.instrument_id,
        order_side=OrderSide.BUY,
        quantity=self.qty,
        price=entry_price,
    )

    # Stop loss (OTO from entry)
    stop = self.order_factory.stop_market(
        instrument_id=self.instrument_id,
        order_side=OrderSide.SELL,
        quantity=self.qty,
        trigger_price=stop_price,
        contingency_type=ContingencyType.OTO,
        linked_order_ids=[entry.client_order_id],
    )

    # Take profit (OTO from entry, OCO with stop)
    target = self.order_factory.limit(
        instrument_id=self.instrument_id,
        order_side=OrderSide.SELL,
        quantity=self.qty,
        price=target_price,
        contingency_type=ContingencyType.OUO,  # One-Updates-Other
        linked_order_ids=[entry.client_order_id, stop.client_order_id],
    )

    self.submit_order(entry)
```

## OrderFactory

The strategy provides an `order_factory` for creating orders with automatic ID generation.

```python
class MyStrategy(Strategy):

    def on_bar(self, bar):
        # OrderFactory is accessed via self.order_factory
        order = self.order_factory.market(
            instrument_id=bar.bar_type.instrument_id,
            order_side=OrderSide.BUY,
            quantity=Quantity.from_str("1.0"),
        )

        # Order has auto-generated client_order_id
        self.log.info(f"Order ID: {order.client_order_id}")

        self.submit_order(order)
```

### Additional OrderFactory Parameters

```python
order = self.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.00"),

    # Optional parameters
    time_in_force=TimeInForce.GTC,
    post_only=True,           # Maker only (no taker fills)
    reduce_only=True,         # Only reduce position
    display_qty=Quantity.from_str("0.1"),  # Iceberg display quantity
    tags=["entry", "swing"],  # Custom tags for tracking
)
```

## Order Management

### Submit Order

```python
def submit_order(self, order):
    """Submit order through strategy."""
    self.submit_order(order)
```

### Cancel Order

```python
def cancel_order(self, client_order_id):
    order = self.cache.order(client_order_id)
    if order and order.is_open:
        self.cancel_order(order)
```

### Modify Order

```python
def modify_order(self, client_order_id, new_qty=None, new_price=None):
    order = self.cache.order(client_order_id)
    if order and order.is_open:
        self.modify_order(
            order=order,
            quantity=new_qty,
            price=new_price,
        )
```

### Cancel All Orders

```python
# Cancel all open orders
self.cancel_all_orders()

# Cancel for specific instrument
self.cancel_all_orders(instrument_id=self.instrument_id)
```

## Order Events

### Event Handlers

```python
def on_order_submitted(self, event: OrderSubmitted):
    """Order sent to venue."""
    self.log.info(f"Submitted: {event.client_order_id}")

def on_order_accepted(self, event: OrderAccepted):
    """Venue acknowledged order."""
    self.log.info(f"Accepted: {event.client_order_id}")

def on_order_rejected(self, event: OrderRejected):
    """Venue rejected order."""
    self.log.error(f"Rejected: {event.client_order_id} - {event.reason}")

def on_order_cancelled(self, event: OrderCancelled):
    """Order cancelled."""
    self.log.info(f"Cancelled: {event.client_order_id}")

def on_order_expired(self, event: OrderExpired):
    """Order expired (GTD/DAY)."""
    self.log.info(f"Expired: {event.client_order_id}")

def on_order_triggered(self, event: OrderTriggered):
    """Stop/trigger order triggered."""
    self.log.info(f"Triggered: {event.client_order_id}")

def on_order_filled(self, event: OrderFilled):
    """Order filled (partial or complete)."""
    self.log.info(f"Filled: {event.last_qty} @ {event.last_px}")

def on_order_updated(self, event: OrderUpdated):
    """Order modified."""
    self.log.info(f"Updated: {event.client_order_id}")

def on_order_denied(self, event: OrderDenied):
    """Order denied by risk engine."""
    self.log.error(f"Denied: {event.reason}")
```

### Order States

```python
from nautilus_trader.model.enums import OrderStatus

OrderStatus.INITIALIZED   # Created, not submitted
OrderStatus.DENIED        # Denied by risk engine
OrderStatus.EMULATED      # Held by order emulator
OrderStatus.RELEASED      # Released from emulator
OrderStatus.SUBMITTED     # Sent to venue
OrderStatus.ACCEPTED      # Acknowledged by venue
OrderStatus.REJECTED      # Rejected by venue
OrderStatus.CANCELED      # Cancelled
OrderStatus.EXPIRED       # Expired (GTD/DAY)
OrderStatus.TRIGGERED     # Stop triggered
OrderStatus.PENDING_UPDATE  # Modification pending
OrderStatus.PENDING_CANCEL  # Cancellation pending
OrderStatus.PARTIALLY_FILLED  # Partially filled
OrderStatus.FILLED        # Completely filled
```

### Check Order State

```python
order = self.cache.order(client_order_id)

if order:
    # State checks
    is_open = order.is_open           # Working at venue
    is_closed = order.is_closed       # Terminal state
    is_pending = order.is_pending     # Pending modification/cancel
    is_emulated = order.is_emulated   # Held by emulator

    # Quantity info
    total_qty = order.quantity
    filled_qty = order.filled_qty
    leaves_qty = order.leaves_qty     # Remaining to fill

    # Price info (for limit orders)
    price = order.price
    avg_px = order.avg_px             # Average fill price
```

## Order Emulation

Some order types are emulated client-side when venues don't support them natively.

### Emulated Order Types

- Trailing stops (most venues)
- GTD orders (some venues)
- Complex contingent orders

### Configuration

```python
from nautilus_trader.config import ExecEngineConfig

exec_config = ExecEngineConfig(
    load_cache=True,
    allow_cash_positions=True,
)
```

### Check Emulated Orders

```python
# Get all emulated orders
emulated = self.cache.orders_emulated()

# Count
count = self.cache.orders_emulated_count()
```

## Common Patterns

### 1. Entry with Stop Loss

```python
def enter_with_stop(self, side, entry_price, stop_price):
    qty = self.calculate_position_size()

    # Entry order
    entry = self.order_factory.limit(
        instrument_id=self.instrument_id,
        order_side=side,
        quantity=qty,
        price=entry_price,
    )

    # Store for later stop placement
    self.pending_entry = entry.client_order_id
    self.pending_stop_price = stop_price

    self.submit_order(entry)

def on_order_filled(self, event: OrderFilled):
    if event.client_order_id == self.pending_entry:
        # Place stop after entry fills
        stop_side = OrderSide.SELL if event.order_side == OrderSide.BUY else OrderSide.BUY

        stop = self.order_factory.stop_market(
            instrument_id=self.instrument_id,
            order_side=stop_side,
            quantity=event.last_qty,
            trigger_price=self.pending_stop_price,
        )
        self.submit_order(stop)
```

### 2. Scale-In Orders

```python
def scale_in(self, levels: list[tuple[Price, Quantity]]):
    """Place multiple limit orders at different levels."""
    for price, qty in levels:
        order = self.order_factory.limit(
            instrument_id=self.instrument_id,
            order_side=OrderSide.BUY,
            quantity=qty,
            price=price,
            tags=["scale_in"],
        )
        self.submit_order(order)
```

### 3. Order Tracking

```python
class OrderTracker:
    def __init__(self):
        self.orders: dict[ClientOrderId, str] = {}

    def track(self, order, label: str):
        self.orders[order.client_order_id] = label

    def get_label(self, client_order_id) -> str:
        return self.orders.get(client_order_id, "unknown")

    def remove(self, client_order_id):
        self.orders.pop(client_order_id, None)
```

## Next Steps

- **Execution flow:** Read `execution.md`
- **Position management:** Read `portfolio.md`
- **Strategy development:** Read `strategy-development.md`
- **Best practices:** Read `best-practices.md`

## Additional Resources

- **Orders Docs:** https://nautilustrader.io/docs/latest/concepts/orders/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/model/orders/

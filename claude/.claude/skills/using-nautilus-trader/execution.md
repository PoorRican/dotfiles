# Execution Flow Guide

## Overview

NautilusTrader's execution system handles the complete lifecycle of orders from strategy submission to venue execution and back. The flow passes through multiple components that validate, route, and track orders.

## Execution Flow Diagram

```
┌─────────────┐
│  Strategy   │
│ submit_order│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ RiskEngine  │ ← Pre-trade risk checks
│  validate   │
└──────┬──────┘
       │ (approved)
       ▼
┌─────────────┐
│  Execution  │ ← Order routing & tracking
│   Engine    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Order     │ ← Client-side order types (optional)
│  Emulator   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Execution  │ ← Venue adapter
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Venue/    │ ← Exchange/Broker
│  Exchange   │
└─────────────┘
```

## Components

### 1. RiskEngine

**Location:** `nautilus_trader.risk.engine`

The RiskEngine performs pre-trade risk checks before orders reach the ExecutionEngine.

#### Risk Checks

```python
from nautilus_trader.config import RiskEngineConfig

risk_config = RiskEngineConfig(
    bypass=False,  # NEVER bypass in production

    # Rate limits
    max_order_submit_rate=100,   # Orders per second
    max_order_modify_rate=50,    # Modifications per second

    # Notional limits per instrument
    max_notionals={
        "BTCUSDT.BINANCE": 100_000.0,  # Max $100k per order
        "ETHUSDT.BINANCE": 50_000.0,
    },

    # Position limits (optional)
    max_positions={
        "BTCUSDT.BINANCE": 10.0,  # Max 10 BTC position
    },
)
```

#### What Gets Checked

1. **Order rate limiting** - Prevents excessive order submission
2. **Notional value limits** - Caps order value per instrument
3. **Position limits** - Prevents exceeding max position size
4. **Account balance** - Ensures sufficient funds
5. **Custom rules** - User-defined risk logic

#### Rejection Flow

```
Order submitted → RiskEngine → [DENIED] → OrderDenied event → Strategy notified
                            → [APPROVED] → ExecutionEngine
```

### 2. ExecutionEngine

**Location:** `nautilus_trader.execution.engine`

The ExecutionEngine is the central order management component.

#### Responsibilities

- Order validation and normalization
- Order routing to correct venue
- Order state tracking
- Event generation and distribution
- Execution report processing

#### Order Lifecycle States

```
INITIALIZED → SUBMITTED → ACCEPTED → [FILLED | CANCELLED | EXPIRED | REJECTED]
                                   → PARTIALLY_FILLED → [FILLED | CANCELLED]
```

### 3. OrderEmulator

**Location:** `nautilus_trader.execution.emulator`

The OrderEmulator enables client-side order types not supported by venues.

#### Emulated Order Types

- **Trailing Stop** - Stop that follows price
- **Bracket Orders** - Entry with TP/SL
- **Time-based Orders** - GTD with specific expiry
- **Synthetic Orders** - Orders on synthetic instruments

#### How Emulation Works

```
Strategy submits TrailingStopOrder
        │
        ▼
ExecutionEngine detects emulation needed
        │
        ▼
OrderEmulator holds order locally
        │
        ▼
OrderEmulator monitors market data
        │
        ▼
Trigger condition met
        │
        ▼
OrderEmulator submits real order to venue
```

#### Configuration

```python
from nautilus_trader.config import ExecEngineConfig

exec_config = ExecEngineConfig(
    load_cache=True,
    allow_cash_positions=True,
    debug=False,
)
```

### 4. ExecutionClient

**Location:** `nautilus_trader.execution.client`

ExecutionClients are venue-specific adapters that communicate with exchanges.

#### Responsibilities

- API authentication
- Order submission to venue
- Order modification/cancellation
- Execution report parsing
- WebSocket connection management

## Order Submission Flow

### 1. Strategy Submits Order

```python
class MyStrategy(Strategy):

    def on_bar(self, bar: Bar):
        # Create order
        order = self.order_factory.market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.BUY,
            quantity=Quantity.from_str("1.0"),
        )

        # Submit - triggers execution flow
        self.submit_order(order)
```

### 2. Order Events Generated

```python
def on_order_submitted(self, event: OrderSubmitted):
    """Order sent to venue."""
    self.log.info(f"Order submitted: {event.client_order_id}")

def on_order_accepted(self, event: OrderAccepted):
    """Venue acknowledged order."""
    self.log.info(f"Order accepted: {event.client_order_id}")

def on_order_rejected(self, event: OrderRejected):
    """Venue rejected order."""
    self.log.error(f"Order rejected: {event.reason}")

def on_order_filled(self, event: OrderFilled):
    """Order (partially) filled."""
    self.log.info(f"Filled {event.last_qty} @ {event.last_px}")

def on_order_cancelled(self, event: OrderCancelled):
    """Order cancelled."""
    self.log.info(f"Order cancelled: {event.client_order_id}")
```

### 3. Complete Event Flow

```
submit_order()
    │
    ├─→ OrderInitialized (internal)
    │
    ├─→ [RiskEngine check]
    │       │
    │       ├─→ OrderDenied (if failed)
    │       │
    │       └─→ Continue (if passed)
    │
    ├─→ OrderSubmitted
    │
    ├─→ [Venue response]
    │       │
    │       ├─→ OrderAccepted
    │       │       │
    │       │       ├─→ OrderFilled (complete)
    │       │       │
    │       │       ├─→ OrderPartiallyFilled → OrderFilled
    │       │       │
    │       │       ├─→ OrderCancelled
    │       │       │
    │       │       └─→ OrderExpired
    │       │
    │       └─→ OrderRejected
```

## OMS Types

### NETTING (Crypto-style)

Single position per instrument. New orders adjust the existing position.

```python
from nautilus_trader.model.enums import OmsType

# Configure venue with NETTING
BacktestVenueConfig(
    name="BINANCE",
    oms_type=OmsType.NETTING,
    # ...
)
```

**Behavior:**
- Buy 1 BTC → Position: +1 BTC
- Buy 0.5 BTC → Position: +1.5 BTC
- Sell 2 BTC → Position: -0.5 BTC (short)

### HEDGING (Traditional Futures-style)

Multiple independent positions per instrument.

```python
BacktestVenueConfig(
    name="CME",
    oms_type=OmsType.HEDGING,
    # ...
)
```

**Behavior:**
- Open long 1 BTC → Position 1: +1 BTC
- Open short 0.5 BTC → Position 2: -0.5 BTC
- Both positions exist independently

## Execution Algorithms

### Built-in: TWAP (Time-Weighted Average Price)

**Location:** `nautilus_trader.execution.algorithm`

Splits large orders over time to minimize market impact.

```python
from nautilus_trader.execution.algorithm import TWAPExecAlgorithm
from nautilus_trader.config import TWAPExecAlgorithmConfig

# Configure TWAP
twap_config = TWAPExecAlgorithmConfig(
    exec_algorithm_id="TWAP-001",
    exec_spawn_id="TWAP_SPAWNER",
)

# In strategy
def execute_twap(self, instrument_id, quantity, duration_secs):
    order = self.order_factory.market(
        instrument_id=instrument_id,
        order_side=OrderSide.BUY,
        quantity=quantity,
        exec_algorithm_id=ExecAlgorithmId("TWAP-001"),
        exec_algorithm_params={
            "horizon_secs": duration_secs,
            "interval_secs": 60,  # Child order every 60 seconds
        },
    )
    self.submit_order(order)
```

### Custom Execution Algorithm

```python
from nautilus_trader.execution.algorithm import ExecAlgorithm
from nautilus_trader.config import ExecAlgorithmConfig

class ICEBERGConfig(ExecAlgorithmConfig):
    """Configuration for iceberg algorithm."""
    display_qty: float
    total_qty: float

class ICEBERGExecAlgorithm(ExecAlgorithm):
    """
    Iceberg algorithm that shows only a portion of the order.
    """

    def __init__(self, config: ICEBERGConfig):
        super().__init__(config)
        self.display_qty = Quantity.from_str(str(config.display_qty))
        self.total_qty = Quantity.from_str(str(config.total_qty))
        self.filled_qty = Quantity.zero()

    def on_start(self):
        """Initialize algorithm."""
        self.submit_child_order()

    def on_order_filled(self, event: OrderFilled):
        """Handle child order fill."""
        self.filled_qty = Quantity.from_raw(
            self.filled_qty.raw + event.last_qty.raw,
            self.filled_qty.precision,
        )

        remaining = self.total_qty.raw - self.filled_qty.raw
        if remaining > 0:
            self.submit_child_order()
        else:
            self.stop()

    def submit_child_order(self):
        """Submit next iceberg slice."""
        remaining = self.total_qty.raw - self.filled_qty.raw
        qty = min(self.display_qty.raw, remaining)

        order = self.order_factory.limit(
            instrument_id=self.instrument_id,
            order_side=self.order_side,
            quantity=Quantity.from_raw(qty, self.display_qty.precision),
            price=self.limit_price,
        )
        self.submit_order(order)
```

## Order Modification

### Modify Order

```python
def modify_existing_order(self):
    # Get order from cache
    order = self.cache.order(self.pending_order_id)

    if order and order.is_open:
        self.modify_order(
            order=order,
            quantity=Quantity.from_str("2.0"),  # New quantity
            price=Price.from_str("51000.0"),     # New price (for limit)
        )

def on_order_updated(self, event: OrderUpdated):
    """Handle order modification confirmation."""
    self.log.info(f"Order updated: {event.client_order_id}")
```

### Cancel Order

```python
def cancel_existing_order(self):
    order = self.cache.order(self.pending_order_id)

    if order and order.is_open:
        self.cancel_order(order)

def on_order_cancelled(self, event: OrderCancelled):
    """Handle order cancellation confirmation."""
    self.log.info(f"Order cancelled: {event.client_order_id}")
```

### Cancel All Orders

```python
def cancel_all(self):
    # Cancel all open orders
    self.cancel_all_orders()

    # Cancel for specific instrument
    self.cancel_all_orders(instrument_id=self.instrument_id)

    # Cancel for specific strategy
    self.cancel_all_orders(strategy_id=self.id)
```

## Position Management

### Close Position

```python
def close_current_position(self):
    # Get position
    positions = self.cache.positions_open(instrument_id=self.instrument_id)

    for position in positions:
        self.close_position(position)

def on_position_closed(self, event: PositionClosed):
    """Handle position close."""
    self.log.info(f"Position closed: {event.position_id}")
    self.log.info(f"Realized PnL: {event.realized_pnl}")
```

### Close All Positions

```python
def close_all(self):
    # Close all positions
    self.close_all_positions()

    # Close for specific instrument
    self.close_all_positions(instrument_id=self.instrument_id)

    # Close for specific strategy
    self.close_all_positions(strategy_id=self.id)
```

## Execution Reconciliation

### Live Trading Reconciliation

On startup, the LiveExecutionEngine reconciles cached state with venue state:

```
Startup
    │
    ├─→ Load cached orders and positions
    │
    ├─→ Request venue state (open orders, positions)
    │
    ├─→ Compare cached vs venue state
    │
    ├─→ Generate events for any differences:
    │       • Missing fills
    │       • Cancelled orders
    │       • Position adjustments
    │
    └─→ State synchronized
```

### Configuration

```python
from nautilus_trader.config import LiveExecEngineConfig

exec_config = LiveExecEngineConfig(
    reconciliation=True,           # Enable reconciliation
    reconciliation_lookback_mins=60,  # How far back to look
    inflight_check_interval_ms=1000,  # Check interval
)
```

## Common Patterns

### 1. Bracket Order (Entry + TP + SL)

```python
def submit_bracket_order(self, entry_price, stop_loss, take_profit):
    # Entry order
    entry = self.order_factory.limit(
        instrument_id=self.instrument_id,
        order_side=OrderSide.BUY,
        quantity=self.position_size,
        price=entry_price,
    )

    # Stop loss (linked to entry)
    stop = self.order_factory.stop_market(
        instrument_id=self.instrument_id,
        order_side=OrderSide.SELL,
        quantity=self.position_size,
        trigger_price=stop_loss,
        linked_order_ids=[entry.client_order_id],
        contingency_type=ContingencyType.OTO,  # One-Triggers-Other
    )

    # Take profit (linked to entry, OCO with stop)
    tp = self.order_factory.limit(
        instrument_id=self.instrument_id,
        order_side=OrderSide.SELL,
        quantity=self.position_size,
        price=take_profit,
        linked_order_ids=[entry.client_order_id, stop.client_order_id],
        contingency_type=ContingencyType.OCO,  # One-Cancels-Other
    )

    # Submit entry (TP/SL activate when entry fills)
    self.submit_order(entry)
```

### 2. Position Scaling

```python
def scale_into_position(self):
    """Add to existing position."""
    current_qty = self.portfolio.net_position(self.instrument_id)

    if current_qty < self.max_position:
        add_qty = min(self.scale_size, self.max_position - current_qty)

        order = self.order_factory.market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.BUY,
            quantity=Quantity.from_str(str(add_qty)),
        )
        self.submit_order(order)

def scale_out_of_position(self, pct: float):
    """Reduce position by percentage."""
    current_qty = abs(self.portfolio.net_position(self.instrument_id))

    if current_qty > 0:
        reduce_qty = current_qty * pct

        order = self.order_factory.market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.SELL,
            quantity=Quantity.from_str(str(reduce_qty)),
        )
        self.submit_order(order)
```

### 3. Order Tracking

```python
class OrderTrackingStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.pending_orders: dict[ClientOrderId, str] = {}

    def on_order_accepted(self, event: OrderAccepted):
        order_type = self.pending_orders.get(event.client_order_id)
        self.log.info(f"{order_type} order accepted")

    def on_order_filled(self, event: OrderFilled):
        order_type = self.pending_orders.pop(event.client_order_id, "unknown")
        self.log.info(f"{order_type} order filled @ {event.last_px}")

    def on_order_rejected(self, event: OrderRejected):
        order_type = self.pending_orders.pop(event.client_order_id, "unknown")
        self.log.error(f"{order_type} order rejected: {event.reason}")

    def submit_entry(self):
        order = self.order_factory.market(...)
        self.pending_orders[order.client_order_id] = "ENTRY"
        self.submit_order(order)

    def submit_exit(self):
        order = self.order_factory.market(...)
        self.pending_orders[order.client_order_id] = "EXIT"
        self.submit_order(order)
```

## Next Steps

- **Order types:** Read `orders.md`
- **Risk management:** Read `best-practices.md`
- **Live deployment:** Read `live-trading.md`
- **Strategy development:** Read `strategy-development.md`

## Additional Resources

- **Execution Docs:** https://nautilustrader.io/docs/latest/concepts/execution/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/execution/
- **Order Types:** https://nautilustrader.io/docs/latest/concepts/orders/

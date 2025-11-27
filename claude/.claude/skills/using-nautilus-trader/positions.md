# Positions

Positions in NautilusTrader represent open exposure to instruments and are created automatically when orders are filled. This section covers position lifecycle, PnL calculations, and management patterns.

## Documentation Links

- **Concept Guide**: https://nautilustrader.io/docs/latest/concepts/positions/
- **API Reference - Position**: https://nautilustrader.io/docs/latest/api_reference/model/position/

## Source Code Locations

```
nautilus_trader/
├── model/
│   ├── position.py           # Position class
│   └── events/
│       └── position.py       # Position events
├── execution/
│   └── engine.py             # Position creation/updates
└── portfolio/
    └── portfolio.py          # Position aggregation
```

**Rust Core**:
```
crates/
└── model/
    └── src/
        └── position.rs       # Core position implementation
```

## Position Basics

### Position Lifecycle

```
Order Fill → Position Opened → Position Changed (fills) → Position Closed
```

1. **Opened**: First fill creates position
2. **Changed**: Subsequent fills modify position
3. **Closed**: Net quantity reaches zero

### Position Properties

```python
position = self.cache.position(position_id)

# Identification
position.id              # PositionId
position.instrument_id   # InstrumentId
position.strategy_id     # StrategyId
position.trader_id       # TraderId

# State
position.side            # PositionSide (FLAT, LONG, SHORT)
position.quantity        # Current quantity (Quantity)
position.signed_qty      # Signed quantity (positive=LONG, negative=SHORT)
position.is_open         # bool
position.is_closed       # bool

# Entry
position.entry_price     # Average entry price (Price)
position.avg_px_open     # Same as entry_price

# Timing
position.ts_opened       # UNIX timestamp when opened (nanoseconds)
position.ts_closed       # UNIX timestamp when closed (nanoseconds)
position.duration_ns     # Duration position was open (nanoseconds)

# Fill tracking
position.events          # List of all fill events
position.last_event      # Most recent event
```

## Position Events

### PositionOpened

```python
def on_position_opened(self, event: PositionOpened) -> None:
    """Handle new position."""
    self.log.info(
        f"Position opened: {event.instrument_id} "
        f"side={event.entry} qty={event.quantity} "
        f"price={event.avg_px_open}"
    )
    
    # Get full position from cache
    position = self.cache.position(event.position_id)
```

### PositionChanged

```python
def on_position_changed(self, event: PositionChanged) -> None:
    """Handle position modification."""
    self.log.info(
        f"Position changed: {event.instrument_id} "
        f"side={event.side} qty={event.quantity} "
        f"avg_px={event.avg_px_open}"
    )
```

### PositionClosed

```python
def on_position_closed(self, event: PositionClosed) -> None:
    """Handle position close."""
    self.log.info(
        f"Position closed: {event.instrument_id} "
        f"realized_pnl={event.realized_pnl} "
        f"duration={event.duration_ns / 1e9:.1f}s"
    )
```

### Generic Position Event Handler

```python
def on_event(self, event: Event) -> None:
    """Handle any event."""
    if isinstance(event, PositionEvent):
        position = self.cache.position(event.position_id)
        self.log.info(f"Position event: {event}")
```

## Querying Positions

### From Cache

```python
# Get position by ID
position = self.cache.position(position_id)

# Get position for an order
position = self.cache.position_for_order(client_order_id)

# Get all open positions
open_positions = self.cache.positions_open()

# Filter by instrument
instrument_positions = self.cache.positions_open(
    instrument_id=self.instrument_id
)

# Filter by strategy
strategy_positions = self.cache.positions_open(
    strategy_id=self.id
)

# Filter by venue
venue_positions = self.cache.positions_open(
    venue=Venue("BINANCE")
)

# Get closed positions
closed_positions = self.cache.positions_closed()

# Get all positions (open + closed)
all_positions = self.cache.positions()

# Position counts
open_count = self.cache.positions_open_count()
closed_count = self.cache.positions_closed_count()
total_count = self.cache.positions_total_count()
```

### From Portfolio

```python
# Check if net long/short/flat
is_long = self.portfolio.is_net_long(self.instrument_id)
is_short = self.portfolio.is_net_short(self.instrument_id)
is_flat = self.portfolio.is_flat(self.instrument_id)

# Get net position quantity (signed decimal)
net_qty = self.portfolio.net_position(self.instrument_id)

# Get net exposure
exposure = self.portfolio.net_exposure(self.instrument_id)
```

## PnL Calculations

### Unrealized PnL

```python
# From portfolio (aggregated across positions)
unrealized_pnl = self.portfolio.unrealized_pnl(self.instrument_id)

# From individual position (requires current price)
current_price = self.cache.price(position.instrument_id)
unrealized = position.unrealized_pnl(current_price)
```

### Realized PnL

```python
# From portfolio
realized_pnl = self.portfolio.realized_pnl(self.instrument_id)

# From position
realized = position.realized_pnl
```

### Total PnL

```python
# Unrealized + Realized
total_unrealized = self.portfolio.unrealized_pnls(venue)  # dict[Currency, Money]
total_realized = self.portfolio.realized_pnls(venue)      # dict[Currency, Money]
```

### Commissions

```python
# Get all commissions for position
commissions = position.commissions()  # list[Money]

# Total commission in quote currency
total_commission = sum(float(c) for c in commissions if c.currency == position.quote_currency)
```

### Notional Value

```python
# Get position notional value at current price
current_price = self.cache.price(position.instrument_id)
notional = position.notional_value(current_price)  # Money
```

## OMS Types and Positions

### NETTING (Default)

One position per instrument. New fills modify the single position.

```python
# Configure for NETTING
venue_config = BacktestVenueConfig(
    name="SIM",
    oms_type="NETTING",  # or OmsType.NETTING
    # ...
)
```

### HEDGING

Multiple positions per instrument (each with unique PositionId).

```python
# Configure for HEDGING
venue_config = BacktestVenueConfig(
    name="SIM",
    oms_type="HEDGING",  # or OmsType.HEDGING
    # ...
)

# When submitting orders, can specify position_id
order = self.order_factory.limit(
    instrument_id=self.instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.00"),
    position_id=PositionId("custom-position-1"),  # Assign to specific position
)
```

## Position Snapshots (NETTING OMS)

For NETTING OMS, position snapshots preserve historical PnL across position cycles:

```python
# Cycle 1: Open LONG, close LONG with $500 profit
# Snapshot preserves $500 realized PnL

# Cycle 2: Open SHORT, close SHORT with $100 profit
# Snapshot preserves $100 realized PnL

# Total realized PnL = $600 (from snapshots)

# Get position snapshots
snapshot = self.cache.position_snapshot(position_id)
all_snapshots = self.cache.position_snapshots()
```

## Common Patterns

### Check Position Before Entry

```python
def on_bar(self, bar: Bar) -> None:
    # Check current position state
    if self.portfolio.is_flat(self.instrument_id):
        # No position - consider entry
        self.evaluate_entry_signal(bar)
    else:
        # Has position - manage or exit
        self.evaluate_exit_signal(bar)
```

### Track Position State

```python
class MyStrategy(Strategy):
    def __init__(self, config: MyConfig) -> None:
        super().__init__(config)
        self.position: Position | None = None

    def on_position_opened(self, event: PositionOpened) -> None:
        if event.instrument_id == self.instrument_id:
            self.position = self.cache.position(event.position_id)
            self.log.info(f"Tracking position: {self.position.id}")

    def on_position_closed(self, event: PositionClosed) -> None:
        if event.instrument_id == self.instrument_id:
            self.log.info(f"Position closed with PnL: {event.realized_pnl}")
            self.position = None
```

### Position Sizing Based on Risk

```python
def calculate_position_size(self, entry_price: float, stop_price: float) -> Quantity:
    """Calculate position size based on risk."""
    # Get account balance
    account = self.portfolio.account(self.venue)
    balance = float(account.balance_total())
    
    # Risk parameters
    risk_percent = 0.02  # 2% risk per trade
    risk_amount = balance * risk_percent
    
    # Calculate stop distance
    stop_distance = abs(entry_price - stop_price)
    
    # Calculate quantity
    if stop_distance > 0:
        quantity = risk_amount / stop_distance
    else:
        quantity = 0
    
    # Round to instrument precision
    instrument = self.cache.instrument(self.instrument_id)
    return Quantity(quantity, instrument.size_precision)
```

### Close All Positions

```python
def close_all_positions(self) -> None:
    """Close all open positions for this strategy."""
    positions = self.cache.positions_open(strategy_id=self.id)
    
    for position in positions:
        self.close_position(position)

def close_position(self, position: Position) -> None:
    """Close a specific position."""
    if position.is_closed:
        return
    
    # Create closing order
    order_side = OrderSide.SELL if position.side == PositionSide.LONG else OrderSide.BUY
    
    order = self.order_factory.market(
        instrument_id=position.instrument_id,
        order_side=order_side,
        quantity=position.quantity,
        reduce_only=True,
    )
    self.submit_order(order)
```

### Monitor Position Performance

```python
def on_bar(self, bar: Bar) -> None:
    positions = self.cache.positions_open(strategy_id=self.id)
    
    for position in positions:
        current_price = Price.from_str(str(bar.close))
        unrealized = position.unrealized_pnl(current_price)
        
        self.log.info(
            f"Position {position.id}: "
            f"side={position.side} "
            f"qty={position.quantity} "
            f"entry={position.avg_px_open} "
            f"unrealized={unrealized}"
        )
```

### Position-Based Stop Loss

```python
def on_position_opened(self, event: PositionOpened) -> None:
    if event.instrument_id != self.instrument_id:
        return
    
    # Calculate stop price
    entry = float(event.avg_px_open)
    atr_value = self.atr.value
    
    if event.entry == OrderSide.BUY:
        stop_price = entry - (atr_value * 2)  # 2x ATR below entry
    else:
        stop_price = entry + (atr_value * 2)  # 2x ATR above entry
    
    # Submit stop order
    stop_side = OrderSide.SELL if event.entry == OrderSide.BUY else OrderSide.BUY
    
    stop_order = self.order_factory.stop_market(
        instrument_id=self.instrument_id,
        order_side=stop_side,
        quantity=event.quantity,
        trigger_price=Price.from_str(f"{stop_price:.2f}"),
        reduce_only=True,
    )
    self.submit_order(stop_order)
```

## Position in Strategy Lifecycle

```python
class MyStrategy(Strategy):
    def on_start(self) -> None:
        # Check for existing positions (from previous run)
        existing = self.cache.positions_open(strategy_id=self.id)
        if existing:
            self.log.info(f"Found {len(existing)} existing positions")
            for pos in existing:
                self.log.info(f"  {pos.instrument_id}: {pos.side} {pos.quantity}")

    def on_stop(self) -> None:
        # Optionally close all positions on stop
        if self.config.close_positions_on_stop:
            self.close_all_positions()
```

## Best Practices

1. **Always check position state**: Before entering, verify current position.

2. **Use reduce_only for exits**: Mark closing orders as `reduce_only=True`.

3. **Handle partial fills**: Positions reflect actual filled quantities.

4. **Monitor unrealized PnL**: Track position performance in real-time.

5. **Consider commissions**: Include commissions in PnL calculations.

6. **Use appropriate OMS type**: Match venue behavior (NETTING vs HEDGING).

7. **Handle position events**: React to opens, changes, and closes appropriately.

## Related Sections

- [orders.md](orders.md) - Order management creates positions
- [portfolio.md](portfolio.md) - Aggregated position information
- [cache.md](cache.md) - Position queries
- [execution.md](execution.md) - OMS types and execution flow
- [strategy-development.md](strategy-development.md) - Position handlers

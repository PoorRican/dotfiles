# Strategy Development Guide

## Strategy Base Class

**Location:** `nautilus_trader.trading.strategy`

The `Strategy` class is the foundation for all trading strategies in NautilusTrader.

```python
from nautilus_trader.trading import Strategy
from nautilus_trader.config import StrategyConfig

class MyStrategy(Strategy):
    """
    Custom trading strategy.
    
    Parameters
    ----------
    config : MyStrategyConfig
        The strategy configuration.
    """
    
    def __init__(self, config: StrategyConfig):
        super().__init__(config)
        # Initialize strategy-specific attributes
```

## Strategy Lifecycle

### Core Lifecycle Methods

```python
class MyStrategy(Strategy):
    
    def on_start(self):
        """
        Actions to be performed when the strategy starts.
        Called when transitioning from INITIALIZED to RUNNING.
        
        Use this method to:
        - Subscribe to market data
        - Initialize indicators
        - Set up timers
        - Load state if needed
        """
        pass
    
    def on_stop(self):
        """
        Actions to be performed when the strategy stops.
        Called when transitioning from RUNNING to STOPPED.
        
        Use this method to:
        - Cancel open orders
        - Close positions
        - Clean up resources
        """
        pass
    
    def on_reset(self):
        """
        Actions to be performed when strategy resets.
        Called when resetting strategy state.
        
        Use this method to:
        - Reset indicators
        - Clear internal state
        - Reset counters
        """
        pass
    
    def on_save(self) -> dict:
        """
        Save strategy state for persistence.
        
        Returns
        -------
        dict
            State dictionary to be saved
        """
        return {
            "custom_state": self.custom_value,
        }
    
    def on_load(self, state: dict):
        """
        Load strategy state from persistence.
        
        Parameters
        ----------
        state : dict
            Previously saved state dictionary
        """
        self.custom_value = state.get("custom_state")
    
    def on_dispose(self):
        """
        Final cleanup when strategy is disposed.
        Called once before strategy is destroyed.
        """
        pass
```

## Data Event Handlers

### Market Data Events

```python
from nautilus_trader.model.data import QuoteTick, TradeTick, Bar
from nautilus_trader.model.data import OrderBookDelta, OrderBookDepth10

class DataHandlerStrategy(Strategy):
    
    def on_quote_tick(self, tick: QuoteTick):
        """
        Handle quote tick (bid/ask) updates.
        
        Parameters
        ----------
        tick : QuoteTick
            The quote tick containing bid/ask prices
        """
        self.log.info(f"Quote: {tick.bid} / {tick.ask}")
    
    def on_trade_tick(self, tick: TradeTick):
        """
        Handle trade tick (executed trades) updates.
        
        Parameters
        ----------
        tick : TradeTick
            The trade tick containing price, size, aggressor side
        """
        self.log.info(f"Trade: {tick.price} @ {tick.size}")
    
    def on_bar(self, bar: Bar):
        """
        Handle bar (OHLCV) updates.
        
        Parameters
        ----------
        bar : Bar
            The completed bar with open, high, low, close, volume
        """
        self.log.info(f"Bar close: {bar.close}")
    
    def on_order_book_deltas(self, deltas: OrderBookDelta):
        """
        Handle order book delta (incremental) updates.
        
        Parameters
        ----------
        deltas : OrderBookDeltas
            The order book changes
        """
        pass
    
    def on_order_book_depth(self, depth: OrderBookDepth10):
        """
        Handle order book depth (top 10 levels) snapshot.
        
        Parameters
        ----------
        depth : OrderBookDepth10
            The order book depth snapshot
        """
        pass
```

## Data Subscriptions

### Subscribe to Market Data

```python
from nautilus_trader.model.identifiers import InstrumentId
from nautilus_trader.model.data import BarType

class SubscriptionStrategy(Strategy):
    
    def on_start(self):
        # Quote ticks (bid/ask updates)
        instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
        self.subscribe_quote_ticks(instrument_id)
        
        # Trade ticks (executed trades)
        self.subscribe_trade_ticks(instrument_id)
        
        # Bars (OHLCV)
        bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
        self.subscribe_bars(bar_type)
        
        # Order book deltas (incremental updates)
        self.subscribe_order_book_deltas(
            instrument_id=instrument_id,
            book_type=BookType.L2_MBP,  # Market by price
            depth=10,  # Top 10 levels
        )
        
        # Order book snapshots
        self.subscribe_order_book_snapshots(
            instrument_id=instrument_id,
            book_type=BookType.L2_MBP,
            depth=10,
        )
```

### Historical Data Requests

```python
def on_start(self):
    # Request historical bars
    self.request_bars(
        bar_type=self.bar_type,
        start=pd.Timestamp("2024-01-01", tz="UTC"),
        end=pd.Timestamp("2024-12-31", tz="UTC"),
    )

def on_historical_data(self, data):
    """Handle historical data response."""
    self.log.info(f"Received {len(data)} historical bars")
```

## Order Management

### Using OrderFactory

The strategy provides an `order_factory` for convenient order creation:

```python
from nautilus_trader.model.enums import OrderSide, TimeInForce
from nautilus_trader.model.objects import Quantity, Price

class OrderStrategy(Strategy):
    
    def create_market_order(self, instrument_id):
        """Create a market order."""
        order = self.order_factory.market(
            instrument_id=instrument_id,
            order_side=OrderSide.BUY,
            quantity=Quantity.from_str("1.0"),
        )
        return order
    
    def create_limit_order(self, instrument_id, price):
        """Create a limit order."""
        order = self.order_factory.limit(
            instrument_id=instrument_id,
            order_side=OrderSide.BUY,
            quantity=Quantity.from_str("1.0"),
            price=Price.from_str(str(price)),
            time_in_force=TimeInForce.GTC,
        )
        return order
    
    def create_stop_market_order(self, instrument_id, trigger_price):
        """Create a stop-market order."""
        order = self.order_factory.stop_market(
            instrument_id=instrument_id,
            order_side=OrderSide.SELL,
            quantity=Quantity.from_str("1.0"),
            trigger_price=Price.from_str(str(trigger_price)),
            time_in_force=TimeInForce.GTC,
        )
        return order
```

### Submitting and Managing Orders

```python
def on_bar(self, bar: Bar):
    # Create order
    order = self.order_factory.market(
        instrument_id=bar.bar_type.instrument_id,
        order_side=OrderSide.BUY,
        quantity=Quantity.from_str("1.0"),
    )
    
    # Submit order
    self.submit_order(order)
    
    # Cancel order (if not filled)
    self.cancel_order(order)
    
    # Modify order
    self.modify_order(
        order=order,
        quantity=Quantity.from_str("2.0"),
        price=Price.from_str("50000.0"),
    )
    
    # Close position
    position = self.portfolio.position(order.position_id)
    if position:
        self.close_position(position)
    
    # Close all positions for instrument
    self.close_all_positions(bar.bar_type.instrument_id)
```

### Order Event Handlers

```python
from nautilus_trader.model.events import OrderFilled, OrderRejected

def on_order_filled(self, event: OrderFilled):
    """Handle order filled event."""
    self.log.info(f"Order filled: {event.client_order_id}")

def on_order_rejected(self, event: OrderRejected):
    """Handle order rejected event."""
    self.log.error(f"Order rejected: {event.reason}")

def on_order_accepted(self, event):
    """Handle order accepted event."""
    pass

def on_order_cancelled(self, event):
    """Handle order cancelled event."""
    pass

def on_order_expired(self, event):
    """Handle order expired event."""
    pass

def on_order_triggered(self, event):
    """Handle order triggered event (for stop/trigger orders)."""
    pass
```

## Portfolio Access

### Account and Balance Information

```python
def check_account_state(self):
    # Get account for venue
    venue = Venue("BINANCE")
    account = self.portfolio.account(venue)
    
    # Check balances
    balances = self.portfolio.balances_locked(venue)
    for currency, money in balances.items():
        self.log.info(f"{currency}: {money}")
    
    # Check margins
    margins_init = self.portfolio.margins_init(venue)
    margins_maint = self.portfolio.margins_maint(venue)
```

### Position Information

```python
def check_positions(self, instrument_id):
    # Get specific position
    position = self.portfolio.position(position_id)
    
    # Get all open positions
    open_positions = self.portfolio.positions_open()
    
    # Get positions for instrument
    instrument_positions = self.portfolio.positions_open(
        instrument_id=instrument_id
    )
    
    # Check PnL
    unrealized_pnl = self.portfolio.unrealized_pnl(instrument_id)
    realized_pnl = self.portfolio.realized_pnl(instrument_id)
    
    # Check exposure
    net_exposure = self.portfolio.net_exposure(instrument_id)
```

## Working with Indicators

### Register Indicators for Automatic Updates

```python
from nautilus_trader.indicators import ExponentialMovingAverage

class EMAStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        # Create indicator
        self.ema = ExponentialMovingAverage(period=20)
        
    def on_start(self):
        # Register indicator for automatic bar updates
        self.register_indicator_for_bars(self.bar_type, self.ema)
        
        # Subscribe to bars
        self.subscribe_bars(self.bar_type)
    
    def on_bar(self, bar: Bar):
        # Indicator is automatically updated before this method is called
        if self.ema.initialized:
            current_ema = self.ema.value
            self.log.info(f"EMA: {current_ema}")
```

### Manual Indicator Updates

```python
def on_bar(self, bar: Bar):
    # Manually update indicator
    self.ema.handle_bar(bar)
    
    # Check if indicator has enough data
    if self.ema.initialized:
        value = self.ema.value
```

### Multiple Indicators

```python
from nautilus_trader.indicators import (
    ExponentialMovingAverage,
    RelativeStrengthIndex,
    BollingerBands,
)

class MultiIndicatorStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        self.ema_fast = ExponentialMovingAverage(period=12)
        self.ema_slow = ExponentialMovingAverage(period=26)
        self.rsi = RelativeStrengthIndex(period=14)
        self.bb = BollingerBands(period=20, k=2.0)
    
    def on_start(self):
        # Register all indicators
        self.register_indicator_for_bars(self.bar_type, self.ema_fast)
        self.register_indicator_for_bars(self.bar_type, self.ema_slow)
        self.register_indicator_for_bars(self.bar_type, self.rsi)
        self.register_indicator_for_bars(self.bar_type, self.bb)
        
        self.subscribe_bars(self.bar_type)
    
    def on_bar(self, bar: Bar):
        # All indicators automatically updated
        if self.ema_fast.initialized and self.ema_slow.initialized:
            if self.ema_fast.value > self.ema_slow.value:
                # Bullish signal
                pass
```

## Timing and Scheduling

### Using Timers

```python
from datetime import timedelta

class TimerStrategy(Strategy):
    
    def on_start(self):
        # Create recurring timer
        self.clock.set_timer(
            name="check_positions",
            interval=timedelta(seconds=60),
            callback=self.check_positions_callback,
        )
        
        # Create one-time timer
        self.clock.set_time_alert(
            name="morning_check",
            alert_time=pd.Timestamp("2024-01-01 09:30:00", tz="UTC"),
            callback=self.morning_check_callback,
        )
    
    def check_positions_callback(self, event):
        """Called every 60 seconds."""
        self.log.info("Checking positions...")
    
    def morning_check_callback(self, event):
        """Called once at specific time."""
        self.log.info("Morning check executed")
    
    def on_stop(self):
        # Cancel timers
        self.clock.cancel_timer("check_positions")
```

## State Management

### Custom State Variables

```python
class StatefulStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        self.trade_count = 0
        self.last_signal = None
        self.position_history = []
    
    def on_save(self) -> dict:
        """Save strategy state."""
        return {
            "trade_count": self.trade_count,
            "last_signal": self.last_signal,
            "position_history": self.position_history,
        }
    
    def on_load(self, state: dict):
        """Load strategy state."""
        self.trade_count = state.get("trade_count", 0)
        self.last_signal = state.get("last_signal")
        self.position_history = state.get("position_history", [])
```

## Configuration

### Strategy Configuration

```python
from nautilus_trader.config import StrategyConfig

class MyStrategyConfig(StrategyConfig):
    """Configuration for MyStrategy."""
    
    instrument_id: str
    bar_type: str
    fast_period: int = 12
    slow_period: int = 26
    trade_size: float = 1.0

class MyStrategy(Strategy):
    
    def __init__(self, config: MyStrategyConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)
        self.fast_period = config.fast_period
        self.slow_period = config.slow_period
        self.trade_size = Quantity.from_str(str(config.trade_size))
```

## Logging

### Strategy Logging

```python
class LoggingStrategy(Strategy):
    
    def on_bar(self, bar: Bar):
        # Different log levels
        self.log.debug(f"Debug: {bar}")
        self.log.info(f"Processing bar: {bar.close}")
        self.log.warning(f"Warning: Unusual condition")
        self.log.error(f"Error occurred")
        
        # Structured logging
        self.log.info(
            f"Trade signal generated",
            extra={
                "instrument": bar.bar_type.instrument_id,
                "price": float(bar.close),
                "volume": float(bar.volume),
            }
        )
```

## Common Strategy Patterns

### 1. Trend Following

```python
class TrendFollowingStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        self.ema_fast = ExponentialMovingAverage(12)
        self.ema_slow = ExponentialMovingAverage(26)
    
    def on_bar(self, bar: Bar):
        if not self.ema_fast.initialized or not self.ema_slow.initialized:
            return
        
        # Check for crossover
        if self.ema_fast.value > self.ema_slow.value:
            # Bullish - buy signal
            if not self.portfolio.is_net_long(bar.bar_type.instrument_id):
                order = self.order_factory.market(
                    instrument_id=bar.bar_type.instrument_id,
                    order_side=OrderSide.BUY,
                    quantity=self.trade_size,
                )
                self.submit_order(order)
        
        elif self.ema_fast.value < self.ema_slow.value:
            # Bearish - sell signal
            if not self.portfolio.is_net_short(bar.bar_type.instrument_id):
                # Close long position
                self.close_all_positions(bar.bar_type.instrument_id)
```

### 2. Mean Reversion

```python
from nautilus_trader.indicators import BollingerBands

class MeanReversionStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        self.bb = BollingerBands(period=20, k=2.0)
    
    def on_bar(self, bar: Bar):
        if not self.bb.initialized:
            return
        
        price = float(bar.close)
        upper = float(self.bb.upper)
        lower = float(self.bb.lower)
        
        # Price below lower band - buy
        if price < lower:
            order = self.order_factory.market(
                instrument_id=bar.bar_type.instrument_id,
                order_side=OrderSide.BUY,
                quantity=self.trade_size,
            )
            self.submit_order(order)
        
        # Price above upper band - sell
        elif price > upper:
            self.close_all_positions(bar.bar_type.instrument_id)
```

### 3. Risk Managed Strategy

```python
class RiskManagedStrategy(Strategy):
    
    def __init__(self, config):
        super().__init__(config)
        self.max_position_size = Quantity.from_str("10.0")
        self.stop_loss_pct = 0.02  # 2%
    
    def on_bar(self, bar: Bar):
        # Check current exposure
        net_position = self.portfolio.net_position(bar.bar_type.instrument_id)
        
        if abs(net_position) >= self.max_position_size:
            self.log.warning("Position limit reached")
            return
        
        # Entry signal logic here
        if self.should_enter(bar):
            # Calculate position size
            position_size = min(
                self.calculate_position_size(bar),
                self.max_position_size - abs(net_position)
            )
            
            # Entry order
            entry_order = self.order_factory.market(
                instrument_id=bar.bar_type.instrument_id,
                order_side=OrderSide.BUY,
                quantity=position_size,
            )
            self.submit_order(entry_order)
            
            # Stop loss order
            stop_price = float(bar.close) * (1 - self.stop_loss_pct)
            stop_order = self.order_factory.stop_market(
                instrument_id=bar.bar_type.instrument_id,
                order_side=OrderSide.SELL,
                quantity=position_size,
                trigger_price=Price.from_str(str(stop_price)),
            )
            self.submit_order(stop_order)
```

## Next Steps

- **See complete examples:** Read `examples.md`
- **Learn backtesting:** Read `backtesting.md`
- **Deploy live:** Read `live-trading.md`
- **Best practices:** Read `best-practices.md`

## Additional Resources

- **Strategy Concepts:** https://nautilustrader.io/docs/latest/concepts/strategies/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/trading/
- **Example Strategies:** https://github.com/nautechsystems/nautilus_trader/tree/develop/examples

# Actors Guide

## Overview

The `Actor` class is the foundational base class for all user-defined components in NautilusTrader. It provides access to the system's core infrastructure: the clock, cache, portfolio, and message bus.

**Location:** `nautilus_trader.trading.actor`

## Actor vs Strategy

| Feature | Actor | Strategy |
|---------|-------|----------|
| Base class | `Component` | `Actor` |
| Order submission | No | Yes |
| Position management | No | Yes |
| OrderFactory | No | Yes |
| Data subscriptions | Yes | Yes |
| Cache access | Yes | Yes |
| Portfolio access | Yes | Yes |
| MessageBus access | Yes | Yes |
| Timers | Yes | Yes |

**Use Actor when:**
- Building data processors or signal generators
- Creating monitoring or logging components
- Implementing cross-strategy coordination
- Building components that don't trade directly

**Use Strategy when:**
- Implementing trading logic with order submission
- Managing positions and risk

## Basic Actor Structure

```python
from nautilus_trader.trading import Actor
from nautilus_trader.config import ActorConfig

class MyActorConfig(ActorConfig):
    """Configuration for MyActor."""
    instrument_id: str
    signal_threshold: float = 0.5

class MyActor(Actor):
    """
    Custom actor for signal generation.

    Parameters
    ----------
    config : MyActorConfig
        The actor configuration.
    """

    def __init__(self, config: MyActorConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.signal_threshold = config.signal_threshold
```

## Lifecycle Methods

```python
class MyActor(Actor):

    def on_start(self):
        """
        Called when actor transitions to RUNNING state.

        Use for:
        - Subscribing to data
        - Initializing indicators
        - Setting up timers
        - Loading saved state
        """
        self.subscribe_quote_ticks(self.instrument_id)
        self.subscribe_trade_ticks(self.instrument_id)

    def on_stop(self):
        """
        Called when actor transitions to STOPPED state.

        Use for:
        - Cleanup operations
        - Saving state
        - Unsubscribing from data
        """
        self.unsubscribe_quote_ticks(self.instrument_id)

    def on_reset(self):
        """
        Called when actor is reset.

        Use for:
        - Resetting internal state
        - Clearing indicators
        - Resetting counters
        """
        self.signal_count = 0

    def on_dispose(self):
        """
        Called once before actor is destroyed.

        Use for:
        - Final cleanup
        - Releasing resources
        """
        pass

    def on_save(self) -> dict:
        """
        Save actor state for persistence.

        Returns
        -------
        dict
            State dictionary to persist
        """
        return {
            "signal_count": self.signal_count,
            "last_signal": self.last_signal,
        }

    def on_load(self, state: dict):
        """
        Load actor state from persistence.

        Parameters
        ----------
        state : dict
            Previously saved state
        """
        self.signal_count = state.get("signal_count", 0)
        self.last_signal = state.get("last_signal")
```

## Data Subscriptions

### Subscribe to Market Data

```python
from nautilus_trader.model.identifiers import InstrumentId
from nautilus_trader.model.data import BarType
from nautilus_trader.model.enums import BookType

class DataActor(Actor):

    def on_start(self):
        instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")

        # Quote ticks (bid/ask updates)
        self.subscribe_quote_ticks(instrument_id)

        # Trade ticks (executed trades)
        self.subscribe_trade_ticks(instrument_id)

        # Bars (OHLCV)
        bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
        self.subscribe_bars(bar_type)

        # Order book deltas
        self.subscribe_order_book_deltas(
            instrument_id=instrument_id,
            book_type=BookType.L2_MBP,
            depth=10,
        )

        # Order book snapshots
        self.subscribe_order_book_snapshots(
            instrument_id=instrument_id,
            book_type=BookType.L2_MBP,
            depth=10,
        )

        # Instrument updates
        self.subscribe_instrument(instrument_id)
        self.subscribe_instrument_status(instrument_id)
```

### Data Event Handlers

```python
from nautilus_trader.model.data import QuoteTick, TradeTick, Bar
from nautilus_trader.model.data import OrderBookDelta, OrderBookDepth10

class DataActor(Actor):

    def on_quote_tick(self, tick: QuoteTick):
        """Handle quote tick updates."""
        self.log.info(f"Quote: {tick.bid_price} / {tick.ask_price}")

    def on_trade_tick(self, tick: TradeTick):
        """Handle trade tick updates."""
        self.log.info(f"Trade: {tick.price} @ {tick.size}")

    def on_bar(self, bar: Bar):
        """Handle bar updates."""
        self.log.info(f"Bar: O={bar.open} H={bar.high} L={bar.low} C={bar.close}")

    def on_order_book_deltas(self, deltas: OrderBookDelta):
        """Handle order book delta updates."""
        pass

    def on_order_book_depth(self, depth: OrderBookDepth10):
        """Handle order book depth snapshots."""
        best_bid = depth.bids[0] if depth.bids else None
        best_ask = depth.asks[0] if depth.asks else None
```

### Historical Data Requests

```python
import pandas as pd

def on_start(self):
    # Request historical bars
    self.request_bars(
        bar_type=self.bar_type,
        start=pd.Timestamp("2024-01-01", tz="UTC"),
        end=pd.Timestamp("2024-12-31", tz="UTC"),
    )

    # Request historical quote ticks
    self.request_quote_ticks(
        instrument_id=self.instrument_id,
        start=pd.Timestamp("2024-01-01", tz="UTC"),
        end=pd.Timestamp("2024-01-31", tz="UTC"),
    )

def on_historical_data(self, data):
    """Handle historical data response."""
    self.log.info(f"Received {len(data)} historical records")
```

## Cache Access

Actors have full access to the system cache:

```python
def check_market_state(self):
    # Get instrument
    instrument = self.cache.instrument(self.instrument_id)

    # Get latest quote
    quote = self.cache.quote_tick(self.instrument_id)
    if quote:
        spread = float(quote.ask_price - quote.bid_price)

    # Get latest trade
    trade = self.cache.trade_tick(self.instrument_id)

    # Get latest bar
    bar = self.cache.bar(self.bar_type)

    # Get order book
    book = self.cache.order_book(self.instrument_id)
    if book:
        best_bid = book.best_bid_price()
        best_ask = book.best_ask_price()

    # Get all instruments for venue
    instruments = self.cache.instruments(venue=Venue("BINANCE"))
```

## Portfolio Access

Actors can read portfolio state (but cannot modify it):

```python
def check_portfolio(self):
    venue = Venue("BINANCE")

    # Check account
    account = self.portfolio.account(venue)

    # Check balances
    balances = self.portfolio.balances_locked(venue)

    # Check positions
    positions = self.portfolio.positions_open(venue)

    # Check specific instrument position
    net_position = self.portfolio.net_position(self.instrument_id)

    # Check PnL
    unrealized = self.portfolio.unrealized_pnl(self.instrument_id)
    realized = self.portfolio.realized_pnl(self.instrument_id)
```

## MessageBus Communication

### Publishing Messages

```python
from nautilus_trader.core.data import Data

class SignalActor(Actor):

    def publish_signal(self, signal_value: float):
        """Publish a trading signal to the message bus."""
        # Create custom signal data
        signal = CustomSignal(
            value=signal_value,
            instrument_id=self.instrument_id,
            ts_event=self.clock.timestamp_ns(),
            ts_init=self.clock.timestamp_ns(),
        )

        # Publish to topic
        self.publish_data(
            data_type=DataType(CustomSignal),
            data=signal,
        )

        # Or publish directly to message bus
        self.msgbus.publish(
            topic="signals.trading",
            msg=signal,
        )
```

### Subscribing to Messages

```python
class ReceiverActor(Actor):

    def on_start(self):
        # Subscribe to custom topic
        self.msgbus.subscribe(
            topic="signals.trading",
            handler=self.on_trading_signal,
        )

        # Subscribe with wildcard
        self.msgbus.subscribe(
            topic="signals.*",
            handler=self.on_any_signal,
        )

    def on_trading_signal(self, signal):
        """Handle trading signal from message bus."""
        self.log.info(f"Received signal: {signal.value}")

    def on_any_signal(self, signal):
        """Handle any signal matching wildcard."""
        pass

    def on_stop(self):
        # Unsubscribe when stopping
        self.msgbus.unsubscribe(
            topic="signals.trading",
            handler=self.on_trading_signal,
        )
```

### Common Topic Patterns

```python
# System topics
"data.quotes.*"           # All quote tick events
"data.trades.*"           # All trade tick events
"data.bars.*"             # All bar events
"events.order.*"          # All order events
"events.position.*"       # All position events
"events.account.*"        # All account events

# Custom topics
"signals.entry"           # Entry signals
"signals.exit"            # Exit signals
"alerts.risk"             # Risk alerts
"metrics.performance"     # Performance metrics
```

## Timers and Scheduling

### Recurring Timers

```python
from datetime import timedelta

class TimerActor(Actor):

    def on_start(self):
        # Create recurring timer
        self.clock.set_timer(
            name="health_check",
            interval=timedelta(seconds=60),
            callback=self.on_health_check,
        )

        # Create faster timer
        self.clock.set_timer(
            name="signal_check",
            interval=timedelta(seconds=5),
            callback=self.on_signal_check,
        )

    def on_health_check(self, event):
        """Called every 60 seconds."""
        self.log.info("Health check OK")

    def on_signal_check(self, event):
        """Called every 5 seconds."""
        self.check_signals()

    def on_stop(self):
        # Cancel timers
        self.clock.cancel_timer("health_check")
        self.clock.cancel_timer("signal_check")
```

### One-Time Alerts

```python
import pandas as pd

def on_start(self):
    # Set alert for specific time
    self.clock.set_time_alert(
        name="market_open",
        alert_time=pd.Timestamp("2024-01-02 09:30:00", tz="America/New_York"),
        callback=self.on_market_open,
    )

def on_market_open(self, event):
    """Called once at market open."""
    self.log.info("Market is now open")
```

## Custom Data Types

### Define Custom Data

```python
from nautilus_trader.core.data import Data
from nautilus_trader.model.identifiers import InstrumentId

class TradingSignal(Data):
    """Custom trading signal data type."""

    def __init__(
        self,
        instrument_id: InstrumentId,
        direction: int,  # 1 = long, -1 = short, 0 = neutral
        strength: float,  # 0.0 to 1.0
        ts_event: int,
        ts_init: int,
    ):
        super().__init__()
        self.instrument_id = instrument_id
        self.direction = direction
        self.strength = strength
        self.ts_event = ts_event
        self.ts_init = ts_init
```

### Publish and Subscribe to Custom Data

```python
from nautilus_trader.core.data import DataType

class SignalGenerator(Actor):

    def on_bar(self, bar: Bar):
        # Generate signal
        signal = TradingSignal(
            instrument_id=bar.bar_type.instrument_id,
            direction=1 if self.is_bullish(bar) else -1,
            strength=0.8,
            ts_event=self.clock.timestamp_ns(),
            ts_init=self.clock.timestamp_ns(),
        )

        # Publish to subscribers
        self.publish_data(
            data_type=DataType(TradingSignal),
            data=signal,
        )

class SignalConsumer(Actor):

    def on_start(self):
        # Subscribe to custom data type
        self.subscribe_data(DataType(TradingSignal))

    def on_data(self, data: TradingSignal):
        """Handle custom data."""
        if isinstance(data, TradingSignal):
            self.log.info(f"Signal: {data.direction} @ {data.strength}")
```

## Common Actor Patterns

### 1. Signal Generator

```python
class MomentumSignalActor(Actor):
    """Generates momentum signals for strategies to consume."""

    def __init__(self, config):
        super().__init__(config)
        self.lookback = config.lookback
        self.prices = []

    def on_bar(self, bar: Bar):
        self.prices.append(float(bar.close))
        if len(self.prices) > self.lookback:
            self.prices.pop(0)

        if len(self.prices) >= self.lookback:
            momentum = (self.prices[-1] - self.prices[0]) / self.prices[0]

            signal = TradingSignal(
                instrument_id=bar.bar_type.instrument_id,
                direction=1 if momentum > 0 else -1,
                strength=min(abs(momentum) * 10, 1.0),
                ts_event=bar.ts_event,
                ts_init=self.clock.timestamp_ns(),
            )

            self.publish_data(DataType(TradingSignal), signal)
```

### 2. Risk Monitor

```python
class RiskMonitorActor(Actor):
    """Monitors portfolio risk and publishes alerts."""

    def __init__(self, config):
        super().__init__(config)
        self.max_drawdown = config.max_drawdown
        self.peak_equity = 0.0

    def on_start(self):
        self.clock.set_timer(
            name="risk_check",
            interval=timedelta(seconds=10),
            callback=self.check_risk,
        )

    def check_risk(self, event):
        # Calculate current equity
        equity = self.calculate_equity()

        # Update peak
        if equity > self.peak_equity:
            self.peak_equity = equity

        # Check drawdown
        if self.peak_equity > 0:
            drawdown = (self.peak_equity - equity) / self.peak_equity

            if drawdown > self.max_drawdown:
                self.log.error(f"Max drawdown exceeded: {drawdown:.2%}")
                self.msgbus.publish(
                    topic="alerts.risk",
                    msg={"type": "max_drawdown", "value": drawdown},
                )
```

### 3. Data Aggregator

```python
class VWAPActor(Actor):
    """Calculates VWAP and publishes updates."""

    def __init__(self, config):
        super().__init__(config)
        self.cumulative_volume = 0.0
        self.cumulative_pv = 0.0  # price * volume

    def on_trade_tick(self, tick: TradeTick):
        price = float(tick.price)
        volume = float(tick.size)

        self.cumulative_volume += volume
        self.cumulative_pv += price * volume

        if self.cumulative_volume > 0:
            vwap = self.cumulative_pv / self.cumulative_volume

            self.msgbus.publish(
                topic="indicators.vwap",
                msg={"instrument_id": tick.instrument_id, "vwap": vwap},
            )

    def on_reset(self):
        self.cumulative_volume = 0.0
        self.cumulative_pv = 0.0
```

## Registering Actors

### With BacktestEngine

```python
from nautilus_trader.backtest.engine import BacktestEngine

engine = BacktestEngine()
# ... configure engine ...

# Add actor
actor = MyActor(MyActorConfig(instrument_id="BTCUSDT.BINANCE"))
engine.add_actor(actor)

# Add strategy that consumes actor signals
strategy = MyStrategy(config)
engine.add_strategy(strategy)

engine.run()
```

### With TradingNode

```python
from nautilus_trader.live.node import TradingNode
from nautilus_trader.config import TradingNodeConfig

config = TradingNodeConfig(
    trader_id="TRADER-001",
    actors=[
        MyActorConfig(instrument_id="BTCUSDT.BINANCE"),
        RiskMonitorConfig(max_drawdown=0.1),
    ],
    strategies=[
        MyStrategyConfig(...),
    ],
    # ... other config
)

node = TradingNode(config=config)
node.run()
```

## Next Steps

- **Build trading strategies:** Read `strategy-development.md`
- **Understand data flow:** Read `architecture.md`
- **Use indicators:** Read `indicators.md`
- **Query cached data:** Read `cache.md`

## Additional Resources

- **Actor Concepts:** https://nautilustrader.io/docs/latest/concepts/actors/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/trading/
- **Example Actors:** https://github.com/nautechsystems/nautilus_trader/tree/develop/examples

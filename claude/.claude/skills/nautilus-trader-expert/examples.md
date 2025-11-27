# Examples Guide

## Complete Strategy Examples

### 1. Simple Moving Average Crossover

```python
from nautilus_trader.trading import Strategy
from nautilus_trader.config import StrategyConfig
from nautilus_trader.indicators.average import ExponentialMovingAverage
from nautilus_trader.model.data import Bar, BarType
from nautilus_trader.model.enums import OrderSide
from nautilus_trader.model.identifiers import InstrumentId
from nautilus_trader.model.objects import Quantity


class EMACrossConfig(StrategyConfig):
    """Configuration for EMA crossover strategy."""
    instrument_id: str
    bar_type: str
    fast_period: int = 10
    slow_period: int = 20
    trade_size: float = 1.0


class EMACrossStrategy(Strategy):
    """
    Simple EMA crossover strategy.

    Buy when fast EMA crosses above slow EMA.
    Sell when fast EMA crosses below slow EMA.
    """

    def __init__(self, config: EMACrossConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)
        self.trade_size = Quantity.from_str(str(config.trade_size))

        # Create indicators
        self.ema_fast = ExponentialMovingAverage(config.fast_period)
        self.ema_slow = ExponentialMovingAverage(config.slow_period)

        # Track previous values for crossover detection
        self.prev_fast = None
        self.prev_slow = None

    def on_start(self):
        # Register indicators for automatic updates
        self.register_indicator_for_bars(self.bar_type, self.ema_fast)
        self.register_indicator_for_bars(self.bar_type, self.ema_slow)

        # Subscribe to bars
        self.subscribe_bars(self.bar_type)

        self.log.info("Strategy started")

    def on_bar(self, bar: Bar):
        # Wait for indicators to initialize
        if not self.ema_fast.initialized or not self.ema_slow.initialized:
            return

        fast = self.ema_fast.value
        slow = self.ema_slow.value

        # Detect crossovers
        if self.prev_fast is not None and self.prev_slow is not None:
            # Bullish crossover
            if self.prev_fast <= self.prev_slow and fast > slow:
                self.log.info("Bullish crossover detected")
                if not self.portfolio.is_net_long(self.instrument_id):
                    self.close_all_positions(self.instrument_id)
                    self.buy()

            # Bearish crossover
            elif self.prev_fast >= self.prev_slow and fast < slow:
                self.log.info("Bearish crossover detected")
                if self.portfolio.is_net_long(self.instrument_id):
                    self.close_all_positions(self.instrument_id)

        # Store for next comparison
        self.prev_fast = fast
        self.prev_slow = slow

    def buy(self):
        order = self.order_factory.market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.BUY,
            quantity=self.trade_size,
        )
        self.submit_order(order)

    def on_stop(self):
        self.close_all_positions(self.instrument_id)
        self.cancel_all_orders(self.instrument_id)
        self.log.info("Strategy stopped")
```

### 2. RSI Mean Reversion with Stop Loss

```python
from nautilus_trader.indicators.rsi import RelativeStrengthIndex
from nautilus_trader.indicators.atr import AverageTrueRange
from nautilus_trader.model.objects import Price


class RSIMeanReversionConfig(StrategyConfig):
    instrument_id: str
    bar_type: str
    rsi_period: int = 14
    atr_period: int = 14
    oversold: float = 30.0
    overbought: float = 70.0
    atr_multiplier: float = 2.0
    trade_size: float = 1.0


class RSIMeanReversionStrategy(Strategy):
    """
    RSI mean reversion with ATR-based stop loss.

    Buy when RSI < oversold level.
    Exit when RSI > overbought level or stop loss hit.
    """

    def __init__(self, config: RSIMeanReversionConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)
        self.trade_size = Quantity.from_str(str(config.trade_size))
        self.oversold = config.oversold
        self.overbought = config.overbought
        self.atr_multiplier = config.atr_multiplier

        self.rsi = RelativeStrengthIndex(config.rsi_period)
        self.atr = AverageTrueRange(config.atr_period)

        self.entry_price = None
        self.stop_order_id = None

    def on_start(self):
        self.register_indicator_for_bars(self.bar_type, self.rsi)
        self.register_indicator_for_bars(self.bar_type, self.atr)
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar: Bar):
        if not self.rsi.initialized or not self.atr.initialized:
            return

        rsi = self.rsi.value
        is_long = self.portfolio.is_net_long(self.instrument_id)

        # Entry: RSI oversold and not in position
        if rsi < self.oversold and not is_long:
            self.enter_long(bar)

        # Exit: RSI overbought
        elif rsi > self.overbought and is_long:
            self.exit_position()

    def enter_long(self, bar: Bar):
        # Market entry
        entry = self.order_factory.market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.BUY,
            quantity=self.trade_size,
        )
        self.submit_order(entry)

        # Stop loss
        stop_price = float(bar.close) - (self.atr.value * self.atr_multiplier)
        stop = self.order_factory.stop_market(
            instrument_id=self.instrument_id,
            order_side=OrderSide.SELL,
            quantity=self.trade_size,
            trigger_price=Price.from_str(f"{stop_price:.2f}"),
        )
        self.submit_order(stop)
        self.stop_order_id = stop.client_order_id
        self.entry_price = float(bar.close)

    def exit_position(self):
        # Cancel stop order
        if self.stop_order_id:
            stop = self.cache.order(self.stop_order_id)
            if stop and stop.is_open:
                self.cancel_order(stop)

        # Close position
        self.close_all_positions(self.instrument_id)
        self.stop_order_id = None
        self.entry_price = None

    def on_order_filled(self, event):
        if event.client_order_id == self.stop_order_id:
            self.log.info("Stop loss triggered")
            self.stop_order_id = None
            self.entry_price = None
```

### 3. Bollinger Band Breakout

```python
from nautilus_trader.indicators.bollinger_bands import BollingerBands


class BollingerBreakoutConfig(StrategyConfig):
    instrument_id: str
    bar_type: str
    bb_period: int = 20
    bb_std: float = 2.0
    trade_size: float = 1.0


class BollingerBreakoutStrategy(Strategy):
    """
    Bollinger Band breakout strategy.

    Buy on breakout above upper band.
    Sell when price returns to middle band.
    """

    def __init__(self, config: BollingerBreakoutConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)
        self.trade_size = Quantity.from_str(str(config.trade_size))

        self.bb = BollingerBands(config.bb_period, config.bb_std)
        self.in_breakout = False

    def on_start(self):
        self.register_indicator_for_bars(self.bar_type, self.bb)
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar: Bar):
        if not self.bb.initialized:
            return

        close = float(bar.close)
        upper = self.bb.upper
        middle = self.bb.middle
        lower = self.bb.lower

        is_long = self.portfolio.is_net_long(self.instrument_id)

        # Breakout above upper band
        if close > upper and not is_long:
            self.log.info(f"Breakout: {close:.2f} > {upper:.2f}")
            order = self.order_factory.market(
                instrument_id=self.instrument_id,
                order_side=OrderSide.BUY,
                quantity=self.trade_size,
            )
            self.submit_order(order)
            self.in_breakout = True

        # Return to middle band - exit
        elif self.in_breakout and is_long and close < middle:
            self.log.info(f"Exit: {close:.2f} < {middle:.2f}")
            self.close_all_positions(self.instrument_id)
            self.in_breakout = False

        # Stop on close below lower band
        elif self.in_breakout and is_long and close < lower:
            self.log.info(f"Stop: {close:.2f} < {lower:.2f}")
            self.close_all_positions(self.instrument_id)
            self.in_breakout = False
```

## Backtest Example

### Complete Backtest Setup

```python
from nautilus_trader.backtest.node import BacktestNode
from nautilus_trader.config import (
    BacktestRunConfig,
    BacktestEngineConfig,
    BacktestVenueConfig,
    BacktestDataConfig,
)
from nautilus_trader.model.enums import OmsType, AccountType
from nautilus_trader.model.data import Bar
from nautilus_trader.persistence.catalog import ParquetDataCatalog


def run_backtest():
    # Load data catalog
    catalog = ParquetDataCatalog("./data/catalog")

    # Configure backtest
    config = BacktestRunConfig(
        engine=BacktestEngineConfig(
            trader_id="BACKTESTER-001",
            logging_config=LoggingConfig(log_level="INFO"),
        ),
        venues=[
            BacktestVenueConfig(
                name="BINANCE",
                oms_type=OmsType.NETTING,
                account_type=AccountType.CASH,
                starting_balances=["100000 USDT"],
                base_currency="USDT",
            )
        ],
        data=[
            BacktestDataConfig(
                catalog_path="./data/catalog",
                data_cls=Bar,
                instrument_id="BTCUSDT.BINANCE",
                bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
            )
        ],
        strategies=[
            EMACrossConfig(
                instrument_id="BTCUSDT.BINANCE",
                bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
                fast_period=10,
                slow_period=20,
                trade_size=0.1,
            )
        ],
    )

    # Run backtest
    node = BacktestNode(configs=[config])
    results = node.run()

    # Print results
    for result in results:
        print(f"Total PnL: {result}")


if __name__ == "__main__":
    run_backtest()
```

### Parameter Optimization

```python
def optimize_parameters():
    """Run multiple backtests with different parameters."""

    fast_periods = [5, 10, 15]
    slow_periods = [20, 30, 50]

    results = []

    for fast in fast_periods:
        for slow in slow_periods:
            if fast >= slow:
                continue

            config = BacktestRunConfig(
                engine=BacktestEngineConfig(
                    trader_id=f"OPT-{fast}-{slow}",
                ),
                # ... other config
                strategies=[
                    EMACrossConfig(
                        instrument_id="BTCUSDT.BINANCE",
                        bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
                        fast_period=fast,
                        slow_period=slow,
                    )
                ],
            )

            node = BacktestNode(configs=[config])
            result = node.run()[0]

            results.append({
                "fast": fast,
                "slow": slow,
                "pnl": result,
            })

    # Find best parameters
    best = max(results, key=lambda x: x["pnl"])
    print(f"Best: fast={best['fast']}, slow={best['slow']}, pnl={best['pnl']}")
```

## Live Trading Example

```python
import os
from nautilus_trader.live.node import TradingNode
from nautilus_trader.config import TradingNodeConfig
from nautilus_trader.adapters.binance.config import (
    BinanceDataClientConfig,
    BinanceExecClientConfig,
)


def run_live():
    config = TradingNodeConfig(
        trader_id="LIVE-TRADER-001",
        data_clients={
            "BINANCE": BinanceDataClientConfig(
                api_key=os.getenv("BINANCE_API_KEY"),
                api_secret=os.getenv("BINANCE_API_SECRET"),
                testnet=True,  # Use testnet first!
            ),
        },
        exec_clients={
            "BINANCE": BinanceExecClientConfig(
                api_key=os.getenv("BINANCE_API_KEY"),
                api_secret=os.getenv("BINANCE_API_SECRET"),
                testnet=True,
            ),
        },
        strategies=[
            EMACrossConfig(
                instrument_id="BTCUSDT.BINANCE",
                bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
                fast_period=10,
                slow_period=20,
                trade_size=0.001,  # Small size for testing
            )
        ],
    )

    node = TradingNode(config=config)

    try:
        node.build()
        node.start()
    except KeyboardInterrupt:
        node.stop()
    finally:
        node.dispose()


if __name__ == "__main__":
    run_live()
```

## Actor Example: Signal Generator

```python
from nautilus_trader.trading import Actor
from nautilus_trader.config import ActorConfig
from nautilus_trader.core.data import Data, DataType


class TradingSignal(Data):
    """Custom trading signal."""

    def __init__(
        self,
        instrument_id: InstrumentId,
        direction: int,  # 1=long, -1=short, 0=neutral
        strength: float,
        ts_event: int,
        ts_init: int,
    ):
        super().__init__()
        self.instrument_id = instrument_id
        self.direction = direction
        self.strength = strength
        self.ts_event = ts_event
        self.ts_init = ts_init


class SignalGeneratorConfig(ActorConfig):
    instrument_id: str
    bar_type: str
    lookback: int = 20


class SignalGenerator(Actor):
    """Generates trading signals for other strategies."""

    def __init__(self, config: SignalGeneratorConfig):
        super().__init__(config)
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)
        self.lookback = config.lookback
        self.closes = []

    def on_start(self):
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar: Bar):
        self.closes.append(float(bar.close))
        if len(self.closes) > self.lookback:
            self.closes.pop(0)

        if len(self.closes) >= self.lookback:
            # Calculate momentum signal
            momentum = (self.closes[-1] - self.closes[0]) / self.closes[0]
            direction = 1 if momentum > 0 else -1
            strength = min(abs(momentum) * 10, 1.0)

            signal = TradingSignal(
                instrument_id=self.instrument_id,
                direction=direction,
                strength=strength,
                ts_event=bar.ts_event,
                ts_init=self.clock.timestamp_ns(),
            )

            # Publish for other components
            self.publish_data(DataType(TradingSignal), signal)


class SignalFollowerStrategy(Strategy):
    """Strategy that follows signals from SignalGenerator."""

    def on_start(self):
        self.subscribe_data(DataType(TradingSignal))

    def on_data(self, data):
        if isinstance(data, TradingSignal):
            if data.direction == 1 and data.strength > 0.5:
                if not self.portfolio.is_net_long(data.instrument_id):
                    # Go long
                    pass
            elif data.direction == -1 and data.strength > 0.5:
                if self.portfolio.is_net_long(data.instrument_id):
                    # Exit long
                    pass
```

## MessageBus Communication Example

```python
class RiskMonitor(Actor):
    """Monitors portfolio risk and publishes alerts."""

    def on_start(self):
        from datetime import timedelta

        self.clock.set_timer(
            name="risk_check",
            interval=timedelta(seconds=30),
            callback=self.check_risk,
        )

    def check_risk(self, event):
        # Check drawdown
        # ... calculate drawdown ...

        if drawdown > 0.1:  # 10% drawdown
            self.msgbus.publish(
                topic="alerts.risk",
                msg={"type": "drawdown", "value": drawdown},
            )


class AlertHandler(Actor):
    """Handles risk alerts."""

    def on_start(self):
        self.msgbus.subscribe(
            topic="alerts.risk",
            handler=self.on_risk_alert,
        )

    def on_risk_alert(self, alert):
        self.log.error(f"Risk alert: {alert}")
        # Could trigger emergency shutdown, notifications, etc.
```

## Next Steps

- **Strategy development:** Read `strategy-development.md`
- **Backtesting:** Read `backtesting.md`
- **Live trading:** Read `live-trading.md`
- **Best practices:** Read `best-practices.md`

## Additional Resources

- **Official Examples:** https://github.com/nautechsystems/nautilus_trader/tree/develop/examples
- **Documentation:** https://nautilustrader.io/docs/latest/

# Indicators Guide

## Overview

NautilusTrader provides a comprehensive library of technical indicators implemented in Cython for maximum performance. Indicators can be updated automatically via registration or manually in event handlers.

**Location:** `nautilus_trader.indicators`

## Built-in Indicators

### Moving Averages

```python
from nautilus_trader.indicators.average import (
    ExponentialMovingAverage,  # EMA
    SimpleMovingAverage,       # SMA
    WeightedMovingAverage,     # WMA
    DoubleExponentialMovingAverage,  # DEMA
    HullMovingAverage,         # HMA
    AdaptiveMovingAverage,     # AMA / KAMA
    WilderMovingAverage,       # Wilder's smoothing
)

# Create EMA
ema = ExponentialMovingAverage(period=20)

# Create SMA
sma = SimpleMovingAverage(period=50)

# Create HMA
hma = HullMovingAverage(period=16)
```

### Momentum Indicators

```python
from nautilus_trader.indicators.rsi import RelativeStrengthIndex
from nautilus_trader.indicators.macd import MovingAverageConvergenceDivergence
from nautilus_trader.indicators.stochastics import Stochastics
from nautilus_trader.indicators.cci import CommodityChannelIndex
from nautilus_trader.indicators.roc import RateOfChange
from nautilus_trader.indicators.momentum import Momentum

# RSI
rsi = RelativeStrengthIndex(period=14)

# MACD
macd = MovingAverageConvergenceDivergence(
    fast_period=12,
    slow_period=26,
    signal_period=9,
)

# Stochastics
stoch = Stochastics(period_k=14, period_d=3)

# CCI
cci = CommodityChannelIndex(period=20)
```

### Volatility Indicators

```python
from nautilus_trader.indicators.bollinger_bands import BollingerBands
from nautilus_trader.indicators.atr import AverageTrueRange
from nautilus_trader.indicators.keltner_channel import KeltnerChannel
from nautilus_trader.indicators.donchian_channel import DonchianChannel
from nautilus_trader.indicators.volatility_ratio import VolatilityRatio

# Bollinger Bands
bb = BollingerBands(period=20, k=2.0)

# ATR
atr = AverageTrueRange(period=14)

# Keltner Channel
keltner = KeltnerChannel(period=20, k_multiplier=2.0)

# Donchian Channel
donchian = DonchianChannel(period=20)
```

### Trend Indicators

```python
from nautilus_trader.indicators.adx import AverageDirectionalIndex
from nautilus_trader.indicators.aroon import AroonOscillator
from nautilus_trader.indicators.psar import ParabolicSAR

# ADX
adx = AverageDirectionalIndex(period=14)

# Aroon
aroon = AroonOscillator(period=25)

# Parabolic SAR
psar = ParabolicSAR(af_initial=0.02, af_increment=0.02, af_max=0.2)
```

### Volume Indicators

```python
from nautilus_trader.indicators.obv import OnBalanceVolume
from nautilus_trader.indicators.vwap import VolumeWeightedAveragePrice

# OBV
obv = OnBalanceVolume()

# VWAP
vwap = VolumeWeightedAveragePrice()
```

### Other Indicators

```python
from nautilus_trader.indicators.spread_analyzer import SpreadAnalyzer
from nautilus_trader.indicators.efficiency_ratio import EfficiencyRatio
from nautilus_trader.indicators.linear_regression import LinearRegression

# Spread Analyzer
spread = SpreadAnalyzer(capacity=1000)

# Efficiency Ratio
er = EfficiencyRatio(period=10)

# Linear Regression
lr = LinearRegression(period=20)
```

## Using Indicators in Strategies

### Automatic Updates (Recommended)

Register indicators to receive automatic updates from bars:

```python
from nautilus_trader.trading import Strategy
from nautilus_trader.indicators.average import ExponentialMovingAverage
from nautilus_trader.indicators.rsi import RelativeStrengthIndex
from nautilus_trader.model.data import BarType

class IndicatorStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.bar_type = BarType.from_str(config.bar_type)

        # Create indicators
        self.ema_fast = ExponentialMovingAverage(period=12)
        self.ema_slow = ExponentialMovingAverage(period=26)
        self.rsi = RelativeStrengthIndex(period=14)

    def on_start(self):
        # Register indicators for automatic bar updates
        self.register_indicator_for_bars(self.bar_type, self.ema_fast)
        self.register_indicator_for_bars(self.bar_type, self.ema_slow)
        self.register_indicator_for_bars(self.bar_type, self.rsi)

        # Subscribe to bars
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar):
        # Indicators are automatically updated BEFORE on_bar is called
        if not self.indicators_initialized():
            return

        # Access indicator values
        fast_ema = self.ema_fast.value
        slow_ema = self.ema_slow.value
        rsi_value = self.rsi.value

        self.log.info(f"EMA Fast: {fast_ema:.2f}, Slow: {slow_ema:.2f}, RSI: {rsi_value:.2f}")

    def indicators_initialized(self) -> bool:
        """Check if all indicators have enough data."""
        return (
            self.ema_fast.initialized
            and self.ema_slow.initialized
            and self.rsi.initialized
        )
```

### Manual Updates

For tick-level or custom update logic:

```python
class ManualIndicatorStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.ema = ExponentialMovingAverage(period=20)

    def on_trade_tick(self, tick):
        # Manually update with trade price
        self.ema.update_raw(float(tick.price))

        if self.ema.initialized:
            self.log.info(f"EMA: {self.ema.value:.2f}")

    def on_quote_tick(self, tick):
        # Update with mid price
        mid = (float(tick.bid_price) + float(tick.ask_price)) / 2
        self.ema.update_raw(mid)
```

### Register for Quote/Trade Ticks

```python
def on_start(self):
    # Register indicator for quote ticks
    self.register_indicator_for_quote_ticks(
        instrument_id=self.instrument_id,
        indicator=self.spread_analyzer,
    )

    # Register indicator for trade ticks
    self.register_indicator_for_trade_ticks(
        instrument_id=self.instrument_id,
        indicator=self.volume_indicator,
    )

    self.subscribe_quote_ticks(self.instrument_id)
    self.subscribe_trade_ticks(self.instrument_id)
```

## Indicator Properties

### Common Properties

```python
# Check if indicator has enough data
if indicator.initialized:
    value = indicator.value

# Get indicator name
name = indicator.name

# Check how many updates received
count = indicator.count

# Check period (if applicable)
period = indicator.period
```

### Specific Indicator Values

```python
# Bollinger Bands
bb = BollingerBands(period=20, k=2.0)
upper = bb.upper
middle = bb.middle
lower = bb.lower

# MACD
macd = MovingAverageConvergenceDivergence(12, 26, 9)
macd_line = macd.value      # MACD line
signal_line = macd.signal   # Signal line
histogram = macd.histogram  # MACD - Signal

# Stochastics
stoch = Stochastics(14, 3)
k_value = stoch.value_k  # %K
d_value = stoch.value_d  # %D

# ADX
adx = AverageDirectionalIndex(14)
adx_value = adx.value     # ADX
plus_di = adx.plus_di     # +DI
minus_di = adx.minus_di   # -DI

# ATR
atr = AverageTrueRange(14)
atr_value = atr.value
```

## Indicator Warm-up

### Pre-loading Historical Data

```python
class WarmupStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.ema = ExponentialMovingAverage(period=200)
        self.warmup_complete = False

    def on_start(self):
        self.register_indicator_for_bars(self.bar_type, self.ema)

        # Request historical bars for warmup
        self.request_bars(
            bar_type=self.bar_type,
            start=self.clock.utc_now() - timedelta(days=30),
            end=self.clock.utc_now(),
        )

        self.subscribe_bars(self.bar_type)

    def on_historical_data(self, data):
        """Historical bars warm up indicators automatically."""
        self.warmup_complete = True
        self.log.info(f"Warmup complete with {len(data)} bars")
        self.log.info(f"EMA initialized: {self.ema.initialized}")

    def on_bar(self, bar):
        if not self.warmup_complete or not self.ema.initialized:
            return

        # Now safe to use indicator
        self.log.info(f"EMA: {self.ema.value:.2f}")
```

### Checking Initialization

```python
def on_bar(self, bar):
    # Individual check
    if not self.ema.initialized:
        return

    # Multiple indicators
    if not all([
        self.ema_fast.initialized,
        self.ema_slow.initialized,
        self.rsi.initialized,
        self.atr.initialized,
    ]):
        return

    # Now all indicators are ready
```

## Custom Indicators

### Basic Custom Indicator

```python
from nautilus_trader.indicators.base.indicator import Indicator
from nautilus_trader.model.data import Bar

class CustomMomentum(Indicator):
    """
    Custom momentum indicator.

    Calculates: (close - close[n]) / close[n] * 100
    """

    def __init__(self, period: int):
        super().__init__([period])
        self.period = period
        self._prices: list[float] = []
        self._value: float = 0.0

    @property
    def value(self) -> float:
        return self._value

    def handle_bar(self, bar: Bar) -> None:
        """Update indicator with bar data."""
        self._prices.append(float(bar.close))

        if len(self._prices) > self.period:
            self._prices.pop(0)

        if len(self._prices) >= self.period:
            old_price = self._prices[0]
            new_price = self._prices[-1]
            self._value = ((new_price - old_price) / old_price) * 100
            self._set_initialized(True)

    def _reset(self) -> None:
        """Reset indicator state."""
        self._prices.clear()
        self._value = 0.0
        self._set_initialized(False)
```

### Custom Indicator with Multiple Values

```python
class CustomBands(Indicator):
    """Custom indicator returning multiple values."""

    def __init__(self, period: int, multiplier: float = 2.0):
        super().__init__([period, multiplier])
        self.period = period
        self.multiplier = multiplier
        self._prices: list[float] = []
        self._upper: float = 0.0
        self._middle: float = 0.0
        self._lower: float = 0.0

    @property
    def upper(self) -> float:
        return self._upper

    @property
    def middle(self) -> float:
        return self._middle

    @property
    def lower(self) -> float:
        return self._lower

    def handle_bar(self, bar: Bar) -> None:
        self._prices.append(float(bar.close))

        if len(self._prices) > self.period:
            self._prices.pop(0)

        if len(self._prices) >= self.period:
            self._middle = sum(self._prices) / len(self._prices)

            variance = sum((p - self._middle) ** 2 for p in self._prices) / len(self._prices)
            std = variance ** 0.5

            self._upper = self._middle + (std * self.multiplier)
            self._lower = self._middle - (std * self.multiplier)

            self._set_initialized(True)

    def _reset(self) -> None:
        self._prices.clear()
        self._upper = 0.0
        self._middle = 0.0
        self._lower = 0.0
        self._set_initialized(False)
```

### Using Custom Indicators

```python
class CustomIndicatorStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.momentum = CustomMomentum(period=10)
        self.bands = CustomBands(period=20, multiplier=2.0)

    def on_start(self):
        self.register_indicator_for_bars(self.bar_type, self.momentum)
        self.register_indicator_for_bars(self.bar_type, self.bands)
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar):
        if not (self.momentum.initialized and self.bands.initialized):
            return

        self.log.info(f"Momentum: {self.momentum.value:.2f}%")
        self.log.info(f"Bands: {self.bands.lower:.2f} - {self.bands.upper:.2f}")
```

## Common Strategy Patterns

### 1. Moving Average Crossover

```python
class MACrossoverStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.ema_fast = ExponentialMovingAverage(config.fast_period)
        self.ema_slow = ExponentialMovingAverage(config.slow_period)
        self.prev_fast = None
        self.prev_slow = None

    def on_bar(self, bar):
        if not (self.ema_fast.initialized and self.ema_slow.initialized):
            return

        fast = self.ema_fast.value
        slow = self.ema_slow.value

        # Detect crossover
        if self.prev_fast and self.prev_slow:
            # Bullish crossover
            if self.prev_fast <= self.prev_slow and fast > slow:
                self.go_long(bar.bar_type.instrument_id)

            # Bearish crossover
            elif self.prev_fast >= self.prev_slow and fast < slow:
                self.go_short(bar.bar_type.instrument_id)

        self.prev_fast = fast
        self.prev_slow = slow
```

### 2. RSI Mean Reversion

```python
class RSIMeanReversionStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.rsi = RelativeStrengthIndex(period=14)
        self.oversold = config.oversold  # e.g., 30
        self.overbought = config.overbought  # e.g., 70

    def on_bar(self, bar):
        if not self.rsi.initialized:
            return

        rsi_value = self.rsi.value
        instrument_id = bar.bar_type.instrument_id

        # Oversold - potential buy
        if rsi_value < self.oversold:
            if not self.portfolio.is_net_long(instrument_id):
                self.buy(instrument_id)

        # Overbought - potential sell
        elif rsi_value > self.overbought:
            if self.portfolio.is_net_long(instrument_id):
                self.close_all_positions(instrument_id)
```

### 3. Bollinger Band Breakout

```python
class BollingerBreakoutStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.bb = BollingerBands(period=20, k=2.0)
        self.atr = AverageTrueRange(period=14)

    def on_bar(self, bar):
        if not (self.bb.initialized and self.atr.initialized):
            return

        close = float(bar.close)
        instrument_id = bar.bar_type.instrument_id

        # Breakout above upper band
        if close > self.bb.upper:
            if not self.portfolio.is_net_long(instrument_id):
                self.buy(instrument_id)
                self.set_stop_loss(close - 2 * self.atr.value)

        # Breakout below lower band
        elif close < self.bb.lower:
            if self.portfolio.is_net_long(instrument_id):
                self.close_all_positions(instrument_id)
```

### 4. Multi-Indicator Confirmation

```python
class MultiIndicatorStrategy(Strategy):

    def __init__(self, config):
        super().__init__(config)
        self.ema = ExponentialMovingAverage(period=50)
        self.rsi = RelativeStrengthIndex(period=14)
        self.macd = MovingAverageConvergenceDivergence(12, 26, 9)
        self.adx = AverageDirectionalIndex(period=14)

    def on_bar(self, bar):
        if not self.all_initialized():
            return

        close = float(bar.close)
        instrument_id = bar.bar_type.instrument_id

        # Trend filter: price above EMA and ADX > 25
        trend_up = close > self.ema.value and self.adx.value > 25

        # Momentum confirmation: RSI not overbought and MACD positive
        momentum_ok = self.rsi.value < 70 and self.macd.value > 0

        # Entry signal
        if trend_up and momentum_ok:
            if not self.portfolio.is_net_long(instrument_id):
                self.buy(instrument_id)

    def all_initialized(self) -> bool:
        return all([
            self.ema.initialized,
            self.rsi.initialized,
            self.macd.initialized,
            self.adx.initialized,
        ])
```

## Resetting Indicators

```python
def on_reset(self):
    """Reset all indicators to initial state."""
    self.ema_fast.reset()
    self.ema_slow.reset()
    self.rsi.reset()
    self.atr.reset()
```

## Next Steps

- **Build strategies:** Read `strategy-development.md`
- **Backtest strategies:** Read `backtesting.md`
- **See examples:** Read `examples.md`
- **Best practices:** Read `best-practices.md`

## Additional Resources

- **Indicators Docs:** https://nautilustrader.io/docs/latest/concepts/indicators/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/indicators/
- **Built-in Indicators:** https://github.com/nautechsystems/nautilus_trader/tree/develop/nautilus_trader/indicators

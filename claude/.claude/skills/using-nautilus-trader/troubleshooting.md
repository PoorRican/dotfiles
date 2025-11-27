# Troubleshooting Guide

## Installation Issues

### Import Errors

**Problem:** `ImportError: No module named 'nautilus_trader'`

**Solutions:**
```bash
# Verify installation
pip show nautilus_trader

# Check Python path
which python
which pip

# Reinstall
pip uninstall nautilus_trader
pip install nautilus_trader

# Verify imports
python -c "import nautilus_trader; print(nautilus_trader.__version__)"
```

### Compilation Errors (Building from Source)

**Problem:** C/C++ compiler errors

**Solutions:**
```bash
# Linux - Install build tools
sudo apt-get install build-essential python3-dev

# macOS - Install Xcode tools
xcode-select --install

# Windows - Install Visual C++ Build Tools
# Download from Microsoft
```

### Windows High-Precision Error

**Problem:** Attempting to use 128-bit precision on Windows

**Solution:**
- Windows only supports 64-bit (standard precision)
- Design strategies with 9 decimal places maximum
- Or use Linux/macOS for high-precision mode

## Data Loading Issues

### Instrument ID Mismatch

**Problem:** Data not being processed, no bars/ticks received

**Solutions:**
```python
# ✅ Correct - Exact match
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")

# ❌ Incorrect - Mismatch
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
bar_type = BarType.from_str("BTCUSD.BINANCE-1-MINUTE-LAST-EXTERNAL")  # Wrong!
```

### Data Not Sorted

**Problem:** `ValueError: Data must be sorted chronologically`

**Solution:**
```python
# Sort data before adding to engine
bars = sorted(bars, key=lambda x: x.ts_event)
engine.add_data(bars)
```

### Data Timestamp Issues

**Problem:** Data in wrong timezone or format

**Solution:**
```python
# Ensure UTC timestamps
import pandas as pd

# Convert to UTC
df['timestamp'] = pd.to_datetime(df['timestamp']).dt.tz_localize('UTC')
```

## Backtesting Issues

### Orders Not Filling

**Problem:** Orders submitted but never filled

**Solutions:**
1. **Check fill model:**
```python
# Increase fill probability
fill_model = FillModel(
    prob_fill_on_limit=1.0,  # Always fill
    prob_slippage=0.0,
)
```

2. **Verify price within spread:**
```python
# For quote tick data, ensure limit price is within bid/ask
if order_side == OrderSide.BUY:
    limit_price <= ask_price
else:
    limit_price >= bid_price
```

3. **Check account balance:**
```python
account = engine.trader.portfolio.account(venue)
print(f"Balance: {account.balance()}")
```

### Strategy Not Executing

**Problem:** Strategy starts but no trades

**Debug Steps:**
```python
def on_start(self):
    self.log.info("Strategy started")
    self.log.info(f"Subscribed to: {self.bar_type}")

def on_bar(self, bar):
    self.log.info(f"Received bar: {bar}")
    
    if not self.indicator.initialized:
        self.log.warning("Indicator not initialized")
        return
```

### Inconsistent Backtest Results

**Problem:** Different results on same data

**Solutions:**
```python
# Set random seed for reproducibility
fill_model = FillModel(
    prob_fill_on_limit=0.2,
    prob_slippage=0.5,
    random_seed=42,  # Fixed seed
)
```

## Live Trading Issues

### Connection Problems

**Problem:** Cannot connect to venue

**Solutions:**
1. **Check API credentials:**
```python
# Verify environment variables
import os
print(os.getenv("BINANCE_API_KEY"))  # Should not be None
```

2. **Check network connectivity:**
```bash
# Test connection
ping api.binance.com

# Check firewall rules
```

3. **Verify API permissions:**
- Ensure API key has required permissions
- Check IP whitelist settings
- Verify testnet vs. mainnet configuration

### Redis Connection Issues

**Problem:** Cannot connect to Redis

**Solutions:**
```bash
# Check Redis is running
redis-cli ping
# Should return "PONG"

# Check Redis port
netstat -an | grep 6379

# Start Redis
redis-server  # or docker start redis

# Check Redis logs
redis-cli INFO
```

### Order Rejection

**Problem:** Orders rejected by venue

**Common Reasons:**
1. **Insufficient balance**
2. **Invalid price (outside limits)**
3. **Invalid quantity (below minimum)**
4. **Rate limit exceeded**
5. **Market closed**

**Debug:**
```python
def on_order_rejected(self, event):
    self.log.error(f"Order rejected: {event.reason}")
    self.log.error(f"Order: {event.client_order_id}")
```

### Position Reconciliation Issues

**Problem:** System position doesn't match venue

**Solution:**
- Let reconciliation complete on startup
- Check logs for reconciliation events
- Verify order history matches
- May need to manually close positions

## Performance Issues

### High Memory Usage

**Problem:** Backtest consuming too much memory

**Solutions:**
```python
# 1. Use high-level API with streaming
config = BacktestRunConfig(
    data=[
        BacktestDataConfig(
            catalog_path="./catalog",  # Streams from disk
            # ...
        )
    ]
)

# 2. Reduce data resolution
# Use 5-minute bars instead of 1-minute

# 3. Clear cache periodically
engine.cache.clear()  # Use carefully
```

### Slow Backtests

**Problem:** Backtests taking too long

**Solutions:**
1. **Reduce data granularity:**
```python
# Use bars instead of ticks
subscribe_bars(bar_type)  # Faster

# Use larger timeframes
"BTCUSDT.BINANCE-1-HOUR-LAST-EXTERNAL"  # vs 1-MINUTE
```

2. **Optimize indicator calculations:**
```python
# Use built-in indicators (optimized)
from nautilus_trader.indicators import ExponentialMovingAverage

# Avoid complex calculations in on_bar
```

3. **Use ParquetDataCatalog:**
```python
# Parquet format is optimized for reading
catalog = ParquetDataCatalog("./catalog")
```

### High CPU Usage Live

**Problem:** High CPU usage during live trading

**Solutions:**
- Reduce subscription frequency
- Minimize indicator calculations
- Check for busy loops
- Review logging verbosity

## Strategy Issues

### Indicator Not Initializing

**Problem:** `indicator.initialized` always False

**Solution:**
```python
def on_start(self):
    # Register indicator for automatic updates
    self.register_indicator_for_bars(self.bar_type, self.indicator)
    
    # Subscribe to bars
    self.subscribe_bars(self.bar_type)

def on_bar(self, bar):
    # Check initialization
    if not self.indicator.initialized:
        self.log.debug(f"Indicator needs {self.indicator.period} bars")
        return
```

### State Not Persisting

**Problem:** Strategy state lost after restart

**Solution:**
```python
def on_save(self) -> dict:
    """Must implement to save state."""
    return {
        "trade_count": self.trade_count,
        "last_trade": self.last_trade,
    }

def on_load(self, state: dict):
    """Must implement to load state."""
    self.trade_count = state.get("trade_count", 0)
    self.last_trade = state.get("last_trade")
```

## Error Messages

### Common Error Messages

**"Data must be sorted chronologically"**
- Sort data by timestamp before adding
```python
data = sorted(data, key=lambda x: x.ts_event)
```

**"Instrument not found in cache"**
- Add instrument before adding data
```python
engine.add_instrument(instrument)
engine.add_data(bars)
```

**"Order rejected: insufficient balance"**
- Check account balance
- Reduce position size

**"Cannot modify order: order already filled"**
- Check order status before modifying
- Handle race conditions

**"Redis connection refused"**
- Start Redis server
- Check host/port configuration

## Debug Techniques

### Enable Debug Logging

```python
from nautilus_trader.config import LoggingConfig

logging_config = LoggingConfig(
    log_level="DEBUG",  # More verbose
    log_level_file="DEBUG",
)
```

### Inspect Cache

```python
# In strategy
instruments = self.cache.instruments()
orders = self.cache.orders()
positions = self.cache.positions()

self.log.info(f"Instruments: {len(instruments)}")
self.log.info(f"Orders: {len(orders)}")
self.log.info(f"Positions: {len(positions)}")
```

### Check Component State

```python
# Component state
self.log.info(f"Strategy state: {self.state}")
self.log.info(f"Is running: {self.is_running}")
self.log.info(f"Is connected: {self.is_connected}")
```

## Getting Help

When asking for help, provide:
1. **Version information:**
```python
import nautilus_trader
print(nautilus_trader.__version__)
```

2. **Minimal reproducible example**
3. **Full error traceback**
4. **Configuration used**
5. **Expected vs actual behavior**

### Community Resources

- **GitHub Issues:** https://github.com/nautechsystems/nautilus_trader/issues
- **Discord:** Join community server
- **Documentation:** https://nautilustrader.io/docs/

### Before Opening Issue

- [ ] Search existing issues
- [ ] Check documentation
- [ ] Try on latest version
- [ ] Create minimal example
- [ ] Include version info
- [ ] Include full traceback

## Common Solutions Checklist

**Installation:**
- [ ] Correct Python version (3.11+)
- [ ] Virtual environment active
- [ ] Latest version installed

**Data:**
- [ ] Data sorted chronologically
- [ ] Instrument IDs match exactly
- [ ] Timestamps in UTC
- [ ] Instruments added before data

**Backtesting:**
- [ ] Venue configured correctly
- [ ] Fill model appropriate
- [ ] Strategy subscribed to data
- [ ] Indicators registered

**Live Trading:**
- [ ] API credentials correct
- [ ] Network connectivity good
- [ ] Redis running (if used)
- [ ] Testnet mode for testing
- [ ] Risk management configured

Remember: Most issues are configuration related. Double-check configurations first!
EOF
cat /mnt/skills/user/nautilus-trader/troubleshooting.md
Output

# Troubleshooting Guide

## Installation Issues

### Import Errors

**Problem:** `ImportError: No module named 'nautilus_trader'`

**Solutions:**
```bash
# Verify installation
pip show nautilus_trader

# Check Python path
which python
which pip

# Reinstall
pip uninstall nautilus_trader
pip install nautilus_trader

# Verify imports
python -c "import nautilus_trader; print(nautilus_trader.__version__)"
```

### Compilation Errors (Building from Source)

**Problem:** C/C++ compiler errors

**Solutions:**
```bash
# Linux - Install build tools
sudo apt-get install build-essential python3-dev

# macOS - Install Xcode tools
xcode-select --install

# Windows - Install Visual C++ Build Tools
# Download from Microsoft
```

### Windows High-Precision Error

**Problem:** Attempting to use 128-bit precision on Windows

**Solution:**
- Windows only supports 64-bit (standard precision)
- Design strategies with 9 decimal places maximum
- Or use Linux/macOS for high-precision mode

## Data Loading Issues

### Instrument ID Mismatch

**Problem:** Data not being processed, no bars/ticks received

**Solutions:**
```python
# ✅ Correct - Exact match
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")

# ❌ Incorrect - Mismatch
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
bar_type = BarType.from_str("BTCUSD.BINANCE-1-MINUTE-LAST-EXTERNAL")  # Wrong!
```

### Data Not Sorted

**Problem:** `ValueError: Data must be sorted chronologically`

**Solution:**
```python
# Sort data before adding to engine
bars = sorted(bars, key=lambda x: x.ts_event)
engine.add_data(bars)
```

### Data Timestamp Issues

**Problem:** Data in wrong timezone or format

**Solution:**
```python
# Ensure UTC timestamps
import pandas as pd

# Convert to UTC
df['timestamp'] = pd.to_datetime(df['timestamp']).dt.tz_localize('UTC')
```

## Backtesting Issues

### Orders Not Filling

**Problem:** Orders submitted but never filled

**Solutions:**
1. **Check fill model:**
```python
# Increase fill probability
fill_model = FillModel(
    prob_fill_on_limit=1.0,  # Always fill
    prob_slippage=0.0,
)
```

2. **Verify price within spread:**
```python
# For quote tick data, ensure limit price is within bid/ask
if order_side == OrderSide.BUY:
    limit_price <= ask_price
else:
    limit_price >= bid_price
```

3. **Check account balance:**
```python
account = engine.trader.portfolio.account(venue)
print(f"Balance: {account.balance()}")
```

### Strategy Not Executing

**Problem:** Strategy starts but no trades

**Debug Steps:**
```python
def on_start(self):
    self.log.info("Strategy started")
    self.log.info(f"Subscribed to: {self.bar_type}")

def on_bar(self, bar):
    self.log.info(f"Received bar: {bar}")
    
    if not self.indicator.initialized:
        self.log.warning("Indicator not initialized")
        return
```

### Inconsistent Backtest Results

**Problem:** Different results on same data

**Solutions:**
```python
# Set random seed for reproducibility
fill_model = FillModel(
    prob_fill_on_limit=0.2,
    prob_slippage=0.5,
    random_seed=42,  # Fixed seed
)
```

## Live Trading Issues

### Connection Problems

**Problem:** Cannot connect to venue

**Solutions:**
1. **Check API credentials:**
```python
# Verify environment variables
import os
print(os.getenv("BINANCE_API_KEY"))  # Should not be None
```

2. **Check network connectivity:**
```bash
# Test connection
ping api.binance.com

# Check firewall rules
```

3. **Verify API permissions:**
- Ensure API key has required permissions
- Check IP whitelist settings
- Verify testnet vs. mainnet configuration

### Redis Connection Issues

**Problem:** Cannot connect to Redis

**Solutions:**
```bash
# Check Redis is running
redis-cli ping
# Should return "PONG"

# Check Redis port
netstat -an | grep 6379

# Start Redis
redis-server  # or docker start redis

# Check Redis logs
redis-cli INFO
```

### Order Rejection

**Problem:** Orders rejected by venue

**Common Reasons:**
1. **Insufficient balance**
2. **Invalid price (outside limits)**
3. **Invalid quantity (below minimum)**
4. **Rate limit exceeded**
5. **Market closed**

**Debug:**
```python
def on_order_rejected(self, event):
    self.log.error(f"Order rejected: {event.reason}")
    self.log.error(f"Order: {event.client_order_id}")
```

### Position Reconciliation Issues

**Problem:** System position doesn't match venue

**Solution:**
- Let reconciliation complete on startup
- Check logs for reconciliation events
- Verify order history matches
- May need to manually close positions

## Performance Issues

### High Memory Usage

**Problem:** Backtest consuming too much memory

**Solutions:**
```python
# 1. Use high-level API with streaming
config = BacktestRunConfig(
    data=[
        BacktestDataConfig(
            catalog_path="./catalog",  # Streams from disk
            # ...
        )
    ]
)

# 2. Reduce data resolution
# Use 5-minute bars instead of 1-minute

# 3. Clear cache periodically
engine.cache.clear()  # Use carefully
```

### Slow Backtests

**Problem:** Backtests taking too long

**Solutions:**
1. **Reduce data granularity:**
```python
# Use bars instead of ticks
subscribe_bars(bar_type)  # Faster

# Use larger timeframes
"BTCUSDT.BINANCE-1-HOUR-LAST-EXTERNAL"  # vs 1-MINUTE
```

2. **Optimize indicator calculations:**
```python
# Use built-in indicators (optimized)
from nautilus_trader.indicators import ExponentialMovingAverage

# Avoid complex calculations in on_bar
```

3. **Use ParquetDataCatalog:**
```python
# Parquet format is optimized for reading
catalog = ParquetDataCatalog("./catalog")
```

### High CPU Usage Live

**Problem:** High CPU usage during live trading

**Solutions:**
- Reduce subscription frequency
- Minimize indicator calculations
- Check for busy loops
- Review logging verbosity

## Strategy Issues

### Indicator Not Initializing

**Problem:** `indicator.initialized` always False

**Solution:**
```python
def on_start(self):
    # Register indicator for automatic updates
    self.register_indicator_for_bars(self.bar_type, self.indicator)
    
    # Subscribe to bars
    self.subscribe_bars(self.bar_type)

def on_bar(self, bar):
    # Check initialization
    if not self.indicator.initialized:
        self.log.debug(f"Indicator needs {self.indicator.period} bars")
        return
```

### State Not Persisting

**Problem:** Strategy state lost after restart

**Solution:**
```python
def on_save(self) -> dict:
    """Must implement to save state."""
    return {
        "trade_count": self.trade_count,
        "last_trade": self.last_trade,
    }

def on_load(self, state: dict):
    """Must implement to load state."""
    self.trade_count = state.get("trade_count", 0)
    self.last_trade = state.get("last_trade")
```

## Error Messages

### Common Error Messages

**"Data must be sorted chronologically"**
- Sort data by timestamp before adding
```python
data = sorted(data, key=lambda x: x.ts_event)
```

**"Instrument not found in cache"**
- Add instrument before adding data
```python
engine.add_instrument(instrument)
engine.add_data(bars)
```

**"Order rejected: insufficient balance"**
- Check account balance
- Reduce position size

**"Cannot modify order: order already filled"**
- Check order status before modifying
- Handle race conditions

**"Redis connection refused"**
- Start Redis server
- Check host/port configuration

## Debug Techniques

### Enable Debug Logging

```python
from nautilus_trader.config import LoggingConfig

logging_config = LoggingConfig(
    log_level="DEBUG",  # More verbose
    log_level_file="DEBUG",
)
```

### Inspect Cache

```python
# In strategy
instruments = self.cache.instruments()
orders = self.cache.orders()
positions = self.cache.positions()

self.log.info(f"Instruments: {len(instruments)}")
self.log.info(f"Orders: {len(orders)}")
self.log.info(f"Positions: {len(positions)}")
```

### Check Component State

```python
# Component state
self.log.info(f"Strategy state: {self.state}")
self.log.info(f"Is running: {self.is_running}")
self.log.info(f"Is connected: {self.is_connected}")
```

## Getting Help

When asking for help, provide:
1. **Version information:**
```python
import nautilus_trader
print(nautilus_trader.__version__)
```

2. **Minimal reproducible example**
3. **Full error traceback**
4. **Configuration used**
5. **Expected vs actual behavior**

### Community Resources

- **GitHub Issues:** https://github.com/nautechsystems/nautilus_trader/issues
- **Discord:** Join community server
- **Documentation:** https://nautilustrader.io/docs/

### Before Opening Issue

- [ ] Search existing issues
- [ ] Check documentation
- [ ] Try on latest version
- [ ] Create minimal example
- [ ] Include version info
- [ ] Include full traceback

## Common Solutions Checklist

**Installation:**
- [ ] Correct Python version (3.11+)
- [ ] Virtual environment active
- [ ] Latest version installed

**Data:**
- [ ] Data sorted chronologically
- [ ] Instrument IDs match exactly
- [ ] Timestamps in UTC
- [ ] Instruments added before data

**Backtesting:**
- [ ] Venue configured correctly
- [ ] Fill model appropriate
- [ ] Strategy subscribed to data
- [ ] Indicators registered

**Live Trading:**
- [ ] API credentials correct
- [ ] Network connectivity good
- [ ] Redis running (if used)
- [ ] Testnet mode for testing
- [ ] Risk management configured

Remember: Most issues are configuration related. Double-check configurations first!

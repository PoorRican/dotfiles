# Best Practices

## Configuration Management

### Use Configuration Objects

```python
# ✅ Good - Configuration object
class MyStrategyConfig(StrategyConfig):
    instrument_id: str
    bar_type: str
    fast_period: int = 10
    slow_period: int = 20

# ❌ Bad - Hardcoded values
class MyStrategy(Strategy):
    def __init__(self):
        self.fast_period = 10  # Hardcoded
```

### Environment Variables for Secrets

```python
# ✅ Good - Environment variables
api_key = os.getenv("BINANCE_API_KEY")
api_secret = os.getenv("BINANCE_API_SECRET")

# ❌ Bad - Hardcoded credentials
api_key = "abc123..."  # Never do this!
```

### Version Control

- Store strategy configurations in version control
- Use separate config files for dev/staging/production
- Never commit API keys or secrets

## Testing

### Backtest Before Live

```python
# 1. Backtest with realistic parameters
fill_model = FillModel(
    prob_fill_on_limit=0.2,
    prob_slippage=0.5,
)

# 2. Test on multiple time periods
periods = [
    ("2023-01-01", "2023-06-30"),
    ("2023-07-01", "2023-12-31"),
    ("2024-01-01", "2024-06-30"),
]

# 3. Test with different market conditions
```

### Walk-Forward Analysis

```python
# Train on historical data, test on out-of-sample
train_start = "2023-01-01"
train_end = "2023-12-31"
test_start = "2024-01-01"
test_end = "2024-03-31"
```

### Paper Trading First

Always test live strategies on testnet/paper accounts:

```python
BinanceDataClientConfig(
    api_key="...",
    api_secret="...",
    testnet=True,  # Use testnet first!
)
```

## Performance Optimization

### Data Management

```python
# ✅ Good - Use appropriate data granularity
subscribe_bars("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")

# ❌ Bad - Unnecessary tick data for daily strategy
subscribe_quote_ticks(instrument_id)  # Too much data
```

### Indicator Efficiency

```python
# ✅ Good - Register for automatic updates
self.register_indicator_for_bars(bar_type, indicator)

# ❌ Bad - Manual updates every bar
def on_bar(self, bar):
    self.indicator.handle_bar(bar)  # Inefficient
```

### Minimize Subscriptions

```python
# ✅ Good - Only subscribe to needed data
self.subscribe_bars(bar_type)

# ❌ Bad - Subscribe to everything
self.subscribe_quote_ticks(instrument_id)
self.subscribe_trade_ticks(instrument_id)
self.subscribe_bars(bar_type)  # Unnecessary
```

## Risk Management

### Always Enforce Limits

```python
# Position limits
MAX_POSITION = Quantity.from_str("10.0")

def on_bar(self, bar):
    position = self.portfolio.net_position(instrument_id)
    if abs(position) >= MAX_POSITION:
        return  # Don't trade
```

### Stop Losses

```python
# Always use stops for risk management
stop_order = self.order_factory.stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=position_size,
    trigger_price=entry_price * 0.98,  # 2% stop
)
```

### Risk Engine Configuration

```python
# Never bypass in production
risk_config = RiskEngineConfig(
    bypass=False,  # CRITICAL
    max_order_submit_rate=100,
    max_notionals={
        "BTCUSDT.BINANCE": 10000.0,
    },
)
```

## Error Handling

### Handle Order Rejections

```python
def on_order_rejected(self, event):
    self.log.error(f"Order rejected: {event.reason}")
    
    if "insufficient balance" in event.reason.lower():
        self.stop()  # Stop strategy if out of funds
    elif "invalid price" in event.reason.lower():
        # Retry with adjusted price
        pass
```

### Connection Monitoring

```python
def on_bar(self, bar):
    # Check connectivity
    if not self.is_connected:
        self.log.error("Lost connection")
        # Implement reconnection logic
        return
```

## Code Organization

### Separate Concerns

```python
# ✅ Good - Modular design
class MyStrategy(Strategy):
    def calculate_signal(self, bar):
        """Signal generation logic."""
        pass
    
    def execute_trade(self, signal):
        """Order execution logic."""
        pass
    
    def manage_risk(self, position):
        """Risk management logic."""
        pass
```

### Use Type Hints

```python
# ✅ Good - Type hints for clarity
def calculate_position_size(
    self,
    price: Price,
    account_balance: Money
) -> Quantity:
    pass
```

## Logging

### Structured Logging

```python
self.log.info(
    "Trade executed",
    extra={
        "instrument": str(instrument_id),
        "side": str(order_side),
        "quantity": float(quantity),
        "price": float(price),
    }
)
```

### Appropriate Log Levels

```python
# DEBUG - Detailed diagnostic info
self.log.debug(f"Indicator value: {indicator.value}")

# INFO - General informational messages
self.log.info(f"Position opened: {position_id}")

# WARNING - Warning messages
self.log.warning(f"High latency detected: {latency}ms")

# ERROR - Error messages
self.log.error(f"Failed to submit order: {error}")
```

## State Management

### Save Important State

```python
def on_save(self) -> dict:
    """Save strategy state for recovery."""
    return {
        "trade_count": self.trade_count,
        "last_signal_time": self.last_signal_time,
        "active_trades": self.active_trades,
    }

def on_load(self, state: dict):
    """Load saved state."""
    self.trade_count = state.get("trade_count", 0)
    self.last_signal_time = state.get("last_signal_time")
```

### Clean Shutdown

```python
def on_stop(self):
    """Clean shutdown logic."""
    # Cancel pending orders
    for order in self.cache.orders_open():
        self.cancel_order(order)
    
    # Close positions if needed
    if self.close_positions_on_stop:
        for position in self.portfolio.positions_open():
            self.close_position(position)
```

## Production Deployment

### Monitoring Checklist

- [ ] Set up logging infrastructure
- [ ] Configure alerts for errors
- [ ] Monitor position sizes
- [ ] Track fill rates
- [ ] Monitor latency
- [ ] Set up PnL alerts
- [ ] Monitor API rate limits

### Gradual Rollout

1. Start with small position sizes
2. Monitor for 24-48 hours
3. Gradually increase positions
4. Continue monitoring

### Backup and Recovery

```python
# Database backups
# Regular Redis snapshots
# Save strategy configurations
# Document deployment procedures
```

## Common Pitfalls to Avoid

### 1. Look-Ahead Bias

```python
# ❌ Bad - Using future data
def on_bar(self, bar):
    # Don't use bar.high/low for entry signals
    # These are known only after bar closes
    if bar.close > bar.high:  # Logic error!
        pass
```

### 2. Overfitting

- Test on out-of-sample data
- Use walk-forward analysis
- Avoid excessive parameter optimization
- Keep strategies simple

### 3. Ignoring Transaction Costs

```python
# ✅ Good - Account for fees
expected_profit = (exit_price - entry_price) - commission - slippage
```

### 4. Insufficient Testing

- Test multiple market regimes
- Test with different data periods
- Test edge cases
- Test failure scenarios

### 5. No Risk Management

- Always use stop losses
- Enforce position limits
- Monitor drawdowns
- Have kill switch procedures

## Summary

**Before Live Trading:**
1. Extensive backtesting
2. Walk-forward validation
3. Paper trading
4. Small position sizes
5. Comprehensive monitoring

**During Live Trading:**
1. Active monitoring
2. Risk management
3. Proper logging
4. Error handling
5. Regular reviews

**Remember:**
- Test thoroughly
- Start small
- Monitor closely
- Manage risk
- Be prepared to stop
EOF
cat /mnt/skills/user/nautilus-trader/best-practices.md
Output

# Best Practices

## Configuration Management

### Use Configuration Objects

```python
# ✅ Good - Configuration object
class MyStrategyConfig(StrategyConfig):
    instrument_id: str
    bar_type: str
    fast_period: int = 10
    slow_period: int = 20

# ❌ Bad - Hardcoded values
class MyStrategy(Strategy):
    def __init__(self):
        self.fast_period = 10  # Hardcoded
```

### Environment Variables for Secrets

```python
# ✅ Good - Environment variables
api_key = os.getenv("BINANCE_API_KEY")
api_secret = os.getenv("BINANCE_API_SECRET")

# ❌ Bad - Hardcoded credentials
api_key = "abc123..."  # Never do this!
```

### Version Control

- Store strategy configurations in version control
- Use separate config files for dev/staging/production
- Never commit API keys or secrets

## Testing

### Backtest Before Live

```python
# 1. Backtest with realistic parameters
fill_model = FillModel(
    prob_fill_on_limit=0.2,
    prob_slippage=0.5,
)

# 2. Test on multiple time periods
periods = [
    ("2023-01-01", "2023-06-30"),
    ("2023-07-01", "2023-12-31"),
    ("2024-01-01", "2024-06-30"),
]

# 3. Test with different market conditions
```

### Walk-Forward Analysis

```python
# Train on historical data, test on out-of-sample
train_start = "2023-01-01"
train_end = "2023-12-31"
test_start = "2024-01-01"
test_end = "2024-03-31"
```

### Paper Trading First

Always test live strategies on testnet/paper accounts:

```python
BinanceDataClientConfig(
    api_key="...",
    api_secret="...",
    testnet=True,  # Use testnet first!
)
```

## Performance Optimization

### Data Management

```python
# ✅ Good - Use appropriate data granularity
subscribe_bars("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")

# ❌ Bad - Unnecessary tick data for daily strategy
subscribe_quote_ticks(instrument_id)  # Too much data
```

### Indicator Efficiency

```python
# ✅ Good - Register for automatic updates
self.register_indicator_for_bars(bar_type, indicator)

# ❌ Bad - Manual updates every bar
def on_bar(self, bar):
    self.indicator.handle_bar(bar)  # Inefficient
```

### Minimize Subscriptions

```python
# ✅ Good - Only subscribe to needed data
self.subscribe_bars(bar_type)

# ❌ Bad - Subscribe to everything
self.subscribe_quote_ticks(instrument_id)
self.subscribe_trade_ticks(instrument_id)
self.subscribe_bars(bar_type)  # Unnecessary
```

## Risk Management

### Always Enforce Limits

```python
# Position limits
MAX_POSITION = Quantity.from_str("10.0")

def on_bar(self, bar):
    position = self.portfolio.net_position(instrument_id)
    if abs(position) >= MAX_POSITION:
        return  # Don't trade
```

### Stop Losses

```python
# Always use stops for risk management
stop_order = self.order_factory.stop_market(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=position_size,
    trigger_price=entry_price * 0.98,  # 2% stop
)
```

### Risk Engine Configuration

```python
# Never bypass in production
risk_config = RiskEngineConfig(
    bypass=False,  # CRITICAL
    max_order_submit_rate=100,
    max_notionals={
        "BTCUSDT.BINANCE": 10000.0,
    },
)
```

## Error Handling

### Handle Order Rejections

```python
def on_order_rejected(self, event):
    self.log.error(f"Order rejected: {event.reason}")
    
    if "insufficient balance" in event.reason.lower():
        self.stop()  # Stop strategy if out of funds
    elif "invalid price" in event.reason.lower():
        # Retry with adjusted price
        pass
```

### Connection Monitoring

```python
def on_bar(self, bar):
    # Check connectivity
    if not self.is_connected:
        self.log.error("Lost connection")
        # Implement reconnection logic
        return
```

## Code Organization

### Separate Concerns

```python
# ✅ Good - Modular design
class MyStrategy(Strategy):
    def calculate_signal(self, bar):
        """Signal generation logic."""
        pass
    
    def execute_trade(self, signal):
        """Order execution logic."""
        pass
    
    def manage_risk(self, position):
        """Risk management logic."""
        pass
```

### Use Type Hints

```python
# ✅ Good - Type hints for clarity
def calculate_position_size(
    self,
    price: Price,
    account_balance: Money
) -> Quantity:
    pass
```

## Logging

### Structured Logging

```python
self.log.info(
    "Trade executed",
    extra={
        "instrument": str(instrument_id),
        "side": str(order_side),
        "quantity": float(quantity),
        "price": float(price),
    }
)
```

### Appropriate Log Levels

```python
# DEBUG - Detailed diagnostic info
self.log.debug(f"Indicator value: {indicator.value}")

# INFO - General informational messages
self.log.info(f"Position opened: {position_id}")

# WARNING - Warning messages
self.log.warning(f"High latency detected: {latency}ms")

# ERROR - Error messages
self.log.error(f"Failed to submit order: {error}")
```

## State Management

### Save Important State

```python
def on_save(self) -> dict:
    """Save strategy state for recovery."""
    return {
        "trade_count": self.trade_count,
        "last_signal_time": self.last_signal_time,
        "active_trades": self.active_trades,
    }

def on_load(self, state: dict):
    """Load saved state."""
    self.trade_count = state.get("trade_count", 0)
    self.last_signal_time = state.get("last_signal_time")
```

### Clean Shutdown

```python
def on_stop(self):
    """Clean shutdown logic."""
    # Cancel pending orders
    for order in self.cache.orders_open():
        self.cancel_order(order)
    
    # Close positions if needed
    if self.close_positions_on_stop:
        for position in self.portfolio.positions_open():
            self.close_position(position)
```

## Production Deployment

### Monitoring Checklist

- [ ] Set up logging infrastructure
- [ ] Configure alerts for errors
- [ ] Monitor position sizes
- [ ] Track fill rates
- [ ] Monitor latency
- [ ] Set up PnL alerts
- [ ] Monitor API rate limits

### Gradual Rollout

1. Start with small position sizes
2. Monitor for 24-48 hours
3. Gradually increase positions
4. Continue monitoring

### Backup and Recovery

```python
# Database backups
# Regular Redis snapshots
# Save strategy configurations
# Document deployment procedures
```

## Common Pitfalls to Avoid

### 1. Look-Ahead Bias

```python
# ❌ Bad - Using future data
def on_bar(self, bar):
    # Don't use bar.high/low for entry signals
    # These are known only after bar closes
    if bar.close > bar.high:  # Logic error!
        pass
```

### 2. Overfitting

- Test on out-of-sample data
- Use walk-forward analysis
- Avoid excessive parameter optimization
- Keep strategies simple

### 3. Ignoring Transaction Costs

```python
# ✅ Good - Account for fees
expected_profit = (exit_price - entry_price) - commission - slippage
```

### 4. Insufficient Testing

- Test multiple market regimes
- Test with different data periods
- Test edge cases
- Test failure scenarios

### 5. No Risk Management

- Always use stop losses
- Enforce position limits
- Monitor drawdowns
- Have kill switch procedures

## Summary

**Before Live Trading:**
1. Extensive backtesting
2. Walk-forward validation
3. Paper trading
4. Small position sizes
5. Comprehensive monitoring

**During Live Trading:**
1. Active monitoring
2. Risk management
3. Proper logging
4. Error handling
5. Regular reviews

**Remember:**
- Test thoroughly
- Start small
- Monitor closely
- Manage risk
- Be prepared to stop

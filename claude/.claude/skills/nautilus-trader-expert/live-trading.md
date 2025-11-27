# Live Trading Guide

## Overview

NautilusTrader's `TradingNode` enables live deployment of strategies with the same code used in backtesting.

**Location:** `nautilus_trader.live.node`, `nautilus_trader.config`

## TradingNode Setup

### Basic Configuration

```python
from nautilus_trader.live.node import TradingNode
from nautilus_trader.config import TradingNodeConfig
from nautilus_trader.adapters.binance.config import (
    BinanceDataClientConfig,
    BinanceExecClientConfig,
)

config = TradingNodeConfig(
    trader_id="TRADER-001",
    # Data clients
    data_clients={
        "BINANCE": BinanceDataClientConfig(
            api_key=os.getenv("BINANCE_API_KEY"),
            api_secret=os.getenv("BINANCE_API_SECRET"),
            testnet=True,  # Use testnet for testing
        ),
    },
    # Execution clients
    exec_clients={
        "BINANCE": BinanceExecClientConfig(
            api_key=os.getenv("BINANCE_API_KEY"),
            api_secret=os.getenv("BINANCE_API_SECRET"),
            testnet=True,
        ),
    },
    # Strategies
    strategies=[
        MyStrategyConfig(
            instrument_id="BTCUSDT.BINANCE",
        )
    ],
)

# Create and start node
node = TradingNode(config=config)
node.start()
```

### Running the Node

```python
# Build and start
node.build()
node.start()

# Stop gracefully
node.stop()

# Dispose resources
node.dispose()
```

## Database Configuration (Redis)

### Cache Database

```python
from nautilus_trader.config import CacheConfig, DatabaseConfig

cache_config = CacheConfig(
    database=DatabaseConfig(
        host="localhost",
        port=6379,
        username="nautilus",
        password="your_password",
        timeout=2.0,
    ),
    encoding="msgpack",  # or "json"
    timestamps_as_iso8601=True,
    buffer_interval_ms=100,
    flush_on_start=False,  # Set True to clear cache on startup
)

config = TradingNodeConfig(
    trader_id="TRADER-001",
    cache=cache_config,
    # ... other config
)
```

### Message Bus Configuration

```python
from nautilus_trader.config import MessageBusConfig

message_bus_config = MessageBusConfig(
    database=DatabaseConfig(
        host="localhost",
        port=6379,
    ),
    timestamps_as_iso8601=True,
    use_instance_id=False,
    types_filter=[QuoteTick, TradeTick],  # Filter message types
    stream_per_topic=False,
    autotrim_mins=30,  # Automatic message trimming
    heartbeat_interval_secs=1,
)

config = TradingNodeConfig(
    trader_id="TRADER-001",
    message_bus=message_bus_config,
    # ... other config
)
```

## Multi-Venue Trading

```python
config = TradingNodeConfig(
    trader_id="TRADER-001",
    data_clients={
        "BINANCE": BinanceDataClientConfig(...),
        "BYBIT": BybitDataClientConfig(...),
    },
    exec_clients={
        "BINANCE": BinanceExecClientConfig(...),
        "BYBIT": BybitExecClientConfig(...),
    },
    strategies=[
        ArbitrageStrategyConfig(
            binance_instrument="BTCUSDT.BINANCE",
            bybit_instrument="BTCUSDT.BYBIT",
        )
    ],
)
```

## Execution Reconciliation

On startup, the `LiveExecutionEngine` reconciles state:

**With Cached State:**
- Generates missing events to align state
- Handles partially filled orders
- Reconstructs position state

**Without Cached State:**
- Generates all orders and positions from venue reports
- Builds complete state from scratch

This ensures system state matches venue reality.

## Environment Variables

### Security Best Practices

```bash
# .env file
BINANCE_API_KEY=your_api_key_here
BINANCE_API_SECRET=your_api_secret_here
BYBIT_API_KEY=your_api_key_here
BYBIT_API_SECRET=your_api_secret_here

# Redis credentials
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
```

```python
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

config = TradingNodeConfig(
    data_clients={
        "BINANCE": BinanceDataClientConfig(
            api_key=os.getenv("BINANCE_API_KEY"),
            api_secret=os.getenv("BINANCE_API_SECRET"),
        ),
    },
)
```

## Risk Management

### Pre-Trade Risk Checks

```python
from nautilus_trader.config import RiskEngineConfig

risk_config = RiskEngineConfig(
    bypass=False,  # NEVER bypass in production
    max_order_submit_rate=100,  # Orders per second
    max_order_modify_rate=50,
    max_notionals={
        "BTCUSDT.BINANCE": 50000.0,  # Max $50k per order
    },
)

config = TradingNodeConfig(
    trader_id="TRADER-001",
    risk_engine=risk_config,
    # ... other config
)
```

### Position Limits

Implement in strategy:

```python
class RiskManagedStrategy(Strategy):
    def __init__(self, config):
        super().__init__(config)
        self.max_position = Quantity.from_str("10.0")
    
    def on_bar(self, bar):
        current_position = self.portfolio.net_position(bar.bar_type.instrument_id)
        
        if abs(current_position) >= self.max_position:
            self.log.warning("Position limit reached")
            return
        
        # Trading logic
```

## Monitoring and Logging

### Structured Logging

```python
from nautilus_trader.config import LoggingConfig

logging_config = LoggingConfig(
    log_level="INFO",
    log_level_file="DEBUG",
    log_directory="logs",
    log_file_name="nautilus",
    log_file_format="json",  # or "plain"
    log_colors=True,
)

config = TradingNodeConfig(
    trader_id="TRADER-001",
    logging=logging_config,
    # ... other config
)
```

### Strategy Logging

```python
def on_bar(self, bar):
    self.log.info(
        "Processing bar",
        extra={
            "instrument": str(bar.bar_type.instrument_id),
            "close": float(bar.close),
            "volume": float(bar.volume),
        }
    )
```

## Shutdown Handling

### Graceful Shutdown

```python
import signal
import sys

def signal_handler(sig, frame):
    print("Shutting down gracefully...")
    node.stop()
    node.dispose()
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)  # Ctrl+C
signal.signal(signal.SIGTERM, signal_handler)  # Kill signal

# Run node
node.start()
```

**Note:** Windows SIGINT support tracked in issue #2785. Use `LiveNode` (v2 system) for better Ctrl+C handling.

## Paper Trading

### Testnet/Demo Accounts

```python
# Binance Testnet
BinanceDataClientConfig(
    api_key="...",
    api_secret="...",
    testnet=True,  # Use testnet
)

# Bybit Demo
BybitDataClientConfig(
    api_key="...",
    api_secret="...",
    is_testnet=True,
)
```

### Benefits of Paper Trading

- Test strategies with real market data
- No financial risk
- Validate order execution logic
- Practice deployment procedures

## Production Deployment

### Deployment Checklist

- [ ] Test extensively in backtest
- [ ] Validate on testnet/paper accounts
- [ ] Review risk management settings
- [ ] Set position and order limits
- [ ] Configure proper logging
- [ ] Set up monitoring and alerts
- [ ] Test graceful shutdown
- [ ] Verify credential security
- [ ] Document strategy parameters
- [ ] Plan for failure scenarios

### Running as Service

```bash
# Using systemd (Linux)
# Create /etc/systemd/system/nautilus-trader.service

[Unit]
Description=NautilusTrader Trading Bot
After=network.target redis.service

[Service]
Type=simple
User=trader
WorkingDirectory=/home/trader/nautilus
ExecStart=/home/trader/nautilus/.venv/bin/python run_live.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable nautilus-trader
sudo systemctl start nautilus-trader
sudo systemctl status nautilus-trader
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . .

# Run application
CMD ["python", "run_live.py"]
```

```bash
# Build and run
docker build -t nautilus-trader .
docker run -d --name trader \
  --env-file .env \
  --network host \
  nautilus-trader
```

## Monitoring Strategies

### Health Checks

```python
def on_bar(self, bar):
    # Monitor connectivity
    if not self.is_connected:
        self.log.error("Lost connection to venue")
        # Implement reconnection logic
    
    # Monitor latency
    latency = self.clock.timestamp_ns() - bar.ts_event
    if latency > 1_000_000_000:  # 1 second
        self.log.warning(f"High latency detected: {latency}ns")
    
    # Monitor position size
    position = self.portfolio.net_position(bar.bar_type.instrument_id)
    if abs(position) > self.alert_threshold:
        self.log.warning(f"Large position: {position}")
```

### External Monitoring

- Use Redis monitoring for message bus health
- Track order fill rates
- Monitor PnL and drawdown
- Set up alerts for unusual activity
- Log all errors and warnings

## Error Handling

### Connection Issues

```python
def on_start(self):
    try:
        self.subscribe_quote_ticks(self.instrument_id)
    except Exception as e:
        self.log.error(f"Subscription failed: {e}")
        # Retry logic
```

### Order Rejection

```python
def on_order_rejected(self, event):
    self.log.error(f"Order rejected: {event.reason}")
    
    # Handle based on rejection reason
    if "insufficient balance" in event.reason.lower():
        self.log.error("Insufficient balance - stopping strategy")
        self.stop()
    elif "invalid price" in event.reason.lower():
        # Retry with adjusted price
        pass
```

## Best Practices

1. **Start Small**: Begin with small position sizes
2. **Test Thoroughly**: Extensive backtesting and paper trading
3. **Monitor Actively**: Watch live performance closely initially
4. **Risk Management**: Always enforce position and order limits
5. **Graceful Shutdown**: Handle shutdown signals properly
6. **Secure Credentials**: Use environment variables, never hardcode
7. **Log Everything**: Comprehensive logging for debugging
8. **Backup State**: Regular backups of Redis data
9. **Stay Updated**: Monitor for API changes from venues
10. **Have a Kill Switch**: Manual way to stop and close all positions

## Next Steps

- **Review examples:** Read `examples.md`
- **Optimize strategies:** Read `best-practices.md`
- **Troubleshoot issues:** Read `troubleshooting.md`

## Additional Resources

- **Live Trading Docs:** https://nautilustrader.io/docs/latest/concepts/live/
- **Integration Guides:** https://nautilustrader.io/docs/latest/integrations/
- **Example Live Scripts:** https://github.com/nautechsystems/nautilus_trader/tree/develop/examples/live

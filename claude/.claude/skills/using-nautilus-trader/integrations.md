# Integrations Guide

## Supported Venues

NautilusTrader uses adapters to integrate with trading venues and data providers.

### Integration Status Levels

- **building**: Under construction, not usable
- **beta**: Minimally working, in beta testing
- **stable**: Stabilized, tested by developers and users

## Cryptocurrency Exchanges

### Binance (Stable)

**Supported:** Spot, USD-M Futures, COIN-M Futures

```python
from nautilus_trader.adapters.binance.config import (
    BinanceDataClientConfig,
    BinanceExecClientConfig,
)

data_config = BinanceDataClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    testnet=False,  # Use testnet for testing
    account_type="spot",  # or "usdt_future", "coin_future"
)

exec_config = BinanceExecClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    testnet=False,
    account_type="spot",
)
```

### Bybit (Stable)

```python
from nautilus_trader.adapters.bybit.config import (
    BybitDataClientConfig,
    BybitExecClientConfig,
)

data_config = BybitDataClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    is_testnet=False,
)
```

### Interactive Brokers (Beta)

```python
from nautilus_trader.adapters.interactive_brokers.config import (
    InteractiveBrokersDataClientConfig,
    InteractiveBrokersExecClientConfig,
)

data_config = InteractiveBrokersDataClientConfig(
    ib_host="127.0.0.1",
    ib_port=7497,  # TWS default port
    ib_client_id=1,
)
```

### Other Exchanges

- **OKX** (stable)
- **Kraken** (stable)
- **Coinbase** (beta)
- **Bitfinex** (beta)
- **Hyperliquid** (beta)
- **BitMEX** (beta)

See: https://nautilustrader.io/docs/latest/integrations/

## Data Providers

### Databento

High-quality market data for equities, futures, options.

```python
from nautilus_trader.adapters.databento.config import DatabentoDataClientConfig

data_config = DatabentoDataClientConfig(
    api_key="YOUR_API_KEY",
)
```

### Tardis

Historical cryptocurrency market data.

```python
from nautilus_trader.adapters.tardis.config import TardisDataClientConfig

data_config = TardisDataClientConfig(
    api_key="YOUR_API_KEY",
)
```

## Custom Adapters

### Creating Data Client Adapter

```python
from nautilus_trader.data.client import DataClient

class CustomDataClient(DataClient):
    def __init__(self, config):
        super().__init__(
            client_id=ClientId(config.client_id),
            venue=Venue(config.venue),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
        )
    
    async def _connect(self):
        # Connect to data source
        pass
    
    async def _disconnect(self):
        # Disconnect from data source
        pass
    
    async def _subscribe_quote_ticks(self, instrument_id):
        # Subscribe to quotes
        pass
```

### Creating Execution Client Adapter

```python
from nautilus_trader.execution.client import ExecutionClient

class CustomExecClient(ExecutionClient):
    def __init__(self, config):
        super().__init__(
            client_id=ClientId(config.client_id),
            venue=Venue(config.venue),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
        )
    
    async def _connect(self):
        # Connect to venue
        pass
    
    async def _submit_order(self, command):
        # Submit order to venue
        pass
    
    async def _cancel_order(self, command):
        # Cancel order at venue
        pass
```

## Additional Resources

- **Integrations Docs:** https://nautilustrader.io/docs/latest/integrations/
- **Adapter Examples:** https://github.com/nautechsystems/nautilus_trader/tree/develop/nautilus_trader/adapters
EOF
cat /mnt/skills/user/nautilus-trader/integrations.md
Output

# Integrations Guide

## Supported Venues

NautilusTrader uses adapters to integrate with trading venues and data providers.

### Integration Status Levels

- **building**: Under construction, not usable
- **beta**: Minimally working, in beta testing
- **stable**: Stabilized, tested by developers and users

## Cryptocurrency Exchanges

### Binance (Stable)

**Supported:** Spot, USD-M Futures, COIN-M Futures

```python
from nautilus_trader.adapters.binance.config import (
    BinanceDataClientConfig,
    BinanceExecClientConfig,
)

data_config = BinanceDataClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    testnet=False,  # Use testnet for testing
    account_type="spot",  # or "usdt_future", "coin_future"
)

exec_config = BinanceExecClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    testnet=False,
    account_type="spot",
)
```

### Bybit (Stable)

```python
from nautilus_trader.adapters.bybit.config import (
    BybitDataClientConfig,
    BybitExecClientConfig,
)

data_config = BybitDataClientConfig(
    api_key="YOUR_API_KEY",
    api_secret="YOUR_API_SECRET",
    is_testnet=False,
)
```

### Interactive Brokers (Beta)

```python
from nautilus_trader.adapters.interactive_brokers.config import (
    InteractiveBrokersDataClientConfig,
    InteractiveBrokersExecClientConfig,
)

data_config = InteractiveBrokersDataClientConfig(
    ib_host="127.0.0.1",
    ib_port=7497,  # TWS default port
    ib_client_id=1,
)
```

### Other Exchanges

- **OKX** (stable)
- **Kraken** (stable)
- **Coinbase** (beta)
- **Bitfinex** (beta)
- **Hyperliquid** (beta)
- **BitMEX** (beta)

See: https://nautilustrader.io/docs/latest/integrations/

## Data Providers

### Databento

High-quality market data for equities, futures, options.

```python
from nautilus_trader.adapters.databento.config import DatabentoDataClientConfig

data_config = DatabentoDataClientConfig(
    api_key="YOUR_API_KEY",
)
```

### Tardis

Historical cryptocurrency market data.

```python
from nautilus_trader.adapters.tardis.config import TardisDataClientConfig

data_config = TardisDataClientConfig(
    api_key="YOUR_API_KEY",
)
```

## Custom Adapters

### Creating Data Client Adapter

```python
from nautilus_trader.data.client import DataClient

class CustomDataClient(DataClient):
    def __init__(self, config):
        super().__init__(
            client_id=ClientId(config.client_id),
            venue=Venue(config.venue),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
        )
    
    async def _connect(self):
        # Connect to data source
        pass
    
    async def _disconnect(self):
        # Disconnect from data source
        pass
    
    async def _subscribe_quote_ticks(self, instrument_id):
        # Subscribe to quotes
        pass
```

### Creating Execution Client Adapter

```python
from nautilus_trader.execution.client import ExecutionClient

class CustomExecClient(ExecutionClient):
    def __init__(self, config):
        super().__init__(
            client_id=ClientId(config.client_id),
            venue=Venue(config.venue),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
        )
    
    async def _connect(self):
        # Connect to venue
        pass
    
    async def _submit_order(self, command):
        # Submit order to venue
        pass
    
    async def _cancel_order(self, command):
        # Cancel order at venue
        pass
```

## Additional Resources

- **Integrations Docs:** https://nautilustrader.io/docs/latest/integrations/
- **Adapter Examples:** https://github.com/nautechsystems/nautilus_trader/tree/develop/nautilus_trader/adapters

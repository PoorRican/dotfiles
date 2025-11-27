# Adapters Guide

## Overview

Adapters are venue-specific integrations that connect NautilusTrader to exchanges and data providers. Each adapter consists of data clients, execution clients, and instrument providers.

## Adapter Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Adapter                              │
├─────────────────────────────────────────────────────────┤
│  InstrumentProvider  │  DataClient  │  ExecutionClient  │
│  ─────────────────── │  ─────────── │  ──────────────── │
│  • Load instruments  │  • Market data│  • Order submission│
│  • Instrument specs  │  • WebSocket  │  • Order management│
│                      │  • REST API   │  • Position sync   │
└─────────────────────────────────────────────────────────┘
```

## Adapter Components

### 1. InstrumentProvider

Loads and provides instrument definitions from the venue.

```python
from nautilus_trader.adapters.binance.providers import BinanceInstrumentProvider

provider = BinanceInstrumentProvider(
    client=http_client,
    clock=clock,
    account_type=BinanceAccountType.SPOT,
)

# Load all instruments
await provider.load_all_async()

# Get specific instrument
instrument = provider.find(InstrumentId.from_str("BTCUSDT.BINANCE"))

# Get all instruments
instruments = provider.list_all()
```

### 2. DataClient

Handles market data subscriptions and historical data requests.

```python
from nautilus_trader.adapters.binance.data import BinanceDataClient

# Data client handles:
# - Quote tick subscriptions
# - Trade tick subscriptions
# - Bar subscriptions
# - Order book subscriptions
# - Historical data requests
```

### 3. ExecutionClient

Handles order submission, modification, and cancellation.

```python
from nautilus_trader.adapters.binance.execution import BinanceExecutionClient

# Execution client handles:
# - Order submission
# - Order modification
# - Order cancellation
# - Position reconciliation
# - Account state sync
```

## Creating Custom Adapters

### Custom Data Client

```python
from nautilus_trader.live.data_client import LiveMarketDataClient
from nautilus_trader.model.identifiers import ClientId, Venue

class CustomDataClient(LiveMarketDataClient):
    """
    Custom data client for MyExchange.
    """

    def __init__(
        self,
        loop: asyncio.AbstractEventLoop,
        client: HttpClient,
        msgbus: MessageBus,
        cache: Cache,
        clock: LiveClock,
        instrument_provider: InstrumentProvider,
        config: CustomDataClientConfig,
    ):
        super().__init__(
            loop=loop,
            client_id=ClientId("MY_EXCHANGE"),
            venue=Venue("MY_EXCHANGE"),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            instrument_provider=instrument_provider,
        )
        self._client = client
        self._ws = None

    async def _connect(self) -> None:
        """Connect to the exchange."""
        self._ws = await self._create_websocket()
        self._log.info("Connected to MyExchange")

    async def _disconnect(self) -> None:
        """Disconnect from the exchange."""
        if self._ws:
            await self._ws.close()
        self._log.info("Disconnected from MyExchange")

    async def _subscribe_quote_ticks(self, instrument_id: InstrumentId) -> None:
        """Subscribe to quote tick data."""
        symbol = instrument_id.symbol.value
        await self._ws.send(json.dumps({
            "method": "SUBSCRIBE",
            "params": [f"{symbol.lower()}@bookTicker"],
        }))

    async def _subscribe_trade_ticks(self, instrument_id: InstrumentId) -> None:
        """Subscribe to trade tick data."""
        symbol = instrument_id.symbol.value
        await self._ws.send(json.dumps({
            "method": "SUBSCRIBE",
            "params": [f"{symbol.lower()}@trade"],
        }))

    async def _subscribe_bars(self, bar_type: BarType) -> None:
        """Subscribe to bar data."""
        symbol = bar_type.instrument_id.symbol.value
        interval = self._map_bar_spec(bar_type.spec)
        await self._ws.send(json.dumps({
            "method": "SUBSCRIBE",
            "params": [f"{symbol.lower()}@kline_{interval}"],
        }))

    def _handle_quote_msg(self, raw: bytes) -> None:
        """Parse and publish quote tick."""
        data = json.loads(raw)

        tick = QuoteTick(
            instrument_id=InstrumentId.from_str(f"{data['s']}.MY_EXCHANGE"),
            bid_price=Price.from_str(data['b']),
            ask_price=Price.from_str(data['a']),
            bid_size=Quantity.from_str(data['B']),
            ask_size=Quantity.from_str(data['A']),
            ts_event=millis_to_nanos(data['E']),
            ts_init=self._clock.timestamp_ns(),
        )

        self._handle_data(tick)
```

### Custom Execution Client

```python
from nautilus_trader.live.execution_client import LiveExecutionClient

class CustomExecutionClient(LiveExecutionClient):
    """
    Custom execution client for MyExchange.
    """

    def __init__(
        self,
        loop: asyncio.AbstractEventLoop,
        client: HttpClient,
        msgbus: MessageBus,
        cache: Cache,
        clock: LiveClock,
        instrument_provider: InstrumentProvider,
        config: CustomExecClientConfig,
    ):
        super().__init__(
            loop=loop,
            client_id=ClientId("MY_EXCHANGE"),
            venue=Venue("MY_EXCHANGE"),
            oms_type=OmsType.NETTING,
            account_type=AccountType.CASH,
            base_currency=Currency.from_str("USDT"),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            instrument_provider=instrument_provider,
        )
        self._client = client

    async def _connect(self) -> None:
        """Connect to the exchange."""
        await self._authenticate()
        await self._sync_account_state()
        self._log.info("Connected to MyExchange execution")

    async def _disconnect(self) -> None:
        """Disconnect from the exchange."""
        self._log.info("Disconnected from MyExchange execution")

    async def _submit_order(self, command: SubmitOrder) -> None:
        """Submit order to exchange."""
        order = command.order

        # Map order to exchange format
        params = {
            "symbol": order.instrument_id.symbol.value,
            "side": "BUY" if order.side == OrderSide.BUY else "SELL",
            "type": self._map_order_type(order),
            "quantity": str(order.quantity),
        }

        if isinstance(order, LimitOrder):
            params["price"] = str(order.price)
            params["timeInForce"] = self._map_tif(order.time_in_force)

        # Submit to exchange
        response = await self._client.post("/api/v3/order", params=params)

        # Generate accepted event
        self.generate_order_accepted(
            strategy_id=order.strategy_id,
            instrument_id=order.instrument_id,
            client_order_id=order.client_order_id,
            venue_order_id=VenueOrderId(str(response["orderId"])),
            ts_event=self._clock.timestamp_ns(),
        )

    async def _cancel_order(self, command: CancelOrder) -> None:
        """Cancel order at exchange."""
        await self._client.delete("/api/v3/order", params={
            "symbol": command.instrument_id.symbol.value,
            "orderId": command.venue_order_id.value,
        })

        self.generate_order_canceled(
            strategy_id=command.strategy_id,
            instrument_id=command.instrument_id,
            client_order_id=command.client_order_id,
            venue_order_id=command.venue_order_id,
            ts_event=self._clock.timestamp_ns(),
        )

    async def _modify_order(self, command: ModifyOrder) -> None:
        """Modify order at exchange."""
        # Many exchanges require cancel + new order
        await self._cancel_order(CancelOrder(...))
        await self._submit_order(SubmitOrder(...))
```

### Custom Instrument Provider

```python
from nautilus_trader.common.providers import InstrumentProvider

class CustomInstrumentProvider(InstrumentProvider):
    """
    Custom instrument provider for MyExchange.
    """

    def __init__(
        self,
        client: HttpClient,
        clock: Clock,
    ):
        super().__init__()
        self._client = client
        self._clock = clock

    async def load_all_async(self) -> None:
        """Load all instruments from exchange."""
        response = await self._client.get("/api/v3/exchangeInfo")

        for symbol_info in response["symbols"]:
            instrument = self._parse_instrument(symbol_info)
            self.add(instrument)

    def _parse_instrument(self, data: dict) -> CurrencyPair:
        """Parse exchange data into instrument."""
        filters = {f["filterType"]: f for f in data["filters"]}

        return CurrencyPair(
            instrument_id=InstrumentId(
                symbol=Symbol(data["symbol"]),
                venue=Venue("MY_EXCHANGE"),
            ),
            native_symbol=Symbol(data["symbol"]),
            base_currency=Currency.from_str(data["baseAsset"]),
            quote_currency=Currency.from_str(data["quoteAsset"]),
            price_precision=data["quotePrecision"],
            size_precision=data["baseAssetPrecision"],
            price_increment=Price.from_str(filters["PRICE_FILTER"]["tickSize"]),
            size_increment=Quantity.from_str(filters["LOT_SIZE"]["stepSize"]),
            min_quantity=Quantity.from_str(filters["LOT_SIZE"]["minQty"]),
            max_quantity=Quantity.from_str(filters["LOT_SIZE"]["maxQty"]),
            ts_event=self._clock.timestamp_ns(),
            ts_init=self._clock.timestamp_ns(),
        )
```

## Configuration Classes

### Data Client Config

```python
from nautilus_trader.config import LiveDataClientConfig

class CustomDataClientConfig(LiveDataClientConfig):
    """Configuration for CustomDataClient."""

    api_key: str
    api_secret: str
    base_url: str = "https://api.myexchange.com"
    ws_url: str = "wss://stream.myexchange.com"
    testnet: bool = False
```

### Execution Client Config

```python
from nautilus_trader.config import LiveExecClientConfig

class CustomExecClientConfig(LiveExecClientConfig):
    """Configuration for CustomExecutionClient."""

    api_key: str
    api_secret: str
    base_url: str = "https://api.myexchange.com"
    testnet: bool = False
    max_retries: int = 3
```

## Client Factory

Create a factory to instantiate clients.

```python
from nautilus_trader.live.factories import LiveDataClientFactory, LiveExecClientFactory

class CustomLiveDataClientFactory(LiveDataClientFactory):
    """Factory for CustomDataClient."""

    @staticmethod
    def create(
        loop: asyncio.AbstractEventLoop,
        name: str,
        config: CustomDataClientConfig,
        msgbus: MessageBus,
        cache: Cache,
        clock: LiveClock,
    ) -> CustomDataClient:
        # Create HTTP client
        client = HttpClient(
            base_url=config.base_url,
            api_key=config.api_key,
            api_secret=config.api_secret,
        )

        # Create instrument provider
        provider = CustomInstrumentProvider(client=client, clock=clock)

        return CustomDataClient(
            loop=loop,
            client=client,
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            instrument_provider=provider,
            config=config,
        )


class CustomLiveExecClientFactory(LiveExecClientFactory):
    """Factory for CustomExecutionClient."""

    @staticmethod
    def create(
        loop: asyncio.AbstractEventLoop,
        name: str,
        config: CustomExecClientConfig,
        msgbus: MessageBus,
        cache: Cache,
        clock: LiveClock,
    ) -> CustomExecutionClient:
        # Similar to data client factory
        pass
```

## Registering Custom Adapters

```python
from nautilus_trader.live.node import TradingNode

# Register factories
TradingNode.add_data_client_factory("MY_EXCHANGE", CustomLiveDataClientFactory)
TradingNode.add_exec_client_factory("MY_EXCHANGE", CustomLiveExecClientFactory)

# Configure node
config = TradingNodeConfig(
    trader_id="TRADER-001",
    data_clients={
        "MY_EXCHANGE": CustomDataClientConfig(
            api_key="...",
            api_secret="...",
        ),
    },
    exec_clients={
        "MY_EXCHANGE": CustomExecClientConfig(
            api_key="...",
            api_secret="...",
        ),
    },
)

node = TradingNode(config=config)
node.run()
```

## Backtest Adapter

For backtesting, create simulated data/execution clients.

```python
from nautilus_trader.backtest.data_client import BacktestMarketDataClient
from nautilus_trader.backtest.execution_client import BacktestExecClient

# These are used automatically by BacktestEngine
# You typically don't need to create them manually
```

## Next Steps

- **See integrations:** Read `integrations.md`
- **Live trading:** Read `live-trading.md`
- **Architecture:** Read `architecture.md`

## Additional Resources

- **Adapter Docs:** https://nautilustrader.io/docs/latest/concepts/adapters/
- **Built-in Adapters:** https://github.com/nautechsystems/nautilus_trader/tree/develop/nautilus_trader/adapters

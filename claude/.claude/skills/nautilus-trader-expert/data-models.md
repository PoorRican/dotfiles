# Data Models Reference

## Core Data Types

**Location:** `nautilus_trader.model.data`

### QuoteTick

Represents bid/ask quote updates.

```python
from nautilus_trader.model.data import QuoteTick

# Access quote data
bid_price = tick.bid_price
ask_price = tick.ask_price
bid_size = tick.bid_size
ask_size = tick.ask_size
instrument_id = tick.instrument_id
ts_event = tick.ts_event  # Event timestamp (nanoseconds)
ts_init = tick.ts_init    # System timestamp
```

### TradeTick

Represents executed trades.

```python
from nautilus_trader.model.data import TradeTick

# Access trade data
price = tick.price
size = tick.size
aggressor_side = tick.aggressor_side  # BUY or SELL
trade_id = tick.trade_id
```

### Bar

OHLCV bar data.

```python
from nautilus_trader.model.data import Bar, BarType

# Access bar data
open_price = bar.open
high = bar.high
low = bar.low
close = bar.close
volume = bar.volume
bar_type = bar.bar_type

# Parse bar type
bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
```

### OrderBookDelta

Incremental order book updates.

```python
from nautilus_trader.model.data import OrderBookDelta

# Access delta data
action = delta.action  # ADD, UPDATE, DELETE, CLEAR
order = delta.order    # BookOrder
```

### OrderBookDepth10

Top 10 levels of order book.

```python
from nautilus_trader.model.data import OrderBookDepth10

# Access depth data
bids = depth.bids  # List of (price, size) tuples
asks = depth.asks
```

## Identifiers

**Location:** `nautilus_trader.model.identifiers`

### InstrumentId

```python
from nautilus_trader.model.identifiers import InstrumentId, Symbol, Venue

# Create from string
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")

# Create from components
symbol = Symbol("BTCUSDT")
venue = Venue("BINANCE")
instrument_id = InstrumentId(symbol=symbol, venue=venue)

# Access components
symbol = instrument_id.symbol
venue = instrument_id.venue
```

### Other Identifiers

```python
from nautilus_trader.model.identifiers import (
    TraderId,
    StrategyId,
    AccountId,
    ClientOrderId,
    VenueOrderId,
    PositionId,
)

trader_id = TraderId("TRADER-001")
strategy_id = StrategyId("MyStrategy-001")
account_id = AccountId("BINANCE-001")
```

## Order Types

**Location:** `nautilus_trader.model.orders`

### MarketOrder

```python
from nautilus_trader.model.orders import MarketOrder
from nautilus_trader.model.enums import OrderSide
from nautilus_trader.model.objects import Quantity

order = MarketOrder(
    trader_id=trader_id,
    strategy_id=strategy_id,
    instrument_id=instrument_id,
    client_order_id=client_order_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    init_id=uuid4(),
    ts_init=clock.timestamp_ns(),
)
```

### LimitOrder

```python
from nautilus_trader.model.orders import LimitOrder
from nautilus_trader.model.objects import Price

order = LimitOrder(
    # ... common parameters
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.0"),
    time_in_force=TimeInForce.GTC,
)
```

### StopMarketOrder

```python
from nautilus_trader.model.orders import StopMarketOrder

order = StopMarketOrder(
    # ... common parameters
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.0"),
    trigger_type=TriggerType.LAST_PRICE,
)
```

### Order Enums

```python
from nautilus_trader.model.enums import (
    OrderSide,          # BUY, SELL
    OrderType,          # MARKET, LIMIT, STOP_MARKET, etc.
    TimeInForce,        # GTC, IOC, FOK, DAY, etc.
    OrderStatus,        # INITIALIZED, SUBMITTED, ACCEPTED, etc.
    TriggerType,        # DEFAULT, LAST_PRICE, BID_ASK, etc.
)
```

## Instrument Types

**Location:** `nautilus_trader.model.instruments`

### CurrencyPair (Spot)

```python
from nautilus_trader.model.instruments import CurrencyPair
from nautilus_trader.model.objects import Currency

instrument = CurrencyPair(
    instrument_id=instrument_id,
    native_symbol=Symbol("BTCUSDT"),
    base_currency=Currency.from_str("BTC"),
    quote_currency=Currency.from_str("USDT"),
    price_precision=2,
    size_precision=8,
    price_increment=Price.from_str("0.01"),
    size_increment=Quantity.from_str("0.00000001"),
    ts_event=0,
    ts_init=0,
)
```

### CryptoPerpetual

```python
from nautilus_trader.model.instruments import CryptoPerpetual

instrument = CryptoPerpetual(
    instrument_id=instrument_id,
    # ... similar to CurrencyPair
    max_quantity=Quantity.from_str("10000"),
    min_quantity=Quantity.from_str("0.001"),
)
```

### SyntheticInstrument

```python
from nautilus_trader.model.instruments import SyntheticInstrument

# Create BTC-ETH spread
synthetic = SyntheticInstrument(
    symbol=Symbol("BTC-ETH:BINANCE"),
    price_precision=8,
    components=[
        InstrumentId.from_str("BTCUSDT.BINANCE"),
        InstrumentId.from_str("ETHUSDT.BINANCE"),
    ],
    formula="BTCUSDT.BINANCE - ETHUSDT.BINANCE",
    ts_event=0,
    ts_init=0,
)
```

## Value Objects

**Location:** `nautilus_trader.model.objects`

### Price, Quantity, Money

```python
from nautilus_trader.model.objects import Price, Quantity, Money, Currency

# Create from string
price = Price.from_str("50000.50")
quantity = Quantity.from_str("1.5")
money = Money(10000, Currency.from_str("USDT"))

# Convert to native types
price_float = float(price)
quantity_float = float(quantity)
amount = float(money)

# Arithmetic operations
total = price * quantity  # Returns Money
```

## Events

**Location:** `nautilus_trader.model.events`

### Order Events

```python
from nautilus_trader.model.events import (
    OrderInitialized,
    OrderSubmitted,
    OrderAccepted,
    OrderRejected,
    OrderCancelled,
    OrderExpired,
    OrderTriggered,
    OrderFilled,
    OrderUpdated,
)

def on_order_filled(self, event: OrderFilled):
    order_id = event.client_order_id
    fill_price = event.last_px
    fill_qty = event.last_qty
    commission = event.commission
```

### Position Events

```python
from nautilus_trader.model.events import (
    PositionOpened,
    PositionChanged,
    PositionClosed,
)

def on_position_opened(self, event: PositionOpened):
    position_id = event.position_id
    entry_price = event.entry
```

### Account Events

```python
from nautilus_trader.model.events import AccountState

def on_account_state(self, event: AccountState):
    account_id = event.account_id
    balances = event.balances
    margins = event.margins
```

## ParquetDataCatalog

**Location:** `nautilus_trader.persistence.catalog`

### Writing Data

```python
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog("./catalog")

# Write bars
catalog.write_data(bars)

# Write quote ticks
catalog.write_data(quote_ticks)

# Write custom data
catalog.write_data(custom_data)
```

### Querying Data

```python
# Query bars
bars = catalog.bars(
    instrument_ids=["BTCUSDT.BINANCE"],
    bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
    start="2024-01-01",
    end="2024-12-31",
)

# Query quote ticks
quotes = catalog.quote_ticks(
    instrument_ids=["BTCUSDT.BINANCE"],
    start="2024-01-01",
    end="2024-01-31",
)

# Query instruments
instruments = catalog.instruments(
    instrument_ids=["BTCUSDT.BINANCE"],
)
```

## Custom Data

### Define Custom Data Type

```python
from nautilus_trader.model.data import Data

class CustomSignal(Data):
    def __init__(
        self,
        value: float,
        ts_event: int,
        ts_init: int,
    ):
        super().__init__()
        self.value = value
        self.ts_event = ts_event
        self.ts_init = ts_init
```

### Publish Custom Data

```python
# In strategy or actor
signal = CustomSignal(
    value=0.75,
    ts_event=self.clock.timestamp_ns(),
    ts_init=self.clock.timestamp_ns(),
)

self.publish_data(
    data_type=DataType(CustomSignal),
    data=signal,
)
```

## Additional Resources

- **Data Docs:** https://nautilustrader.io/docs/latest/concepts/data/
- **Model API Reference:** https://nautilustrader.io/docs/latest/api_reference/model/
- **Instruments Guide:** https://nautilustrader.io/docs/latest/concepts/instruments/
EOF
cat /mnt/skills/user/nautilus-trader/data-models.md
Output

# Data Models Reference

## Core Data Types

**Location:** `nautilus_trader.model.data`

### QuoteTick

Represents bid/ask quote updates.

```python
from nautilus_trader.model.data import QuoteTick

# Access quote data
bid_price = tick.bid_price
ask_price = tick.ask_price
bid_size = tick.bid_size
ask_size = tick.ask_size
instrument_id = tick.instrument_id
ts_event = tick.ts_event  # Event timestamp (nanoseconds)
ts_init = tick.ts_init    # System timestamp
```

### TradeTick

Represents executed trades.

```python
from nautilus_trader.model.data import TradeTick

# Access trade data
price = tick.price
size = tick.size
aggressor_side = tick.aggressor_side  # BUY or SELL
trade_id = tick.trade_id
```

### Bar

OHLCV bar data.

```python
from nautilus_trader.model.data import Bar, BarType

# Access bar data
open_price = bar.open
high = bar.high
low = bar.low
close = bar.close
volume = bar.volume
bar_type = bar.bar_type

# Parse bar type
bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
```

### OrderBookDelta

Incremental order book updates.

```python
from nautilus_trader.model.data import OrderBookDelta

# Access delta data
action = delta.action  # ADD, UPDATE, DELETE, CLEAR
order = delta.order    # BookOrder
```

### OrderBookDepth10

Top 10 levels of order book.

```python
from nautilus_trader.model.data import OrderBookDepth10

# Access depth data
bids = depth.bids  # List of (price, size) tuples
asks = depth.asks
```

## Identifiers

**Location:** `nautilus_trader.model.identifiers`

### InstrumentId

```python
from nautilus_trader.model.identifiers import InstrumentId, Symbol, Venue

# Create from string
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")

# Create from components
symbol = Symbol("BTCUSDT")
venue = Venue("BINANCE")
instrument_id = InstrumentId(symbol=symbol, venue=venue)

# Access components
symbol = instrument_id.symbol
venue = instrument_id.venue
```

### Other Identifiers

```python
from nautilus_trader.model.identifiers import (
    TraderId,
    StrategyId,
    AccountId,
    ClientOrderId,
    VenueOrderId,
    PositionId,
)

trader_id = TraderId("TRADER-001")
strategy_id = StrategyId("MyStrategy-001")
account_id = AccountId("BINANCE-001")
```

## Order Types

**Location:** `nautilus_trader.model.orders`

### MarketOrder

```python
from nautilus_trader.model.orders import MarketOrder
from nautilus_trader.model.enums import OrderSide
from nautilus_trader.model.objects import Quantity

order = MarketOrder(
    trader_id=trader_id,
    strategy_id=strategy_id,
    instrument_id=instrument_id,
    client_order_id=client_order_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    init_id=uuid4(),
    ts_init=clock.timestamp_ns(),
)
```

### LimitOrder

```python
from nautilus_trader.model.orders import LimitOrder
from nautilus_trader.model.objects import Price

order = LimitOrder(
    # ... common parameters
    order_side=OrderSide.BUY,
    quantity=Quantity.from_str("1.0"),
    price=Price.from_str("50000.0"),
    time_in_force=TimeInForce.GTC,
)
```

### StopMarketOrder

```python
from nautilus_trader.model.orders import StopMarketOrder

order = StopMarketOrder(
    # ... common parameters
    order_side=OrderSide.SELL,
    quantity=Quantity.from_str("1.0"),
    trigger_price=Price.from_str("49000.0"),
    trigger_type=TriggerType.LAST_PRICE,
)
```

### Order Enums

```python
from nautilus_trader.model.enums import (
    OrderSide,          # BUY, SELL
    OrderType,          # MARKET, LIMIT, STOP_MARKET, etc.
    TimeInForce,        # GTC, IOC, FOK, DAY, etc.
    OrderStatus,        # INITIALIZED, SUBMITTED, ACCEPTED, etc.
    TriggerType,        # DEFAULT, LAST_PRICE, BID_ASK, etc.
)
```

## Instrument Types

**Location:** `nautilus_trader.model.instruments`

### CurrencyPair (Spot)

```python
from nautilus_trader.model.instruments import CurrencyPair
from nautilus_trader.model.objects import Currency

instrument = CurrencyPair(
    instrument_id=instrument_id,
    native_symbol=Symbol("BTCUSDT"),
    base_currency=Currency.from_str("BTC"),
    quote_currency=Currency.from_str("USDT"),
    price_precision=2,
    size_precision=8,
    price_increment=Price.from_str("0.01"),
    size_increment=Quantity.from_str("0.00000001"),
    ts_event=0,
    ts_init=0,
)
```

### CryptoPerpetual

```python
from nautilus_trader.model.instruments import CryptoPerpetual

instrument = CryptoPerpetual(
    instrument_id=instrument_id,
    # ... similar to CurrencyPair
    max_quantity=Quantity.from_str("10000"),
    min_quantity=Quantity.from_str("0.001"),
)
```

### SyntheticInstrument

```python
from nautilus_trader.model.instruments import SyntheticInstrument

# Create BTC-ETH spread
synthetic = SyntheticInstrument(
    symbol=Symbol("BTC-ETH:BINANCE"),
    price_precision=8,
    components=[
        InstrumentId.from_str("BTCUSDT.BINANCE"),
        InstrumentId.from_str("ETHUSDT.BINANCE"),
    ],
    formula="BTCUSDT.BINANCE - ETHUSDT.BINANCE",
    ts_event=0,
    ts_init=0,
)
```

## Value Objects

**Location:** `nautilus_trader.model.objects`

### Price, Quantity, Money

```python
from nautilus_trader.model.objects import Price, Quantity, Money, Currency

# Create from string
price = Price.from_str("50000.50")
quantity = Quantity.from_str("1.5")
money = Money(10000, Currency.from_str("USDT"))

# Convert to native types
price_float = float(price)
quantity_float = float(quantity)
amount = float(money)

# Arithmetic operations
total = price * quantity  # Returns Money
```

## Events

**Location:** `nautilus_trader.model.events`

### Order Events

```python
from nautilus_trader.model.events import (
    OrderInitialized,
    OrderSubmitted,
    OrderAccepted,
    OrderRejected,
    OrderCancelled,
    OrderExpired,
    OrderTriggered,
    OrderFilled,
    OrderUpdated,
)

def on_order_filled(self, event: OrderFilled):
    order_id = event.client_order_id
    fill_price = event.last_px
    fill_qty = event.last_qty
    commission = event.commission
```

### Position Events

```python
from nautilus_trader.model.events import (
    PositionOpened,
    PositionChanged,
    PositionClosed,
)

def on_position_opened(self, event: PositionOpened):
    position_id = event.position_id
    entry_price = event.entry
```

### Account Events

```python
from nautilus_trader.model.events import AccountState

def on_account_state(self, event: AccountState):
    account_id = event.account_id
    balances = event.balances
    margins = event.margins
```

## ParquetDataCatalog

**Location:** `nautilus_trader.persistence.catalog`

### Writing Data

```python
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog("./catalog")

# Write bars
catalog.write_data(bars)

# Write quote ticks
catalog.write_data(quote_ticks)

# Write custom data
catalog.write_data(custom_data)
```

### Querying Data

```python
# Query bars
bars = catalog.bars(
    instrument_ids=["BTCUSDT.BINANCE"],
    bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
    start="2024-01-01",
    end="2024-12-31",
)

# Query quote ticks
quotes = catalog.quote_ticks(
    instrument_ids=["BTCUSDT.BINANCE"],
    start="2024-01-01",
    end="2024-01-31",
)

# Query instruments
instruments = catalog.instruments(
    instrument_ids=["BTCUSDT.BINANCE"],
)
```

## Custom Data

### Define Custom Data Type

```python
from nautilus_trader.model.data import Data

class CustomSignal(Data):
    def __init__(
        self,
        value: float,
        ts_event: int,
        ts_init: int,
    ):
        super().__init__()
        self.value = value
        self.ts_event = ts_event
        self.ts_init = ts_init
```

### Publish Custom Data

```python
# In strategy or actor
signal = CustomSignal(
    value=0.75,
    ts_event=self.clock.timestamp_ns(),
    ts_init=self.clock.timestamp_ns(),
)

self.publish_data(
    data_type=DataType(CustomSignal),
    data=signal,
)
```

## Additional Resources

- **Data Docs:** https://nautilustrader.io/docs/latest/concepts/data/
- **Model API Reference:** https://nautilustrader.io/docs/latest/api_reference/model/
- **Instruments Guide:** https://nautilustrader.io/docs/latest/concepts/instruments/

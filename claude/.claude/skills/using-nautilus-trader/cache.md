# Cache System Guide

## Overview

The Cache is a high-performance, centralized storage system that provides fast access to all system state: instruments, market data, orders, positions, and accounts.

**Location:** `nautilus_trader.cache.cache`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        Cache                             │
├─────────────────────────────────────────────────────────┤
│  Instruments    │  Market Data    │  Trading State      │
│  ─────────────  │  ────────────   │  ─────────────      │
│  • Definitions  │  • Quote Ticks  │  • Orders           │
│  • Status       │  • Trade Ticks  │  • Positions        │
│                 │  • Bars         │  • Accounts         │
│                 │  • Order Books  │  • Strategy State   │
└─────────────────────────────────────────────────────────┘
         ↑                ↑                    ↑
         │                │                    │
    DataEngine      DataEngine         ExecutionEngine
```

## Accessing the Cache

From strategies and actors:

```python
class MyStrategy(Strategy):

    def on_bar(self, bar: Bar):
        # Cache is accessed via self.cache
        instrument = self.cache.instrument(self.instrument_id)
        quote = self.cache.quote_tick(self.instrument_id)
```

## Instrument Queries

### Get Single Instrument

```python
from nautilus_trader.model.identifiers import InstrumentId

# Get by InstrumentId
instrument_id = InstrumentId.from_str("BTCUSDT.BINANCE")
instrument = self.cache.instrument(instrument_id)

if instrument:
    # Access instrument properties
    symbol = instrument.symbol
    venue = instrument.venue
    price_precision = instrument.price_precision
    size_precision = instrument.size_precision
    price_increment = instrument.price_increment
    size_increment = instrument.size_increment
    min_quantity = instrument.min_quantity
    max_quantity = instrument.max_quantity
```

### Get Multiple Instruments

```python
from nautilus_trader.model.identifiers import Venue

# Get all instruments
all_instruments = self.cache.instruments()

# Get instruments for specific venue
venue = Venue("BINANCE")
binance_instruments = self.cache.instruments(venue=venue)

# Get instrument IDs only
instrument_ids = self.cache.instrument_ids()
instrument_ids_for_venue = self.cache.instrument_ids(venue=venue)
```

### Instrument Status

```python
# Get instrument status
status = self.cache.instrument_status(instrument_id)
# Status: OPEN, CLOSED, PRE_TRADING, POST_TRADING, etc.
```

## Market Data Queries

### Quote Ticks (Bid/Ask)

```python
# Get latest quote tick
quote = self.cache.quote_tick(instrument_id)

if quote:
    bid = quote.bid_price
    ask = quote.ask_price
    bid_size = quote.bid_size
    ask_size = quote.ask_size
    spread = float(ask - bid)
    mid_price = (float(bid) + float(ask)) / 2

# Get quote tick count
count = self.cache.quote_tick_count(instrument_id)

# Check if quotes exist
has_quotes = self.cache.has_quote_ticks(instrument_id)
```

### Trade Ticks

```python
# Get latest trade tick
trade = self.cache.trade_tick(instrument_id)

if trade:
    price = trade.price
    size = trade.size
    aggressor = trade.aggressor_side  # BUY or SELL
    trade_id = trade.trade_id

# Get trade tick count
count = self.cache.trade_tick_count(instrument_id)

# Check if trades exist
has_trades = self.cache.has_trade_ticks(instrument_id)
```

### Bars (OHLCV)

```python
from nautilus_trader.model.data import BarType

# Get latest bar
bar_type = BarType.from_str("BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL")
bar = self.cache.bar(bar_type)

if bar:
    open_price = bar.open
    high = bar.high
    low = bar.low
    close = bar.close
    volume = bar.volume
    ts_event = bar.ts_event

# Get bar count
count = self.cache.bar_count(bar_type)

# Check if bars exist
has_bars = self.cache.has_bars(bar_type)
```

### Order Book

```python
# Get order book
book = self.cache.order_book(instrument_id)

if book:
    # Best prices
    best_bid = book.best_bid_price()
    best_ask = book.best_ask_price()
    spread = book.spread()

    # Best quantities
    bid_size = book.best_bid_size()
    ask_size = book.best_ask_size()

    # Multiple levels
    bids = book.bids()  # List of (price, size)
    asks = book.asks()

    # Book depth
    bid_depth = book.bid_depth()
    ask_depth = book.ask_depth()

    # Midpoint
    midpoint = book.midpoint()

    # Book imbalance
    imbalance = book.imbalance()  # Bid vs ask volume ratio
```

## Order Queries

### Get Orders by ID

```python
from nautilus_trader.model.identifiers import ClientOrderId, VenueOrderId

# Get by client order ID
client_order_id = ClientOrderId("O-20240101-001")
order = self.cache.order(client_order_id)

# Get by venue order ID
venue_order_id = VenueOrderId("12345678")
order = self.cache.order(venue_order_id=venue_order_id)
```

### Get Orders by State

```python
# All orders
all_orders = self.cache.orders()

# Open orders (working at venue)
open_orders = self.cache.orders_open()

# Closed orders (filled, cancelled, expired)
closed_orders = self.cache.orders_closed()

# Emulated orders (client-side)
emulated_orders = self.cache.orders_emulated()

# Inflight orders (submitted but not yet acknowledged)
inflight_orders = self.cache.orders_inflight()
```

### Filter Orders

```python
from nautilus_trader.model.identifiers import Venue, StrategyId

# Filter by venue
binance_orders = self.cache.orders_open(venue=Venue("BINANCE"))

# Filter by instrument
btc_orders = self.cache.orders_open(instrument_id=instrument_id)

# Filter by strategy
strategy_orders = self.cache.orders_open(strategy_id=StrategyId("MyStrategy-001"))

# Filter by side
from nautilus_trader.model.enums import OrderSide
buy_orders = self.cache.orders_open(side=OrderSide.BUY)

# Combine filters
filtered = self.cache.orders_open(
    venue=Venue("BINANCE"),
    instrument_id=instrument_id,
    side=OrderSide.BUY,
)
```

### Order Existence Checks

```python
# Check if order exists
exists = self.cache.order_exists(client_order_id)

# Check order counts
total = self.cache.orders_total_count()
open_count = self.cache.orders_open_count()
closed_count = self.cache.orders_closed_count()
emulated_count = self.cache.orders_emulated_count()
inflight_count = self.cache.orders_inflight_count()

# Counts with filters
open_for_instrument = self.cache.orders_open_count(instrument_id=instrument_id)
```

### Order IDs

```python
# Get order IDs
all_ids = self.cache.client_order_ids()
open_ids = self.cache.client_order_ids_open()
closed_ids = self.cache.client_order_ids_closed()

# With filters
venue_ids = self.cache.client_order_ids_open(venue=Venue("BINANCE"))
```

## Position Queries

### Get Positions

```python
from nautilus_trader.model.identifiers import PositionId

# Get by position ID
position_id = PositionId("BTCUSDT.BINANCE-001")
position = self.cache.position(position_id)

# Get all positions
all_positions = self.cache.positions()

# Get open positions
open_positions = self.cache.positions_open()

# Get closed positions
closed_positions = self.cache.positions_closed()
```

### Filter Positions

```python
# Filter by venue
binance_positions = self.cache.positions_open(venue=Venue("BINANCE"))

# Filter by instrument
btc_positions = self.cache.positions_open(instrument_id=instrument_id)

# Filter by strategy
strategy_positions = self.cache.positions_open(strategy_id=StrategyId("MyStrategy-001"))

# Filter by side
from nautilus_trader.model.enums import PositionSide
long_positions = self.cache.positions_open(side=PositionSide.LONG)
short_positions = self.cache.positions_open(side=PositionSide.SHORT)
```

### Position Details

```python
if position:
    # Basic info
    instrument_id = position.instrument_id
    side = position.side  # LONG, SHORT, FLAT
    quantity = position.quantity
    signed_qty = position.signed_qty  # Positive for long, negative for short

    # Entry info
    entry_price = position.avg_px_open
    entry_time = position.opened_time

    # PnL
    realized_pnl = position.realized_pnl
    unrealized_pnl = position.unrealized_pnl(last_price)
    total_pnl = position.total_pnl(last_price)

    # Statistics
    commission = position.commissions()
    duration = position.duration_ns
```

### Position Counts

```python
total = self.cache.positions_total_count()
open_count = self.cache.positions_open_count()
closed_count = self.cache.positions_closed_count()

# With filters
open_for_instrument = self.cache.positions_open_count(instrument_id=instrument_id)
```

## Account Queries

```python
from nautilus_trader.model.identifiers import AccountId

# Get account by ID
account_id = AccountId("BINANCE-001")
account = self.cache.account(account_id)

# Get account for venue
account = self.cache.account_for_venue(Venue("BINANCE"))

# Get all accounts
accounts = self.cache.accounts()

# Get account IDs
account_ids = self.cache.account_ids()
```

### Account Details

```python
if account:
    # Account type
    account_type = account.account_type  # CASH, MARGIN, BETTING

    # Balances
    balances = account.balances()
    for currency, balance in balances.items():
        total = balance.total
        locked = balance.locked
        free = balance.free

    # Get specific currency balance
    usdt_balance = account.balance(Currency.from_str("USDT"))

    # Margins (for margin accounts)
    margins = account.margins()
```

## Strategy State

### Store Custom State

```python
# Store strategy-specific data in cache
self.cache.add(key="my_signal", value=signal_data)

# Retrieve later
signal_data = self.cache.get("my_signal")

# Check existence
exists = self.cache.has("my_signal")

# Delete
self.cache.delete("my_signal")
```

### Namespaced Keys

```python
# Use strategy ID as namespace
key = f"{self.id}_last_trade_time"
self.cache.add(key=key, value=self.clock.timestamp_ns())

# Retrieve
last_time = self.cache.get(f"{self.id}_last_trade_time")
```

## Cache Configuration

### Backtest Configuration

```python
from nautilus_trader.config import CacheConfig

# Default in-memory cache (backtesting)
cache_config = CacheConfig()
```

### Live Trading Configuration (Redis)

```python
from nautilus_trader.config import CacheConfig, DatabaseConfig

cache_config = CacheConfig(
    database=DatabaseConfig(
        host="localhost",
        port=6379,
        username="nautilus",
        password="your_password",
        ssl=False,
        timeout=2.0,
    ),
    encoding="msgpack",  # or "json"
    timestamps_as_iso8601=True,
    buffer_interval_ms=100,  # Buffer writes for performance
    flush_on_start=False,  # Set True to clear cache on startup
)
```

### Apply Configuration

```python
from nautilus_trader.config import TradingNodeConfig

config = TradingNodeConfig(
    trader_id="TRADER-001",
    cache=cache_config,
    # ... other config
)
```

## Common Patterns

### 1. Check Market State Before Trading

```python
def on_bar(self, bar: Bar):
    # Verify we have required data
    quote = self.cache.quote_tick(self.instrument_id)
    if not quote:
        self.log.warning("No quote data available")
        return

    instrument = self.cache.instrument(self.instrument_id)
    if not instrument:
        self.log.error("Instrument not found")
        return

    # Check spread is reasonable
    spread = float(quote.ask_price - quote.bid_price)
    if spread > self.max_spread:
        self.log.info(f"Spread too wide: {spread}")
        return

    # Proceed with trading logic
```

### 2. Position-Aware Order Sizing

```python
def calculate_order_size(self):
    # Get current position
    positions = self.cache.positions_open(instrument_id=self.instrument_id)

    current_qty = sum(float(p.signed_qty) for p in positions)

    # Get open orders that would change position
    open_orders = self.cache.orders_open(instrument_id=self.instrument_id)
    pending_qty = sum(
        float(o.quantity) * (1 if o.side == OrderSide.BUY else -1)
        for o in open_orders
    )

    # Calculate remaining capacity
    max_position = 10.0
    remaining = max_position - abs(current_qty + pending_qty)

    return max(0, remaining)
```

### 3. Multi-Instrument State Check

```python
def check_all_instruments(self):
    """Check market state across all instruments."""
    for instrument_id in self.instrument_ids:
        quote = self.cache.quote_tick(instrument_id)
        book = self.cache.order_book(instrument_id)

        if quote and book:
            mid = (float(quote.bid_price) + float(quote.ask_price)) / 2
            imbalance = book.imbalance()
            self.log.info(f"{instrument_id}: mid={mid:.2f}, imbalance={imbalance:.2f}")
```

### 4. Order Book Analysis

```python
def analyze_order_book(self):
    book = self.cache.order_book(self.instrument_id)
    if not book:
        return

    # Calculate weighted mid price
    best_bid = float(book.best_bid_price())
    best_ask = float(book.best_ask_price())
    bid_size = float(book.best_bid_size())
    ask_size = float(book.best_ask_size())

    total_size = bid_size + ask_size
    if total_size > 0:
        weighted_mid = (best_bid * ask_size + best_ask * bid_size) / total_size
    else:
        weighted_mid = (best_bid + best_ask) / 2

    # Calculate book pressure
    pressure = bid_size / ask_size if ask_size > 0 else float('inf')

    return {
        "weighted_mid": weighted_mid,
        "pressure": pressure,
        "spread": best_ask - best_bid,
        "imbalance": book.imbalance(),
    }
```

## Performance Considerations

- Cache operations are O(1) for most lookups
- Rust-backed storage for maximum performance
- Automatic memory management
- Redis backend adds network latency but provides persistence
- Use `buffer_interval_ms` to batch Redis writes

## Next Steps

- **Build strategies:** Read `strategy-development.md`
- **Query portfolio:** Read `portfolio.md`
- **Manage orders:** Read `orders.md`
- **Understand architecture:** Read `architecture.md`

## Additional Resources

- **Cache Docs:** https://nautilustrader.io/docs/latest/concepts/cache/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/cache/

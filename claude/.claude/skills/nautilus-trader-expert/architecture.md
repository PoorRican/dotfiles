# Architecture Overview

## Design Philosophy

NautilusTrader follows a **ports and adapters** (hexagonal) architectural style with these quality attributes prioritized:

1. **Correctness** - Software accuracy at the highest level
2. **Performance** - High-throughput, low-latency event processing
3. **Reliability** - Mission-critical workload support
4. **Modularity** - Composable, extensible components
5. **Type Safety** - Leveraging Rust and Cython for compile-time guarantees

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NautilusKernel                          │
│  (Central orchestration and lifecycle management)           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │   Cache    │  │ MessageBus │  │  Portfolio │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │DataEngine  │  │ExecEngine  │  │ RiskEngine │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  User Components: Strategies, Actors, ExecAlgorithms       │
├─────────────────────────────────────────────────────────────┤
│  Adapters: DataClients, ExecClients (Venue Integration)    │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. NautilusKernel

**Location:** `nautilus_trader.system.kernel`

The central orchestration component responsible for:
- Initializing all system components
- Managing component lifecycle (start, stop, dispose)
- Configuring messaging infrastructure
- Coordinating shared resources
- Providing unified entry point for operations

**Key Methods:**
```python
from nautilus_trader.system.kernel import NautilusKernel

# Kernel is typically created and managed by:
# - BacktestEngine (for backtesting)
# - TradingNode (for live/sandbox)
```

**Component Registration:**
The kernel maintains references to:
- Cache
- MessageBus
- Portfolio
- DataEngine
- ExecutionEngine
- RiskEngine
- All registered strategies and actors

### 2. MessageBus

**Location:** `nautilus_trader.common.messages`

The backbone of inter-component communication implementing:
- **Publish/Subscribe patterns** for broadcasting
- **Point-to-point messaging** for targeted communication
- **Request/Response patterns** for synchronous operations
- **Type-safe topic routing**

**Key Capabilities:**
```python
# Subscribe to messages
self.msgbus.subscribe(topic="events.order.*", handler=self.on_order_event)

# Publish messages
self.msgbus.publish(topic="events.signal", message=signal)

# Unsubscribe
self.msgbus.unsubscribe(topic="events.order.*", handler=self.on_order_event)
```

**Topic Patterns:**
- `data.*` - Market data events
- `events.*` - System events
- `orders.*` - Order events
- `positions.*` - Position events
- Custom topics for user-defined messages

**Benefits:**
- Loose coupling between components
- Flexibility to add new publishers/subscribers
- Global message visibility
- Efficient event distribution

See: https://nautilustrader.io/docs/latest/concepts/message_bus/

### 3. Cache

**Location:** `nautilus_trader.cache.cache`

High-performance cache for fast access to:
- **Instruments** - Trading instrument specifications
- **Market Data** - Latest quotes, trades, order books
- **Orders** - All order states and history
- **Positions** - Current and historical positions
- **Accounts** - Account states and balances
- **Strategy State** - User-defined strategy data

**Key Methods:**
```python
from nautilus_trader.cache.cache import Cache

# Access via strategy/actor
instrument = self.cache.instrument(instrument_id)
quote = self.cache.quote_tick(instrument_id)
order = self.cache.order(client_order_id)
position = self.cache.position(position_id)
account = self.cache.account(account_id)
```

**Performance:**
- Rust-backed high-performance storage
- O(1) lookups for most operations
- Automatic cleanup and memory management

**Persistence Options:**
- In-memory only (default for backtesting)
- Redis backend (for live trading)
- Custom database backends

### 4. DataEngine

**Location:** `nautilus_trader.data.engine`

Handles all data processing and distribution:
- **Data Client Management** - Coordinates multiple data sources
- **Subscription Management** - Routes data to subscribers
- **Data Validation** - Ensures data integrity
- **Bar Aggregation** - Creates bars from ticks
- **Custom Data Support** - Handles user-defined data types

**Key Capabilities:**
```python
# Subscribe to data (called within Strategy)
self.subscribe_quote_ticks(instrument_id)
self.subscribe_trade_ticks(instrument_id)
self.subscribe_bars(bar_type)
self.subscribe_order_book_deltas(instrument_id)

# Request historical data
self.request_bars(
    bar_type=bar_type,
    start=start_time,
    end=end_time,
)
```

**Data Flow:**
```
External Data Source
        ↓
   DataClient (adapter)
        ↓
   DataEngine (validation, routing)
        ↓
   Cache (storage)
        ↓
   MessageBus (distribution)
        ↓
   Strategies/Actors (consumption)
```

See: https://nautilustrader.io/docs/latest/concepts/overview/#data-flow

### 5. ExecutionEngine

**Location:** `nautilus_trader.execution.engine`

Manages order execution workflow:
- **Order Validation** - Pre-submission checks
- **Order Routing** - Routes orders to venues
- **Execution Reports** - Processes venue responses
- **Order Emulation** - Client-side order types
- **Reconciliation** - Syncs state with venues

**Order Lifecycle:**
```
Strategy submits order
        ↓
RiskEngine (pre-trade checks)
        ↓
ExecutionEngine (validation)
        ↓
OrderEmulator (if needed) OR ExecutionClient
        ↓
Venue/Exchange
        ↓
Execution Reports back through system
        ↓
Portfolio updated
        ↓
Strategy notified
```

**Key Features:**
- Multiple venue support
- Order emulation for unsupported types
- Concurrent order management
- Automatic reconciliation

See: https://nautilustrader.io/docs/latest/concepts/overview/#execution-flow

### 6. RiskEngine

**Location:** `nautilus_trader.risk.engine`

Provides risk management and controls:
- **Pre-trade Risk Checks** - Validates orders before submission
- **Position Limits** - Enforces max position sizes
- **Order Limits** - Rate limiting and max order counts
- **Custom Risk Rules** - User-defined risk logic

**Risk Check Flow:**
```
Order Submission Request
        ↓
RiskEngine Checks:
  - Position limits
  - Order rate limits
  - Account balance
  - Custom rules
        ↓
Approved → ExecutionEngine
Denied → Order rejected
```

**Configuration:**
```python
from nautilus_trader.config import RiskEngineConfig

risk_config = RiskEngineConfig(
    bypass=False,  # Never bypass in production
    max_order_submit_rate=100,  # Orders per second
    max_order_modify_rate=50,
    max_notional_per_order={"USD": 100_000},
)
```

### 7. Portfolio

**Location:** `nautilus_trader.portfolio.portfolio`

Manages trading accounts and positions:
- **Account Management** - Tracks balances and margins
- **Position Tracking** - Open and closed positions
- **PnL Calculation** - Realized and unrealized PnL
- **Margin Calculation** - Initial and maintenance margins
- **Exposure Tracking** - Net exposure by currency

**Key Methods:**
```python
# Access account information
account = self.portfolio.account(venue)
balances = self.portfolio.balances_locked(venue)
margins = self.portfolio.margins_init(venue)

# Position information
position = self.portfolio.position(position_id)
positions = self.portfolio.positions_open(venue)
unrealized_pnl = self.portfolio.unrealized_pnl(instrument_id)
realized_pnl = self.portfolio.realized_pnl(instrument_id)

# Exposure
net_exposure = self.portfolio.net_exposure(instrument_id)
exposures = self.portfolio.net_exposures(venue)
```

## System Nodes

### BacktestEngine

**Location:** `nautilus_trader.backtest.engine`

Specialized kernel for backtesting:
- Replays historical data with nanosecond resolution
- Simulates venue execution and fills
- Deterministic event ordering
- Performance metrics generation

**Use Cases:**
- Strategy testing and validation
- Parameter optimization
- Walk-forward analysis
- AI agent training

See: `backtesting.md` for details

### TradingNode

**Location:** `nautilus_trader.live.node`

Production-ready kernel for live/sandbox trading:
- Real-time data ingestion
- Live order execution
- State persistence
- Error recovery
- Monitoring and logging

**Environments:**
- **Live** - Real money, real markets
- **Sandbox/Paper** - Real data, simulated execution

See: `live-trading.md` for details

## Data Flow Architecture

### Inbound Data Flow

```
Market Data
    ↓
DataClient (venue adapter)
    ↓
DataEngine (normalize & validate)
    ↓
Cache (store latest state)
    ↓
MessageBus (publish events)
    ↓
Strategies/Actors (handle events)
```

### Outbound Order Flow

```
Strategy (submit order)
    ↓
RiskEngine (validate)
    ↓
ExecutionEngine (route)
    ↓
OrderEmulator (optional)
    ↓
ExecutionClient (venue adapter)
    ↓
Venue/Exchange
```

### Event Processing

All components operate on an event-driven model:
1. Event enters system (data, order, etc.)
2. Cache updated immediately
3. Event published to MessageBus
4. Subscribers receive event
5. Handlers process event
6. New events may be generated
7. Cycle repeats

## Source Code Structure

### Python Package Layout

```
nautilus_trader/
├── adapters/           # Venue-specific integrations
│   ├── binance/
│   ├── bybit/
│   ├── interactive_brokers/
│   └── ...
├── accounting/         # Account management
├── backtest/          # Backtesting components
│   ├── engine.py      # BacktestEngine
│   ├── models.py      # FillModel, etc.
│   └── node.py        # BacktestNode
├── cache/             # Cache implementations
│   └── cache.py       # Main Cache class
├── common/            # Common components
│   ├── component.py   # Base component
│   ├── clock.py       # Clock implementations
│   └── messages.py    # MessageBus
├── config/            # Configuration objects
├── core/              # Core utilities
├── data/              # Data engine and clients
│   ├── engine.py      # DataEngine
│   └── client.py      # DataClient base
├── execution/         # Execution engine
│   ├── engine.py      # ExecutionEngine
│   └── client.py      # ExecutionClient base
├── indicators/        # Technical indicators
├── live/              # Live trading
│   └── node.py        # TradingNode
├── model/             # Data models
│   ├── data.py        # Market data types
│   ├── orders.py      # Order types
│   ├── identifiers.py # ID types
│   └── instruments.py # Instrument types
├── persistence/       # Data persistence
│   └── catalog.py     # ParquetDataCatalog
├── portfolio/         # Portfolio management
│   └── portfolio.py   # Portfolio class
├── risk/              # Risk engine
│   └── engine.py      # RiskEngine
├── system/            # System kernel
│   └── kernel.py      # NautilusKernel
└── trading/           # Trading components
    ├── strategy.py    # Strategy base
    ├── trader.py      # Trader
    └── ...
```

### Rust Crates Structure

```
nautilus_core/
└── crates/
    ├── core/          # Core Rust types
    ├── model/         # Data models
    ├── common/        # Common components
    ├── infrastructure/# Infrastructure
    ├── network/       # Networking clients
    └── system/        # System kernel
```

## Component Lifecycle

All components follow a standard lifecycle:

```
INITIALIZED → STARTING → RUNNING → STOPPING → STOPPED
                ↓            ↓
             DEGRADING   FAULTING
```

**State Methods:**
- `initialize()` - Component creation
- `start()` - Transition to RUNNING
- `stop()` - Graceful shutdown
- `reset()` - Return to initial state
- `dispose()` - Final cleanup

**User Hooks (in Strategies/Actors):**
- `on_start()` - Called when transitioning to RUNNING
- `on_stop()` - Called when stopping
- `on_reset()` - Called when resetting
- `on_save()` - Save state
- `on_load()` - Load state

## Asynchronous Architecture

NautilusTrader runs on a single event loop for maximum performance:

```python
import asyncio

# Event loop managed internally
# All I/O operations are async
# User code can be sync or async
```

**Performance Optimization:**
- Single-threaded event loop (no GIL contention)
- Optional uvloop support (Linux/macOS)
- Zero-copy data structures where possible
- Rust/Cython for hot paths

## Environment Contexts

The same architecture supports three contexts:

1. **Backtest** - BacktestEngine with simulated venues
2. **Sandbox** - TradingNode with real data, simulated execution
3. **Live** - TradingNode with real data, real execution

**Key Benefit:** Write once, run anywhere - strategies need no changes.

## Next Steps

- **For strategy development:** Read `strategy-development.md`
- **For backtesting setup:** Read `backtesting.md`
- **For live deployment:** Read `live-trading.md`
- **For data models:** Read `data-models.md`

## Additional Resources

- **Architecture Docs:** https://nautilustrader.io/docs/latest/concepts/architecture/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/
- **System Crate Docs:** https://docs.rs/nautilus-system

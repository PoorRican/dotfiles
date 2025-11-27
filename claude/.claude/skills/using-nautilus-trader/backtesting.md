# Backtesting Guide

## Overview

NautilusTrader provides two API levels for backtesting:
- **High-level API**: Uses `BacktestNode` with configuration objects (recommended)
- **Low-level API**: Uses `BacktestEngine` directly for fine-grained control

Both approaches replay historical data with nanosecond resolution through an event-driven engine.

## High-Level API (Recommended)

**Location:** `nautilus_trader.backtest.node`, `nautilus_trader.config`

### Basic Backtest Setup

```python
from nautilus_trader.backtest.node import BacktestNode
from nautilus_trader.config import BacktestRunConfig, BacktestEngineConfig
from nautilus_trader.config import BacktestVenueConfig, BacktestDataConfig
from nautilus_trader.model.identifiers import Venue
from nautilus_trader.model.enums import AccountType, OmsType
from nautilus_trader.persistence.catalog import ParquetDataCatalog

# Load data from catalog
catalog = ParquetDataCatalog("./catalog")

# Configure backtest run
config = BacktestRunConfig(
    engine=BacktestEngineConfig(
        trader_id="BACKTESTER-001",
    ),
    venues=[
        BacktestVenueConfig(
            name="BINANCE",
            oms_type=OmsType.NETTING,
            account_type=AccountType.CASH,
            starting_balances=["10000 USDT"],
            base_currency="USDT",
        )
    ],
    data=[
        BacktestDataConfig(
            catalog_path="./catalog",
            data_cls=QuoteTick,
            instrument_id="BTCUSDT.BINANCE",
        )
    ],
    strategies=[
        MyStrategyConfig(
            instrument_id="BTCUSDT.BINANCE",
            bar_type="BTCUSDT.BINANCE-1-MINUTE-LAST-EXTERNAL",
        )
    ]
)

# Run backtest
node = BacktestNode(configs=[config])
results = node.run()

# Access results
for result in results:
    print(f"Total PnL: {result}")
```

### Multiple Backtest Runs

```python
# Define multiple configurations
configs = [
    BacktestRunConfig(
        engine=BacktestEngineConfig(trader_id="TESTER-001"),
        strategies=[MyStrategyConfig(fast_period=10, slow_period=20)],
        # ... other config
    ),
    BacktestRunConfig(
        engine=BacktestEngineConfig(trader_id="TESTER-002"),
        strategies=[MyStrategyConfig(fast_period=12, slow_period=26)],
        # ... other config
    ),
]

# Run all configurations
node = BacktestNode(configs=configs)
results = node.run()

# Each run gets a fresh engine with clean state
for i, result in enumerate(results):
    print(f"Run {i}: {result}")
```

### Advantages of High-Level API

- Clean configuration-based setup
- Automatic data streaming from catalog
- Support for multiple runs
- Simplified data management
- Best for parameter optimization

## Low-Level API

**Location:** `nautilus_trader.backtest.engine`

### Basic Backtest Engine Setup

```python
from nautilus_trader.backtest.engine import BacktestEngine
from nautilus_trader.model import Money, Currency
from nautilus_trader.model.enums import OmsType, AccountType

# Initialize engine
engine = BacktestEngine()

# Add venue
engine.add_venue(
    venue=Venue("BINANCE"),
    oms_type=OmsType.NETTING,
    account_type=AccountType.CASH,
    starting_balances=[Money(10_000, Currency.from_str("USDT"))],
    base_currency=Currency.from_str("USDT"),
)

# Add instruments
engine.add_instrument(btcusdt_instrument)

# Add data
engine.add_data(bars)  # Can be bars, ticks, order book data

# Add strategy
engine.add_strategy(MyStrategy(config))

# Run backtest
engine.run()

# Access results
portfolio = engine.trader.generate_order_fills_report()
account = engine.trader.generate_account_report()
```

### Adding Different Data Types

```python
from nautilus_trader.model.data import QuoteTick, TradeTick, Bar

# Add quote ticks
quote_ticks = catalog.quote_ticks(instrument_ids=["BTCUSDT.BINANCE"])
engine.add_data(quote_ticks)

# Add trade ticks
trade_ticks = catalog.trade_ticks(instrument_ids=["BTCUSDT.BINANCE"])
engine.add_data(trade_ticks)

# Add bars
bars = catalog.bars(instrument_ids=["BTCUSDT.BINANCE"])
engine.add_data(bars)

# Add order book data
deltas = catalog.order_book_deltas(instrument_ids=["BTCUSDT.BINANCE"])
engine.add_data(deltas)
```

### Multiple Runs with Reset

```python
# First run
engine.add_strategy(strategy1)
engine.run()
results1 = engine.trader.generate_order_fills_report()

# Reset for second run (instruments and data persist)
engine.reset()

# Second run with different strategy
engine.add_strategy(strategy2)
engine.run()
results2 = engine.trader.generate_order_fills_report()

# Third run with modified parameters
engine.reset()
engine.add_strategy(strategy3)
engine.run()
results3 = engine.trader.generate_order_fills_report()
```

**Note:** By default, instruments and data persist across `reset()` calls for efficient parameter optimization.

### Advantages of Low-Level API

- Fine-grained control over engine
- Ability to reuse data across runs
- Direct access to all engine components
- Suitable for streaming large datasets
- Best for custom workflows

## Venue Configuration

### Order Management System (OMS) Types

```python
from nautilus_trader.model.enums import OmsType

# NETTING: Single position per instrument (crypto-style)
oms_type=OmsType.NETTING

# HEDGING: Multiple positions per instrument (traditional futures)
oms_type=OmsType.HEDGING
```

### Account Types

```python
from nautilus_trader.model.enums import AccountType

# CASH: Spot/cash trading (most crypto)
account_type=AccountType.CASH

# MARGIN: Margin/leverage trading
account_type=AccountType.MARGIN

# BETTING: Betting exchange
account_type=AccountType.BETTING
```

### Starting Balances

```python
# Single currency
starting_balances=["10000 USDT"]

# Multiple currencies
starting_balances=[
    "10000 USDT",
    "1.0 BTC",
    "10.0 ETH"
]
```

## Fill Models

**Location:** `nautilus_trader.backtest.models`

Fill models control how orders are filled during backtests.

### Default Fill Model

```python
from nautilus_trader.backtest.models import FillModel

fill_model = FillModel(
    prob_fill_on_limit=0.0,   # Probability limit orders fill when price touches
    prob_slippage=0.0,         # Probability of 1-tick slippage on market orders
    random_seed=None,          # Set for reproducibility
)
```

### Conservative Fill Model

```python
# More realistic fills - limit orders don't always fill at limit price
fill_model = FillModel(
    prob_fill_on_limit=0.2,    # 20% chance limit fills when touched
    prob_slippage=0.5,         # 50% chance of slippage
    random_seed=42,            # Reproducible results
)
```

### Optimistic Fill Model

```python
# Assumes perfect fills
fill_model = FillModel(
    prob_fill_on_limit=1.0,    # Always fill limit orders
    prob_slippage=0.0,         # No slippage
)
```

### Apply Fill Model

```python
from nautilus_trader.backtest.config import BacktestEngineConfig

engine_config = BacktestEngineConfig(
    trader_id="TESTER-001",
    fill_model=fill_model,
)
```

## Slippage and Spread Simulation

### Data-Driven Slippage

For different data types, slippage is handled differently:

**L2/L3 Order Book Data:**
- High accuracy simulation
- Orders filled against actual book levels
- Sequential matching at each price level

**Bar Data:**
- Adaptive high/low ordering
- Configurable slippage probability
- 1-tick slippage model

**Quote/Trade Ticks:**
- Bid/ask spread naturally included
- Configurable slippage
- Realistic fill simulation

### Adaptive Bar Ordering

```python
engine.add_venue(
    venue=Venue("BINANCE"),
    oms_type=OmsType.NETTING,
    account_type=AccountType.CASH,
    starting_balances=["10000 USDT"],
    bar_adaptive_high_low_ordering=True,  # Enable adaptive ordering
)
```

When enabled, the engine intelligently orders high/low bar prices based on open/close relationship.

## Data Management

### Using ParquetDataCatalog

```python
from nautilus_trader.persistence.catalog import ParquetDataCatalog

# Initialize catalog
catalog = ParquetDataCatalog("./catalog")

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

# Query trade ticks
trades = catalog.trade_ticks(
    instrument_ids=["BTCUSDT.BINANCE"],
    start="2024-01-01",
    end="2024-01-31",
)
```

### Memory Management for Large Datasets

For datasets exceeding available memory:

```python
# Use high-level API with streaming
config = BacktestRunConfig(
    data=[
        BacktestDataConfig(
            catalog_path="./catalog",
            data_cls=QuoteTick,
            instrument_id="BTCUSDT.BINANCE",
            start_time="2024-01-01",
            end_time="2024-12-31",
        )
    ]
)

# Data is streamed in chunks automatically
node = BacktestNode(configs=[config])
results = node.run()
```

## Performance Analysis

### Generate Reports

```python
# After backtest run
engine = BacktestEngine()
# ... configure and run ...

# Order fills report
fills_report = engine.trader.generate_order_fills_report()
print(fills_report)

# Account report
account_report = engine.trader.generate_account_report(Venue("BINANCE"))
print(account_report)

# Position report
positions_report = engine.trader.generate_positions_report()
print(positions_report)
```

### Access Portfolio Statistics

```python
# Access portfolio
portfolio = engine.trader.portfolio

# Get final PnLs
realized_pnl = portfolio.realized_pnls(Venue("BINANCE"))
unrealized_pnl = portfolio.unrealized_pnls(Venue("BINANCE"))

# Get final positions
positions = portfolio.positions_open()

# Get order statistics
orders = engine.cache.orders()
filled_orders = [o for o in orders if o.is_filled]
```

## Parameter Optimization

### Grid Search Example

```python
# Define parameter grid
fast_periods = [10, 12, 14]
slow_periods = [20, 26, 30]

configs = []
for fast in fast_periods:
    for slow in slow_periods:
        config = BacktestRunConfig(
            engine=BacktestEngineConfig(
                trader_id=f"TEST-{fast}-{slow}"
            ),
            strategies=[
                MyStrategyConfig(
                    fast_period=fast,
                    slow_period=slow,
                )
            ],
            # ... other config
        )
        configs.append(config)

# Run all combinations
node = BacktestNode(configs=configs)
results = node.run()

# Find best parameters
best_idx = max(range(len(results)), key=lambda i: results[i].total_pnl)
print(f"Best parameters: {configs[best_idx]}")
```

### Walk-Forward Analysis

```python
# Define periods
train_periods = [
    ("2024-01-01", "2024-03-31"),
    ("2024-04-01", "2024-06-30"),
    ("2024-07-01", "2024-09-30"),
]
test_periods = [
    ("2024-04-01", "2024-04-30"),
    ("2024-07-01", "2024-07-31"),
    ("2024-10-01", "2024-10-31"),
]

for train_period, test_period in zip(train_periods, test_periods):
    # Train on train_period, optimize parameters
    # Test on test_period with optimal parameters
    pass
```

## Common Patterns

### Multi-Instrument Backtest

```python
instruments = [
    "BTCUSDT.BINANCE",
    "ETHUSDT.BINANCE",
    "SOLUSDT.BINANCE",
]

config = BacktestRunConfig(
    venues=[
        BacktestVenueConfig(
            name="BINANCE",
            oms_type=OmsType.NETTING,
            account_type=AccountType.CASH,
            starting_balances=["30000 USDT"],
        )
    ],
    data=[
        BacktestDataConfig(
            catalog_path="./catalog",
            data_cls=Bar,
            instrument_id=inst_id,
        )
        for inst_id in instruments
    ],
    strategies=[
        MyStrategyConfig(
            instrument_ids=instruments,
        )
    ]
)
```

### Multi-Venue Backtest

```python
config = BacktestRunConfig(
    venues=[
        BacktestVenueConfig(
            name="BINANCE",
            oms_type=OmsType.NETTING,
            account_type=AccountType.CASH,
            starting_balances=["10000 USDT"],
        ),
        BacktestVenueConfig(
            name="COINBASE",
            oms_type=OmsType.NETTING,
            account_type=AccountType.CASH,
            starting_balances=["10000 USD"],
        ),
    ],
    # ... data and strategies
)
```

## Troubleshooting

### Common Issues

**1. Data not being processed:**
- Ensure data is sorted chronologically
- Verify instrument IDs match exactly
- Check data timestamps are in UTC

**2. Orders not filling:**
- Check fill model probabilities
- Verify price is within bid/ask spread
- Ensure sufficient account balance

**3. Performance issues:**
- Use ParquetDataCatalog for large datasets
- Stream data instead of loading all in memory
- Reduce data resolution if possible

**4. Inconsistent results:**
- Set `random_seed` in FillModel
- Ensure data ordering is deterministic
- Check for strategy state issues

## Best Practices

1. **Start Simple**: Begin with bar data before moving to tick data
2. **Conservative Fills**: Use realistic fill models with slippage
3. **Multiple Runs**: Test strategies across different time periods
4. **Walk-Forward**: Use walk-forward analysis for robustness
5. **Data Quality**: Ensure clean, validated historical data
6. **Realistic Costs**: Include transaction fees and slippage
7. **State Management**: Reset strategy state between runs properly

## Next Steps

- **Deploy live:** Read `live-trading.md`
- **See examples:** Read `examples.md`
- **Optimize strategies:** Read `best-practices.md`

## Additional Resources

- **Backtesting Docs:** https://nautilustrader.io/docs/latest/concepts/backtesting/
- **Data Catalog Guide:** https://nautilustrader.io/docs/latest/concepts/data/
- **Example Backtests:** https://github.com/nautechsystems/nautilus_trader/tree/develop/examples/backtest

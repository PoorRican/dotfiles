# Portfolio Guide

## Overview

The Portfolio component manages account balances, positions, and PnL calculations across all venues. It provides a unified view of trading state.

**Location:** `nautilus_trader.portfolio.portfolio`

## Portfolio vs Cache

| Component | Purpose | Data |
|-----------|---------|------|
| **Cache** | Fast data access | Instruments, market data, orders, positions |
| **Portfolio** | State management | Accounts, balances, margins, PnL calculations |

Use **Cache** to query raw data. Use **Portfolio** for financial state and calculations.

## Accessing Portfolio

From strategies and actors:

```python
class MyStrategy(Strategy):

    def on_bar(self, bar):
        # Portfolio is accessed via self.portfolio
        account = self.portfolio.account(Venue("BINANCE"))
        positions = self.portfolio.positions_open()
```

## Account Information

### Get Account

```python
from nautilus_trader.model.identifiers import Venue

# Get account for venue
venue = Venue("BINANCE")
account = self.portfolio.account(venue)

if account:
    # Account type
    account_type = account.account_type  # CASH, MARGIN, BETTING

    # Account ID
    account_id = account.id
```

### Account Balances

```python
def check_balances(self):
    venue = Venue("BINANCE")

    # Get all balances
    balances = self.portfolio.balances(venue)
    for currency, balance in balances.items():
        self.log.info(f"{currency}: total={balance.total}, free={balance.free}, locked={balance.locked}")

    # Get locked balances only
    locked = self.portfolio.balances_locked(venue)

    # Get specific currency balance
    usdt_balance = account.balance(Currency.from_str("USDT"))
    if usdt_balance:
        total = usdt_balance.total
        free = usdt_balance.free
        locked = usdt_balance.locked
```

### Margins (for Margin Accounts)

```python
def check_margins(self):
    venue = Venue("BINANCE")

    # Initial margins
    init_margins = self.portfolio.margins_init(venue)

    # Maintenance margins
    maint_margins = self.portfolio.margins_maint(venue)

    for instrument_id, margin in init_margins.items():
        self.log.info(f"{instrument_id}: init_margin={margin}")
```

## Position Information

### Get Positions

```python
# All open positions
open_positions = self.portfolio.positions_open()

# Open positions for venue
binance_positions = self.portfolio.positions_open(venue=Venue("BINANCE"))

# Open positions for instrument
btc_positions = self.portfolio.positions_open(instrument_id=self.instrument_id)

# Open positions for strategy
my_positions = self.portfolio.positions_open(strategy_id=self.id)

# Closed positions
closed_positions = self.portfolio.positions_closed()

# Specific position
position = self.portfolio.position(position_id)
```

### Position Details

```python
for position in self.portfolio.positions_open():
    # Basic info
    instrument_id = position.instrument_id
    side = position.side  # LONG, SHORT, FLAT
    quantity = position.quantity
    signed_qty = position.signed_qty  # Positive for long, negative for short

    # Entry info
    avg_entry = position.avg_px_open
    opened_time = position.opened_time

    # Exit info (if partially/fully closed)
    avg_exit = position.avg_px_close
    closed_time = position.closed_time

    # Trade count
    buy_qty = position.buy_qty
    sell_qty = position.sell_qty

    # Duration
    duration_ns = position.duration_ns
```

### Check Position State

```python
def check_position_state(self):
    instrument_id = self.instrument_id

    # Net position (signed quantity)
    net_position = self.portfolio.net_position(instrument_id)
    # Positive = long, Negative = short, Zero = flat

    # Boolean checks
    is_long = self.portfolio.is_net_long(instrument_id)
    is_short = self.portfolio.is_net_short(instrument_id)
    is_flat = self.portfolio.is_flat(instrument_id)

    # Check completely flat
    all_flat = self.portfolio.is_completely_flat()
```

## PnL Calculations

### Unrealized PnL

```python
def check_unrealized_pnl(self):
    # For specific instrument
    unrealized = self.portfolio.unrealized_pnl(self.instrument_id)
    if unrealized:
        self.log.info(f"Unrealized PnL: {unrealized}")

    # For all instruments at venue
    unrealized_all = self.portfolio.unrealized_pnls(Venue("BINANCE"))
    for instrument_id, pnl in unrealized_all.items():
        self.log.info(f"{instrument_id}: {pnl}")
```

### Realized PnL

```python
def check_realized_pnl(self):
    # For specific instrument
    realized = self.portfolio.realized_pnl(self.instrument_id)
    if realized:
        self.log.info(f"Realized PnL: {realized}")

    # For all instruments at venue
    realized_all = self.portfolio.realized_pnls(Venue("BINANCE"))
```

### Total PnL from Position

```python
def calculate_position_pnl(self, position, current_price: float):
    # Get unrealized PnL at current price
    price = Price.from_str(str(current_price))
    unrealized = position.unrealized_pnl(price)

    # Realized PnL (from partial closes)
    realized = position.realized_pnl

    # Total PnL
    total = position.total_pnl(price)

    # Return percentage
    return_pct = position.return_pct(price)

    self.log.info(f"Position PnL: realized={realized}, unrealized={unrealized}, total={total}, return={return_pct:.2%}")
```

## Exposure

### Net Exposure

```python
def check_exposure(self):
    # Net exposure for instrument (in quote currency)
    net_exposure = self.portfolio.net_exposure(self.instrument_id)

    # Net exposures for all instruments at venue
    exposures = self.portfolio.net_exposures(Venue("BINANCE"))
    for instrument_id, exposure in exposures.items():
        self.log.info(f"{instrument_id}: exposure={exposure}")
```

### Check Risk Limits

```python
def check_risk_limits(self):
    max_exposure = 100_000.0  # $100k max exposure

    exposure = self.portfolio.net_exposure(self.instrument_id)
    if exposure and float(exposure) > max_exposure:
        self.log.warning(f"Exposure limit exceeded: {exposure}")
        return False
    return True
```

## Account Types

### Cash Account

For spot trading without leverage.

```python
from nautilus_trader.model.enums import AccountType

# Check account type
account = self.portfolio.account(venue)
if account.account_type == AccountType.CASH:
    # No leverage, no margin
    free_balance = account.balance(Currency.from_str("USDT")).free
```

### Margin Account

For leveraged trading.

```python
if account.account_type == AccountType.MARGIN:
    # Has margin requirements
    init_margin = self.portfolio.margins_init(venue)
    maint_margin = self.portfolio.margins_maint(venue)

    # Calculate available margin
    equity = calculate_equity()
    used_margin = sum(init_margin.values())
    available_margin = equity - used_margin
```

## Portfolio Analyzer

For detailed performance analysis after backtests.

```python
from nautilus_trader.analysis.analyzer import PortfolioAnalyzer

# After backtest
analyzer = PortfolioAnalyzer()

# Add account data
for account in engine.cache.accounts():
    analyzer.add_account(account)

# Add positions
for position in engine.cache.positions():
    analyzer.add_position(position)

# Add orders
for order in engine.cache.orders():
    analyzer.add_order(order)

# Generate statistics
stats = analyzer.get_stats()
print(f"Total trades: {stats['total_trades']}")
print(f"Win rate: {stats['win_rate']:.2%}")
print(f"Profit factor: {stats['profit_factor']:.2f}")
print(f"Sharpe ratio: {stats['sharpe_ratio']:.2f}")
print(f"Max drawdown: {stats['max_drawdown']:.2%}")
```

## Common Patterns

### 1. Position-Based Entry

```python
def on_bar(self, bar):
    instrument_id = bar.bar_type.instrument_id

    # Only enter if flat
    if not self.portfolio.is_flat(instrument_id):
        return

    # Entry logic
    if self.should_enter_long():
        self.enter_long(instrument_id)
```

### 2. Risk-Based Position Sizing

```python
def calculate_position_size(self, stop_distance: float) -> Quantity:
    venue = Venue("BINANCE")
    account = self.portfolio.account(venue)

    # Get available capital
    balance = account.balance(Currency.from_str("USDT"))
    available = float(balance.free)

    # Risk 1% of capital per trade
    risk_amount = available * 0.01

    # Calculate position size
    position_size = risk_amount / stop_distance

    return Quantity.from_str(str(round(position_size, 8)))
```

### 3. Portfolio-Wide Risk Check

```python
def check_portfolio_risk(self) -> bool:
    venue = Venue("BINANCE")

    # Calculate total exposure
    total_exposure = 0.0
    exposures = self.portfolio.net_exposures(venue)
    for instrument_id, exposure in exposures.items():
        total_exposure += abs(float(exposure))

    # Get account equity
    account = self.portfolio.account(venue)
    balance = account.balance(Currency.from_str("USDT"))
    equity = float(balance.total)

    # Check exposure ratio
    exposure_ratio = total_exposure / equity if equity > 0 else 0
    if exposure_ratio > 2.0:  # Max 2x leverage
        self.log.warning(f"Exposure ratio too high: {exposure_ratio:.2f}x")
        return False

    return True
```

### 4. Multi-Position Management

```python
def manage_positions(self):
    """Review and manage all open positions."""
    positions = self.portfolio.positions_open()

    for position in positions:
        quote = self.cache.quote_tick(position.instrument_id)
        if not quote:
            continue

        current_price = float(quote.ask_price) if position.side == PositionSide.LONG else float(quote.bid_price)

        # Check profit target
        return_pct = position.return_pct(Price.from_str(str(current_price)))
        if return_pct > 0.05:  # 5% profit
            self.log.info(f"Taking profit on {position.instrument_id}")
            self.close_position(position)

        # Check stop loss
        elif return_pct < -0.02:  # 2% loss
            self.log.info(f"Stopping out {position.instrument_id}")
            self.close_position(position)
```

### 5. Balance Monitoring

```python
def monitor_balance(self):
    """Monitor account balance changes."""
    venue = Venue("BINANCE")
    account = self.portfolio.account(venue)

    if not account:
        return

    balance = account.balance(Currency.from_str("USDT"))
    current_total = float(balance.total)

    if not hasattr(self, 'initial_balance'):
        self.initial_balance = current_total
        return

    # Calculate change
    change = current_total - self.initial_balance
    change_pct = change / self.initial_balance if self.initial_balance > 0 else 0

    self.log.info(f"Balance: {current_total:.2f} ({change:+.2f}, {change_pct:+.2%})")

    # Alert on significant drawdown
    if change_pct < -0.1:  # 10% drawdown
        self.log.error("Significant drawdown detected!")
```

## Next Steps

- **Order management:** Read `orders.md`
- **Execution flow:** Read `execution.md`
- **Strategy development:** Read `strategy-development.md`
- **Best practices:** Read `best-practices.md`

## Additional Resources

- **Portfolio Docs:** https://nautilustrader.io/docs/latest/concepts/portfolio/
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/portfolio/

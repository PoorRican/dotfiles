# Portfolio, Analytics & Report Generation

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/portfolio.md
- https://nautilustrader.io/docs/md/latest/concepts/reports.md
- https://nautilustrader.io/docs/md/latest/concepts/accounting.md
- https://nautilustrader.io/docs/md/latest/concepts/positions.md

## TL;DR

The **`Portfolio`** is the central hub tracking all positions across strategies. It answers PnL / exposure / equity questions, each in a **single-value form** (`unrealized_pnl(...)`) and a **plural dict-returning form** (`unrealized_pnls(...)`) keyed by currency. NautilusTrader does **not** auto-convert across currencies unless you have xrate data and ask for it — so treat PnL as per-settlement-currency by default. Positions carry their own realized/unrealized PnL; the Portfolio aggregates them (including historical **snapshots** for NETTING positions that closed and reopened under the same `PositionId`). Structured **reports** are pandas DataFrames from `ReportProvider` — reach them via `trader.generate_*_report()` (live) or `engine.trader.generate_*_report()` (post-backtest; the helpers live on the `Trader`, not the engine). Performance **statistics** come from `engine.get_result()` (`stats_pnls` / `stats_returns` only — there is no `stats_general` on the result; general stats live on `engine.portfolio.analyzer.get_performance_stats_general()`) and from the `PortfolioAnalyzer`, into which you can register custom statistics.

See also: [strategies](strategies.md), [execution](execution.md) (OMS types), [value-types](value-types.md) (`Money`/`Currency`), [backtesting](backtesting.md), [live-trading](live-trading.md), [gotchas](gotchas.md), and the master [SKILL.md](../SKILL.md).

---

## The Portfolio

Access from a strategy/actor as `self.portfolio`; from a backtest as `engine.portfolio`.

### Account & state

| Method | Returns | Notes |
|---|---|---|
| `portfolio.account(venue)` | `Account` | The account object for a venue (Cash/Margin/Betting). |
| `portfolio.net_position(instrument_id)` | `Decimal` | Signed net quantity (>0 long, <0 short, 0 flat). |
| `portfolio.is_flat(instrument_id)` | `bool` | True if net position is zero. |
| `portfolio.is_net_long(instrument_id)` | `bool` | True if net position > 0. |
| `portfolio.is_net_short(instrument_id)` | `bool` | True if net position < 0. |
| `portfolio.is_completely_flat()` | `bool` | True if no open positions anywhere. |

### PnL, exposure, equity (singular vs plural)

Every value query has a **singular** form (one instrument, returns `Money` or `None`) and a **plural** form (a `dict` keyed by `Currency`). Singular methods take an optional `target_currency`; failed conversions return `None` and log an error. Plural methods **silently omit** currencies whose conversion failed.

| Singular (per-instrument) | Plural (per venue/account) |
|---|---|
| `realized_pnl(instrument_id, target_currency=None)` | `realized_pnls(venue, account_id=None, target_currency=None)` |
| `unrealized_pnl(instrument_id, target_currency=None)` | `unrealized_pnls(venue, account_id=None, target_currency=None)` |
| `total_pnl(instrument_id, target_currency=None)` | `total_pnls(venue, account_id=None, target_currency=None)` |
| `net_exposure(instrument_id, target_currency=None)` | `net_exposures(venue, account_id=None, target_currency=None)` |

Plural results are `dict[Currency, Money]`. `total_pnl = realized + unrealized`.

Additional venue/account-scoped queries:

| Method | Returns | Purpose |
|---|---|---|
| `portfolio.equity(venue, account_id=None)` | `dict[Currency, Money]` | Total equity = account balance + position valuation. |
| `portfolio.mark_values(venue, account_id)` | `dict[Currency, Money]` | Signed mark-to-market totals for open positions. |
| `portfolio.margins_init(venue, account_id=None)` | `dict[InstrumentId, Money]` | Portfolio-level initial margins. |
| `portfolio.margins_maint(venue, account_id=None)` | `dict[InstrumentId, Money]` | Portfolio-level maintenance margins. |
| `portfolio.missing_price_instruments(venue)` | `set[InstrumentId]` | Instruments currently unpriceable (skipped in valuation). |

```python
# One account: auto-converts to that account's base currency
exposure = portfolio.net_exposures(venue=BINANCE, account_id=account_id)

# Multiple accounts, all USD base -> {USD: Money(...)}
exposures = portfolio.net_exposures(venue=BINANCE)

# Multiple accounts, USD + EUR bases -> {USD: Money(...), EUR: Money(...)}
exposures = portfolio.net_exposures(venue=BINANCE)

# Collapse to one currency across accounts (requires xrate data)
exposures = portfolio.net_exposures(venue=BINANCE, target_currency=USD)  # {USD: Money(...)}
```

### Valuation price fallback (load-bearing)

A position is valued from the **first available** source, in order:

1. **Mark price** (if `use_mark_prices` configured and cached)
2. **Side-appropriate quote** — BID for longs, ASK for shorts
3. **Last trade price**
4. **Recent bar close** (if `bar_updates` enabled)

If none exist, the position is **unpriceable**: skipped in valuation/equity and surfaced via `missing_price_instruments(venue)`.

For **cross-currency conversion** to a `target_currency`, the price type is chosen by net direction: **BID** for all-long, **ASK** for all-short (conservative), **MID** for mixed positions — or **MARK** when `use_mark_xrates` is enabled.

### PortfolioConfig

| Field | Type | Default | Meaning |
|---|---|---|---|
| `convert_to_account_base_currency` | `bool` | `True` | Auto-convert values to the account base currency. |
| `use_mark_prices` | `bool` | — | Use mark prices for position valuation when available/cached. |
| `use_mark_xrates` | `bool` | — | Use MARK price type for cross-currency xrates (mixed positions). |
| `bar_updates` | `bool` | — | Allow recent bar close prices to valuate positions. |

---

## Positions & where PnL comes from

Fetch from the [cache](architecture.md): `self.cache.position(position_id)`, `self.cache.positions(instrument_id=instrument_id)`.

| Member | Signature | Purpose |
|---|---|---|
| `position.side` | `-> PositionSide` | `LONG`, `SHORT`, or `FLAT`. |
| `position.signed_qty` | property | Net signed qty (+long, -short, 0 flat). |
| `position.realized_pnl` | property `Money` | Realized PnL on the closed portion. |
| `position.unrealized_pnl(price)` | `-> Money` | vs supplied price; `Money(0, settlement_currency)` when FLAT. |
| `position.total_pnl(price)` | `-> Money` | `realized_pnl + unrealized_pnl(price)`. |
| `position.commissions()` | `-> list[Money]` | Accrued commissions. |
| `position.notional_value(price)` | `-> Money` | Notional value at price. |
| `position.events` | property | Chronological fill-event history (reconciliation). |
| `position.trade_ids` | property | Venue trade IDs (broker-statement matching). |
| `position.adjustments` | property | `PositionAdjusted` events (COMMISSION, FUNDING). |

```python
position.unrealized_pnl(bid_price)   # conservative for LONG
position.unrealized_pnl(ask_price)   # conservative for SHORT
total_pnl = position.total_pnl(current_price)  # realized + unrealized
```

### PnL formulas

```python
# Standard instruments
realized_pnl = (exit_price - entry_price) * closed_quantity * multiplier

# Inverse instruments (side-aware; requires base_currency set)
# LONG:  closed_quantity * multiplier * (1/entry_price - 1/exit_price)
# SHORT: closed_quantity * multiplier * (1/exit_price - 1/entry_price)
```

### OMS types & snapshots

`OmsType.NETTING | OmsType.HEDGING | OmsType.UNSPECIFIED`. Under **NETTING**, fills aggregate into one `PositionId`; when a closed position reopens under the same ID, the exec engine **snapshots** the closed state first, and the Portfolio sums realized PnL across all snapshots. Under **HEDGING**, each fill can open a distinct `PositionId` that never reopens (no snapshots). This is why report/PnL aggregation must include `cache.position_snapshots()` for NETTING — see [execution](execution.md).

> `snapshot_positions` / `snapshot_positions_interval_secs` (Live/ExecEngine config) only record **open**-position telemetry — they are unrelated to the automatic historical close/reopen snapshot mechanism that preserves PnL.

---

## Report generation

`ReportProvider` is a static generator returning pandas DataFrames. Prefer the **`trader.generate_*`** helpers (live) or the same helpers via **`engine.trader.generate_*`** (post-backtest; they are `Trader` methods, not engine methods) — they wire the cache for you.

```python
from nautilus_trader.analysis import ReportProvider
```

| Report | Trader helper | ReportProvider (direct) | Key columns |
|---|---|---|---|
| Orders | `trader.generate_orders_report()` | `ReportProvider.generate_orders_report(orders)` | index `client_order_id`; `instrument_id, side, type, status, quantity, filled_qty, price, avg_px, ts_init, ts_last` |
| Order fills | `trader.generate_order_fills_report()` | `ReportProvider.generate_order_fills_report(orders)` | orders with `filled_qty > 0`; `ts_init`/`ts_last` as datetime |
| Fills (per event) | `trader.generate_fills_report()` | `ReportProvider.generate_fills_report(orders)` | one row/fill: `trade_id, last_px, last_qty, commission, liquidity_side, ts_event` |
| Positions | `trader.generate_positions_report()` | `ReportProvider.generate_positions_report(positions, snapshots)` | `realized_pnl, realized_return, peak_qty, avg_px_open, avg_px_close, duration_ns, is_snapshot` |
| Account | `trader.generate_account_report(venue)` | `ReportProvider.generate_account_report(account)` | index `ts_event`; `total, free, locked, currency, margins` |

Distinctions: **orders** = full set with raw `ts_*`; **order fills** = filtered to `filled_qty > 0` with datetime timestamps; **fills** = one row per individual fill event.

```python
# Orders / fills (same pattern for order_fills and fills)
orders_report = trader.generate_orders_report()
# or:
orders_report = ReportProvider.generate_orders_report(cache.orders())

# Positions WITH snapshots (NETTING) — trader helper includes them automatically
positions_report = trader.generate_positions_report()
# or explicitly:
positions_report = ReportProvider.generate_positions_report(
    positions=cache.positions(),
    snapshots=cache.position_snapshots(),  # required for NETTING PnL correctness
)

# Account report — venue is REQUIRED on trader/engine variants
from nautilus_trader.model.identifiers import Venue
account_report = trader.generate_account_report(Venue("BINANCE"))
```

### Post-backtest reports

```python
engine.run(start=start_time, end=end_time)

fills_report = engine.trader.generate_fills_report()
venue = engine.list_venues()[0]
account_report = engine.trader.generate_account_report(venue=venue)

# Or raw cache access for custom analysis
orders = engine.cache.orders()
positions = engine.cache.positions()
snapshots = engine.cache.position_snapshots()
```

### Live periodic reporting

```python
class ReportingActor(Actor):
    def on_start(self):
        self.clock.set_timer(
            name="generate_reports",
            interval=pd.Timedelta(minutes=30),
            callback=self.generate_reports,
        )

    def generate_reports(self, event):
        report = self.trader.generate_positions_report()
        report.to_csv(f"positions_{event.ts_event}.csv")
```

---

## Performance statistics

`engine.get_result()` returns a `BacktestResult` exposing `summary`, `stats_pnls`, and `stats_returns` — **there is no `stats_general` on the result**. General stats come from the analyzer directly:

```python
result = engine.get_result()
stats_pnls    = result.stats_pnls     # keyed by CURRENCY, then stat name
stats_returns = result.stats_returns  # keyed by stat name

# General stats are NOT on the result — pull them from the analyzer:
stats_general = engine.portfolio.analyzer.get_performance_stats_general()  # keyed by stat name
```

- **`stats_pnls`** — nested `{currency: {stat_name: value}}`, e.g. `"PnL (total)"`, per settlement currency (no cross-currency aggregation).
- **`stats_returns`** — return-based stats keyed by name, e.g. `"Sharpe Ratio (252 days)"`, Sortino, etc.
- **`analyzer.get_performance_stats_general()`** — general stats keyed by name, e.g. `"Win Rate"`, `"Profit Factor"`, expectancy. (`get_performance_stats_pnls()` / `get_performance_stats_returns()` mirror the two result fields.)

```python
results = {
    "total_positions": len(engine.cache.positions_closed()),
    "pnl_total":    stats_pnls.get("USD", {}).get("PnL (total)"),
    "sharpe_ratio": stats_returns.get("Sharpe Ratio (252 days)"),
    "profit_factor": stats_general.get("Profit Factor"),
    "win_rate":     stats_general.get("Win Rate"),
}
print(pd.DataFrame([results]).T)
```

### PortfolioAnalyzer & custom statistics

The `PortfolioAnalyzer` (`engine.portfolio.analyzer`) drives the stat categories above. A custom statistic **subclasses `PortfolioStatistic`** (`nautilus_trader.analysis.statistic`) and overrides one of the `calculate_from_*` hooks — `calculate_from_realized_pnls(pd.Series)`, `calculate_from_returns(pd.Series)`, `calculate_from_orders(list[Order])`, or `calculate_from_positions(list[Position])` — returning a JSON-serializable scalar (or `None` on degenerate input). The stat `name` defaults to the class name split on CamelCase (`WinRatePct` → `"Win Rate Pct"`). Register the instance with `analyzer.register_statistic(...)`.

```python
import pandas as pd
from nautilus_trader.analysis.statistic import PortfolioStatistic

class WinRatePct(PortfolioStatistic):
    def calculate_from_realized_pnls(self, realized_pnls: pd.Series):
        if realized_pnls is None or realized_pnls.empty:
            return None
        winners = realized_pnls[realized_pnls > 0.0]
        return len(winners) / len(realized_pnls)

analyzer = engine.portfolio.analyzer
analyzer.register_statistic(WinRatePct())
# after engine.run(), the stat appears under its name in the general stats:
analyzer.get_performance_stats_general()["Win Rate Pct"]
```

Built-in statistic classes (`WinRate`, `ProfitFactor`, `SharpeRatio`, `SortinoRatio`, `MaxDrawdown`, `Expectancy`, …) are exported from `nautilus_trader.analysis`, but they are pyo3 implementations, **not** `PortfolioStatistic` subclasses — `register_statistic` accepts only `PortfolioStatistic` instances.

### Multi-currency PnL aggregation (must include snapshots)

There is **no built-in currency conversion** for total PnL. Sum current positions **and** historical snapshots, bucketed per currency:

```python
from nautilus_trader.model.objects import Money

pnl_by_currency = {}
for position in cache.positions(instrument_id=instrument_id):
    if position.realized_pnl:
        c = position.realized_pnl.currency
        pnl_by_currency[c] = pnl_by_currency.get(c, 0.0) + position.realized_pnl.as_double()

for snapshot in cache.position_snapshots(instrument_id=instrument_id):
    if snapshot.realized_pnl:
        c = snapshot.realized_pnl.currency
        pnl_by_currency[c] = pnl_by_currency.get(c, 0.0) + snapshot.realized_pnl.as_double()

total_pnls = [Money(amount, c) for c, amount in pnl_by_currency.items()]
```

---

## Visualization (optional extra)

Requires `uv pip install "nautilus_trader[visualization]"`; `write_image` additionally needs `kaleido`.

```python
from nautilus_trader.analysis import create_tearsheet, create_equity_curve

engine.run()
create_tearsheet(engine, output_path="tearsheet.html")  # equity, drawdown, monthly heatmap, stats

returns = pd.Series([0.01, -0.005, 0.002],
                    index=pd.date_range("2024-01-01", periods=3, tz="UTC"))
fig = create_equity_curve(returns, title="My Strategy Equity")  # Plotly figure
fig.show()
fig.write_image("equity.png")  # needs kaleido
```

---

## Accounting quick reference

Account types: `AccountType.{Cash|Margin|Betting}`. Invariant on every `AccountBalance`: **`total == locked + free`** at currency precision.

| Type | Locks |
|---|---|
| `CashAccount` | Notional for pending orders (no leverage/margin). |
| `MarginAccount` | Initial margin for orders + maintenance margin for positions. |
| `BettingAccount` | Only the venue-required stake. |

`MarginAccount` holds **isolated** (per-instrument, concrete `InstrumentId`) and **cross** (account-wide, `instrument_id=None`, keyed by currency) margin in separate stores:

| Scope | Methods |
|---|---|
| Isolated | `margin(instrument_id)`, `margin_init(instrument_id)`, `margin_maint(instrument_id)`, `margins()`, `clear_margin(instrument_id)` |
| Cross | `margin_for_currency(currency)`, `account_margins()`, `clear_account_margin(currency)` |
| Totals | `total_margin_init(currency)`, `total_margin_maint(currency)` (sum across scopes) |

Margin math is pluggable via `set_margin_model(model)`. **`LeveragedMarginModel` is the default** (`margin = notional/leverage * instrument.margin_init`, crypto-style); `StandardMarginModel` uses fixed percentages (`margin = notional * instrument.margin_init`, traditional broker). Subclass `MarginModel` and implement `calculate_margin_init(...)` and `calculate_margin_maint(...)` for custom logic. See [accounting doc](https://nautilustrader.io/docs/md/latest/concepts/accounting.md).

---

## Gotchas

- **Singular `net_exposure()` returns `None` across multi-currency accounts.** Cross-currency aggregation with no `target_currency` is ambiguous → the single-value method returns `None`. Fix: pass `target_currency`, or use the plural `net_exposures()` per-currency dict.
- **`target_currency` conversion fails silently without xrate data.** Singular methods return `None` and log an error; plural methods **omit** the failed currency while still returning successful ones. Fix: ensure xrate data is available; check for `None` and expect possibly-missing dict keys.
- **Positions report without snapshots undercounts NETTING PnL.** Reopened positions store historical realized PnL in snapshots. Fix: use `trader.generate_positions_report()` (auto-includes) or pass `snapshots=cache.position_snapshots()`. HEDGING never uses snapshots.
- **Reading total PnL only from `cache.positions()` after a backtest misses realized PnL.** Closed/reopened positions' PnL lives in `cache.position_snapshots()`. Fix: sum `realized_pnl` across both, per currency.
- **No automatic multi-currency total.** Framework does not convert currencies; PnL is per settlement currency. Fix: aggregate per-currency, or supply your own xrates before summing.
- **`generate_account_report` requires a `Venue`.** Account reports are venue-scoped. Fix: `trader.generate_account_report(Venue("BINANCE"))` or `engine.trader.generate_account_report(engine.list_venues()[0])` (the report helpers are on `engine.trader`, not `engine`; `engine.list_venues()` is valid).
- **`generate_order_fills_report` excludes unfilled orders and uses datetime timestamps.** It filters `filled_qty > 0` and converts `ts_init`/`ts_last` to datetime. Fix: use `generate_orders_report` for the full set with raw `ts_*`; `generate_fills_report` for one row per fill.
- **Visualization helpers need optional deps.** `create_tearsheet`/`create_equity_curve` need `nautilus_trader[visualization]`; `write_image` also needs `kaleido`.
- **Unpriceable positions are silently excluded from valuation/equity.** Any position lacking mark/quote/trade/bar price is skipped. Fix: call `missing_price_instruments(venue)` and supply price data.
- **`unrealized_pnl` on a FLAT position ignores the price** and returns `Money(0, settlement_currency)`. Only interpret it for open positions.
- **Inverse-instrument PnL needs `base_currency`.** The inverse path panics without it and does not handle quanto contracts. Ensure inverse instruments define `base_currency`.
- **`MarginAccount.apply(event)` REPLACES margin stores** (both isolated and cross) — not a merge. Adapters emitting partial snapshots must include every live margin entry each update or lose the omitted ones.
- **`StandardMarginModel` is NOT the default** — `LeveragedMarginModel` is. Call `set_margin_model(StandardMarginModel())` explicitly for fixed-percentage broker behavior.
- **f64 PnL rounds amounts below ~1e-15 to zero.** For regulatory/audit exactness use `Decimal` types.

# Doc Map — Online NautilusTrader Docs (reciprocal markdown links)

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

This skill covers ~80% of Python tasks offline. When you need the other 20% — an
integration detail, an API signature, an edge case — escalate to the online source
below. **Every human doc page has a reciprocal raw‑markdown page**; prefer the
`/docs/md/…` links here (they are token‑cheap and agent‑friendly).

## URL conventions (memorize these)

| Want | URL pattern |
|---|---|
| Human doc page | `https://nautilustrader.io/docs/latest/<path>` |
| **Raw markdown (reciprocal)** | `https://nautilustrader.io/docs/md/latest/<path>.md` |
| Python API reference | `https://nautilustrader.io/docs/python-api-latest/` (e.g. `/trading.html`, `/model.html`, `/backtest.html`) |
| Rust API reference (docs.rs) | `https://docs.rs/nautilus-*` |
| Nightly (unreleased `develop`) | replace `/latest/` with `/nightly/` in any URL |
| Full LLM index | `https://nautilustrader.io/docs/llms.txt` |

**Pinning note:** version‑pinned markdown URLs (`/docs/md/v1.230.0/…`) currently
**404** — the site serves only `latest` and `nightly`. As of 2026‑07, `latest ==
v1.230.0`, so the links below are v1.230.0. NautilusTrader ships breaking API
changes between minor releases before v2.0; if your installed version differs,
confirm against the [release notes](https://github.com/nautechsystems/nautilus_trader/releases)
and the API reference for your version.

- **Source / releases:** https://github.com/nautechsystems/nautilus_trader
- **Release notes:** https://github.com/nautechsystems/nautilus_trader/releases

---

## Getting Started
- [Quickstart](https://nautilustrader.io/docs/md/latest/getting_started/quickstart.md)
- [Backtest (High-Level API)](https://nautilustrader.io/docs/md/latest/getting_started/backtest_high_level.md)
- [Backtest (Low-Level API)](https://nautilustrader.io/docs/md/latest/getting_started/backtest_low_level.md)
- [Installation](https://nautilustrader.io/docs/md/latest/getting_started/installation.md)

## Concepts
- [Overview](https://nautilustrader.io/docs/md/latest/concepts/overview.md)
- [Architecture](https://nautilustrader.io/docs/md/latest/concepts/architecture.md)
- [Strategies](https://nautilustrader.io/docs/md/latest/concepts/strategies.md)
- [Actors](https://nautilustrader.io/docs/md/latest/concepts/actors.md)
- [Data](https://nautilustrader.io/docs/md/latest/concepts/data.md)
- [Custom Data](https://nautilustrader.io/docs/md/latest/concepts/custom_data.md)
- [Value Types](https://nautilustrader.io/docs/md/latest/concepts/value_types.md)
- [Cache](https://nautilustrader.io/docs/md/latest/concepts/cache.md)
- [Message Bus](https://nautilustrader.io/docs/md/latest/concepts/message_bus.md)
- [Events](https://nautilustrader.io/docs/md/latest/concepts/events.md)
- [Execution](https://nautilustrader.io/docs/md/latest/concepts/execution.md)
- [Portfolio](https://nautilustrader.io/docs/md/latest/concepts/portfolio.md)
- [Positions](https://nautilustrader.io/docs/md/latest/concepts/positions.md)
- [Accounting](https://nautilustrader.io/docs/md/latest/concepts/accounting.md)
- [Backtesting](https://nautilustrader.io/docs/md/latest/concepts/backtesting.md)
- [Live Trading](https://nautilustrader.io/docs/md/latest/concepts/live.md)
- [Logging](https://nautilustrader.io/docs/md/latest/concepts/logging.md)
- [Configuration](https://nautilustrader.io/docs/md/latest/concepts/configuration.md)
- [Order Book](https://nautilustrader.io/docs/md/latest/concepts/order_book.md)
- [Reports](https://nautilustrader.io/docs/md/latest/concepts/reports.md)
- [Adapters](https://nautilustrader.io/docs/md/latest/concepts/adapters.md)
- [Synthetics](https://nautilustrader.io/docs/md/latest/concepts/synthetics.md)
- [Greeks](https://nautilustrader.io/docs/md/latest/concepts/greeks.md)
- [Options](https://nautilustrader.io/docs/md/latest/concepts/options.md)
- [Continuous Futures](https://nautilustrader.io/docs/md/latest/concepts/continuous_futures.md)
- [DST](https://nautilustrader.io/docs/md/latest/concepts/dst.md)
- [Event Sourcing](https://nautilustrader.io/docs/md/latest/concepts/event_sourcing.md)
- [Plugins](https://nautilustrader.io/docs/md/latest/concepts/plugins.md)
- [Rust](https://nautilustrader.io/docs/md/latest/concepts/rust.md)
- [Visualization](https://nautilustrader.io/docs/md/latest/concepts/visualization.md)

### Orders
- [Orders overview](https://nautilustrader.io/docs/md/latest/concepts/orders/index.md)
- [Market](https://nautilustrader.io/docs/md/latest/concepts/orders/market.md)
- [Limit](https://nautilustrader.io/docs/md/latest/concepts/orders/limit.md)
- [Stop-Market](https://nautilustrader.io/docs/md/latest/concepts/orders/stop_market.md)
- [Stop-Limit](https://nautilustrader.io/docs/md/latest/concepts/orders/stop_limit.md)
- [Market-To-Limit](https://nautilustrader.io/docs/md/latest/concepts/orders/market_to_limit.md)
- [Market-If-Touched](https://nautilustrader.io/docs/md/latest/concepts/orders/market_if_touched.md)
- [Limit-If-Touched](https://nautilustrader.io/docs/md/latest/concepts/orders/limit_if_touched.md)
- [Trailing-Stop-Market](https://nautilustrader.io/docs/md/latest/concepts/orders/trailing_stop_market.md)
- [Trailing-Stop-Limit](https://nautilustrader.io/docs/md/latest/concepts/orders/trailing_stop_limit.md)
- [Advanced orders](https://nautilustrader.io/docs/md/latest/concepts/orders/advanced.md)
- [Emulated orders](https://nautilustrader.io/docs/md/latest/concepts/orders/emulated.md)

### Instruments
- [Instruments overview](https://nautilustrader.io/docs/md/latest/concepts/instruments/index.md)
- [Currency Pair](https://nautilustrader.io/docs/md/latest/concepts/instruments/currency_pair.md)
- [Crypto Perpetual](https://nautilustrader.io/docs/md/latest/concepts/instruments/crypto_perpetual.md)
- [Crypto Future](https://nautilustrader.io/docs/md/latest/concepts/instruments/crypto_future.md)
- [Crypto Option](https://nautilustrader.io/docs/md/latest/concepts/instruments/crypto_option.md)
- [Perpetual Contract](https://nautilustrader.io/docs/md/latest/concepts/instruments/perpetual_contract.md)
- [Equity](https://nautilustrader.io/docs/md/latest/concepts/instruments/equity.md)
- [Futures Contract](https://nautilustrader.io/docs/md/latest/concepts/instruments/futures_contract.md)
- [Futures Spread](https://nautilustrader.io/docs/md/latest/concepts/instruments/futures_spread.md)
- [Option Contract](https://nautilustrader.io/docs/md/latest/concepts/instruments/option_contract.md)
- [Option Spread](https://nautilustrader.io/docs/md/latest/concepts/instruments/option_spread.md)
- [Betting Instrument](https://nautilustrader.io/docs/md/latest/concepts/instruments/betting_instrument.md)
- [Binary Option](https://nautilustrader.io/docs/md/latest/concepts/instruments/binary_option.md)
- [CFD](https://nautilustrader.io/docs/md/latest/concepts/instruments/cfd.md)
- [Commodity](https://nautilustrader.io/docs/md/latest/concepts/instruments/commodity.md)
- [Index Instrument](https://nautilustrader.io/docs/md/latest/concepts/instruments/index_instrument.md)
- [Synthetic Instrument](https://nautilustrader.io/docs/md/latest/concepts/instruments/synthetic_instrument.md)
- [Tokenized Asset](https://nautilustrader.io/docs/md/latest/concepts/instruments/tokenized_asset.md)

## How-To
- [Configure a Live Trading Node](https://nautilustrader.io/docs/md/latest/how_to/configure_live_trading.md)
- [Get Started with Lighter](https://nautilustrader.io/docs/md/latest/how_to/get_started_lighter.md)
- [Run a Backtest (Rust)](https://nautilustrader.io/docs/md/latest/how_to/run_rust_backtest.md)
- [Run Live Trading (Rust)](https://nautilustrader.io/docs/md/latest/how_to/run_rust_live_trading.md)
- [Write an Actor (Rust)](https://nautilustrader.io/docs/md/latest/how_to/write_rust_actor.md)
- [Write a Strategy (Rust)](https://nautilustrader.io/docs/md/latest/how_to/write_rust_strategy.md)

## Tutorials
- [Tutorials index](https://nautilustrader.io/docs/md/latest/tutorials/index.md)
- [Book Imbalance Backtest (Betfair)](https://nautilustrader.io/docs/md/latest/tutorials/backtest_book_imbalance_betfair.md)
- [Mean Reversion with Proxy FX Data (AX)](https://nautilustrader.io/docs/md/latest/tutorials/fx_mean_reversion_ax.md)
- [Gold Perpetual Book Imbalance (AX)](https://nautilustrader.io/docs/md/latest/tutorials/gold_book_imbalance_ax.md)
- [Grid Market Making + Deadman's Switch (BitMEX)](https://nautilustrader.io/docs/md/latest/tutorials/grid_market_maker_bitmex.md)
- [On-Chain Grid Market Making (dYdX)](https://nautilustrader.io/docs/md/latest/tutorials/grid_market_maker_dydx.md)
- [Hurst/VPIN Directional (Kraken Futures)](https://nautilustrader.io/docs/md/latest/tutorials/hurst_vpin_kraken.md)
- [Delta-Neutral Options (Bybit)](https://nautilustrader.io/docs/md/latest/tutorials/delta_neutral_options_bybit.md)
- [Delta-Neutral Options (Derive)](https://nautilustrader.io/docs/md/latest/tutorials/delta_neutral_options_derive.md)
- [Options Data and Greeks (Bybit)](https://nautilustrader.io/docs/md/latest/tutorials/options_data_bybit.md)
- [Composite MM on Lighter RWA w/ Databento NVDA](https://nautilustrader.io/docs/md/latest/tutorials/lighter_rwa_composite_mm.md)

## Integrations
- [Integrations index](https://nautilustrader.io/docs/md/latest/integrations/index.md)
- [Binance](https://nautilustrader.io/docs/md/latest/integrations/binance.md)
- [Bybit](https://nautilustrader.io/docs/md/latest/integrations/bybit.md)
- [Interactive Brokers](https://nautilustrader.io/docs/md/latest/integrations/ib.md)
- [Databento](https://nautilustrader.io/docs/md/latest/integrations/databento.md)
- [Coinbase](https://nautilustrader.io/docs/md/latest/integrations/coinbase.md)
- [OKX](https://nautilustrader.io/docs/md/latest/integrations/okx.md)
- [BitMEX](https://nautilustrader.io/docs/md/latest/integrations/bitmex.md)
- [Kraken](https://nautilustrader.io/docs/md/latest/integrations/kraken.md)
- [dYdX](https://nautilustrader.io/docs/md/latest/integrations/dydx.md)
- [Hyperliquid](https://nautilustrader.io/docs/md/latest/integrations/hyperliquid.md)
- [Deribit](https://nautilustrader.io/docs/md/latest/integrations/deribit.md)
- [Derive](https://nautilustrader.io/docs/md/latest/integrations/derive.md)
- [Polymarket](https://nautilustrader.io/docs/md/latest/integrations/polymarket.md)
- [Betfair](https://nautilustrader.io/docs/md/latest/integrations/betfair.md)
- [Betfair v2](https://nautilustrader.io/docs/md/latest/integrations/betfair_v2.md)
- [Blockchain](https://nautilustrader.io/docs/md/latest/integrations/blockchain.md)
- [Tardis](https://nautilustrader.io/docs/md/latest/integrations/tardis.md)
- [Lighter](https://nautilustrader.io/docs/md/latest/integrations/lighter.md)
- [AX Exchange](https://nautilustrader.io/docs/md/latest/integrations/architect_ax.md)

## Developer Guide
- [Developer Guide index](https://nautilustrader.io/docs/md/latest/developer_guide/index.mdx)
- [Adapters](https://nautilustrader.io/docs/md/latest/developer_guide/adapters.md)
- [Coding Standards](https://nautilustrader.io/docs/md/latest/developer_guide/coding_standards.md)
- [Design Principles](https://nautilustrader.io/docs/md/latest/developer_guide/design_principles.md)
- [Environment Setup](https://nautilustrader.io/docs/md/latest/developer_guide/environment_setup.md)
- [Testing](https://nautilustrader.io/docs/md/latest/developer_guide/testing.md)
- [Rust](https://nautilustrader.io/docs/md/latest/developer_guide/rust.md)
- [Python](https://nautilustrader.io/docs/md/latest/developer_guide/python.md)

---

## This skill's reference files → source pages

| Reference file | Primary online sources |
|---|---|
| [architecture.md](architecture.md) | concepts/overview, architecture, configuration, logging |
| [value-types.md](value-types.md) | concepts/value_types |
| [data.md](data.md) | concepts/data, order_book |
| [custom-data.md](custom-data.md) | concepts/custom_data |
| [instruments.md](instruments.md) | concepts/instruments/*, synthetics, greeks |
| [strategies.md](strategies.md) | concepts/strategies |
| [actors.md](actors.md) | concepts/actors |
| [orders.md](orders.md) | concepts/orders/* |
| [execution.md](execution.md) | concepts/execution, positions, accounting |
| [message-bus.md](message-bus.md) | concepts/message_bus, cache, events |
| [backtesting.md](backtesting.md) | concepts/backtesting, getting_started/backtest_* |
| [data-catalog.md](data-catalog.md) | getting_started/backtest_*, concepts/data |
| [portfolio-and-reports.md](portfolio-and-reports.md) | concepts/portfolio, reports, accounting |
| [live-trading.md](live-trading.md) | concepts/live, how_to/configure_live_trading, adapters, integrations |
| [gotchas.md](gotchas.md) | cross-cutting (all of the above) |

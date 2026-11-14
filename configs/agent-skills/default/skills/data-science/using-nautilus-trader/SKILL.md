---
name: using-nautilus-trader
description: Use when building NautilusTrader strategies, custom data, backtests, or live nodes. Covers framework-specific delivery, simulation, accounting, and reconciliation traps.
---

# NautilusTrader

NautilusTrader is an event-driven trading framework whose strategy components can run against historical or live data. Correct results depend on data delivery, event ordering, simulated execution, and reconciliation; a working callback alone does not establish parity with a venue. Check the installed version against the [upstream documentation](https://nautilustrader.io/docs/) for current APIs and defaults.

| Task | Reference |
|---|---|
| Actors, strategies, data subscriptions, instruments and cache | [Components and data](references/data.md) |
| Define, route and persist custom data | [Custom data](references/custom-data.md) |
| Configure replay and assess simulated execution | [Backtesting](references/backtesting.md) |
| Orders, positions, valuation and reports | [Execution and accounting](references/execution.md) |
| Live nodes, ambiguous commands and reconciliation | [Live trading](references/live-trading.md) |

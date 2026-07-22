# Execution: Engine, Algorithms, OMS, Positions & Accounting

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/execution.md
- https://nautilustrader.io/docs/md/latest/concepts/positions.md
- https://nautilustrader.io/docs/md/latest/concepts/accounting.md

## TL;DR

A `Strategy` command (`submit_order`, `modify_order`, `cancel_order`, …) is published on the message bus and routed by order characteristics: emulated orders go to the `OrderEmulator`; orders with an `exec_algorithm_id` go to that `ExecAlgorithm`; everything else flows to the `RiskEngine`. The chain is **Strategy → (Emulator / ExecAlgorithm) → RiskEngine → ExecutionEngine → ExecutionClient (venue)**. The venue returns events (`OrderAccepted`, `OrderFilled`, `OrderRejected`, …) back up the same bus. The `ExecutionEngine` turns fills into `Position` updates. **`OmsType` (NETTING vs HEDGING) decides how fills aggregate into positions**; **`AccountType` (CASH / MARGIN / BETTING) decides how funds are locked.** Positions are always *derived from fills* — never bootstrapped. Reconciliation is covered in [live-trading](live-trading.md).

## Command flow (Strategy → venue)

`Strategy` command methods (all publish on the message bus, do not block):

| Method | Purpose |
|---|---|
| `submit_order(order, position_id=None, client_id=None)` | Submit one order; routed to emulator / exec-algo / risk engine. |
| `submit_order_list(order_list, position_id=None, client_id=None)` | Submit an `OrderList` (e.g. bracket) as one atomic command. |
| `modify_order(order, quantity=None, price=None, trigger_price=None)` | Modify a working order in place. |
| `cancel_order(order)` / `cancel_orders(orders)` / `cancel_all_orders(instrument_id, order_side=...)` | Cancel one / a batch / all open orders (`instrument_id` required). |
| `close_position(position)` / `close_all_positions(instrument_id, position_side=...)` | Flatten a position / all positions (submits offsetting MARKET orders). |
| `query_account(...)` / `query_order(order)` | Request fresh account / order state from the venue. |

Routing components:
- **`OrderEmulator`** — holds emulated orders locally until their trigger condition is met, then releases them onward.
- **`RiskEngine`** — validates the submit/modify path: price/quantity precision, GTD expiry, `reduce_only`, notional/quantity bounds, free balance/margin, rate limits, and trading state. Internal rejections are **`OrderDenied`** events carrying a standardized `reason` string (a plain `str`, not a named enum — e.g. `QUANTITY_EXCEEDS_MAXIMUM`, `MARGIN_EXCEEDS_FREE_BALANCE`, `TRADING_HALTED`), which are distinct from venue `OrderRejected` events (those pass through unchanged).
- **`ExecutionEngine`** — processes fill events and the order lifecycle; assigns/overrides `position_id` when strategy and venue OMS types differ.
- **`ExecutionClient` / `LiveExecutionClient`** — the venue-facing interface. `LiveExecutionEngine` pre-filters on `trade_id` before generating fill events and drives reconciliation.

Key `RiskEngineConfig` field: `max_notional_per_order` — max notional allowed per order, enforced on the submit path.

## OMS types: NETTING vs HEDGING

`OmsType.NETTING | OmsType.HEDGING | OmsType.UNSPECIFIED` controls how fills aggregate into positions. Both a **strategy-level** and a **venue-level** OMS type exist and interact.

| | NETTING | HEDGING |
|---|---|---|
| Positions per instrument | Exactly one, aggregating all fills | One new `Position` per opening fill |
| `position_id` | Deterministic: `{instrument_id}-{strategy_id}` | Unique per position |
| On close then new fill | Snapshots closed state, then reopens *same* `PositionId` | Closed positions stay in cache; new fills make **new** positions |
| Margin | Single netted position | Each position consumes margin independently |
| Custom `position_id` | **Invalid** — engine overrides it | Allowed (HEDGING semantics) |

NETTING `position_id` grammar:

| Format | Examples |
|---|---|
| `{instrument_id}-{strategy_id}` | `ETHUSDT.BINANCE-EMACross-000`, `BTCUSDT.BINANCE-MyStrat-001` |

Under NETTING, when a *closed* position receives a new fill, the `ExecutionEngine` **snapshots** the closed state before resetting, and the `Portfolio` aggregates realized PnL across all snapshots sharing that `PositionId` — so closed-position PnL is never lost on reopen. This is distinct from the `snapshot_positions` telemetry config (see Accounting/config below).

## Position lifecycle & the Position object

Positions open, flip, and close as fills aggregate into a **net signed quantity**:

```python
signed_qty = +100  # LONG  (initial BUY 100 @ $50)
signed_qty = -50   # SHORT (subsequent SELL 150 @ $55 flips it)
signed_qty = 0     # FLAT  (final BUY 50 @ $52 closes it)
```

Fetch positions from the `Cache` inside an actor/strategy:

```python
position = self.cache.position(position_id)
positions = self.cache.positions(instrument_id=instrument_id)
```

`Position` API:

| Member | Kind | Notes |
|---|---|---|
| `position.side` | prop → `PositionSide` | `LONG`, `SHORT`, or `FLAT`. |
| `position.signed_qty` | prop | Net signed qty (+long / −short / 0 flat). |
| `position.realized_pnl` | prop | Realized PnL on the closed portion. |
| `position.unrealized_pnl(price)` | method | PnL vs supplied price; returns `Money(0, settlement_currency)` when FLAT. |
| `position.total_pnl(price)` | method | `realized_pnl + unrealized_pnl(price)`. |
| `position.commissions()` | method | `list[Money]` of accrued commissions. |
| `position.notional_value(price)` | method | Notional as `Money`. |
| `position.events` | prop | Full chronological fill-event history (reconciliation). |
| `position.trade_ids` | prop | Venue trade IDs (match against broker statements). |
| `position.adjustments` | prop | `PositionAdjusted` events (`COMMISSION`, `FUNDING`) applied outside normal fills. |

Choose the price input for conservatism: `unrealized_pnl(bid_price)` is conservative for LONG, `unrealized_pnl(ask_price)` for SHORT, `unrealized_pnl(last_price)` for last-traded.

PnL formulas:

```python
# Standard instruments
realized_pnl = (exit_price - entry_price) * closed_quantity * multiplier

# Inverse instruments (side-aware)
# LONG:  closed_quantity * multiplier * (1/entry_price - 1/exit_price)
# SHORT: closed_quantity * multiplier * (1/exit_price - 1/entry_price)
```

Inverse instruments require a `base_currency` (the inverse path panics without one; quanto contracts are not handled). Positions are **not** created for spread instruments.

## Fill handling

- `Order.apply(event)` applies an event to the order model.
- `Order.is_duplicate_fill(...)` compares `trade_id`, `order_side`, `last_px`, `last_qty` to detect exact duplicate fills — an exact duplicate is skipped gracefully; any *other* mismatch raises.
- `LiveExecutionEngine` pre-filters incoming executions on `trade_id` before generating a fill.
- **Overfills**: `LiveExecEngineConfig.allow_overfills` (default `False`). If `False`, cumulative fills exceeding order quantity are rejected; if `True`, a warning is logged and the excess is tracked in `overfill_qty`.

## Execution algorithms

`ExecAlgorithm(Actor)` is the base class for algorithms that spawn secondary child orders from a primary order. Route an order to it by setting its `exec_algorithm_id` (and optional `exec_algorithm_params`).

| Member | Purpose |
|---|---|
| `on_order(self, order: Order) -> None` | Handler invoked when an order is routed to the algorithm. |
| `spawn_market(...)` | Spawn a `MARKET` child order from the primary. |
| `spawn_market_to_limit(...)` | Spawn a `MARKET_TO_LIMIT` child order. |
| `spawn_limit(...)` | Spawn a `LIMIT` child order. |

`exec_algorithm_params` is an **untyped `dict[str, Any]`** — the framework does *not* type-check it; validate every key/value inside your algorithm.

Query spawned/algo orders from the `Cache`:

```python
Cache.orders_for_exec_algorithm(exec_algorithm_id, venue=None, instrument_id=None,
                                strategy_id=None, side=OrderSide.NO_ORDER_SIDE,
                                account_id=None) -> list[Order]
Cache.orders_for_exec_spawn(exec_spawn_id: ClientOrderId) -> list[Order]  # primary + all spawns
```

Spawned order `client_order_id` grammar:

| Format | Examples |
|---|---|
| `{exec_spawn_id}-E{spawn_sequence}` | `O-20240101-000-001-E1`, `O-20240101-000-001-E2` |

**Built-in TWAP** (`nautilus_trader/examples/algorithms/twap.py`, `TWAPExecAlgorithm`) spreads execution evenly over a horizon via spawned child orders. Params: `horizon_secs`, `interval_secs`. Wiring it into a strategy config:

```python
from decimal import Decimal
from nautilus_trader.model.data import BarType
from nautilus_trader.test_kit.providers import TestInstrumentProvider
from nautilus_trader.examples.strategies.ema_cross_twap import (
    EMACrossTWAP,
    EMACrossTWAPConfig,
)

config = EMACrossTWAPConfig(
    instrument_id=TestInstrumentProvider.ethusdt_binance().id,
    bar_type=BarType.from_str("ETHUSDT.BINANCE-250-TICK-LAST-INTERNAL"),
    trade_size=Decimal("0.05"),
    fast_ema_period=10,
    slow_ema_period=20,
    twap_horizon_secs=10.0,     # total span over which child orders are spread
    twap_interval_secs=2.5,     # spacing between spawned child orders
)

strategy = EMACrossTWAP(config=config)
```

`reduce_primary=True` on a spawn requires spawned quantity ≤ primary `leaves_qty`; over-large spawns are denied/rejected and auto-restore the primary quantity.

## Accounting: AccountType CASH vs MARGIN (vs BETTING)

`AccountType.{Cash|Margin|Betting}` selects how funds are locked:

| Account type | What it locks |
|---|---|
| `Cash` (`CashAccount`) | Notional for pending orders. No leverage, no margin. |
| `Margin` (`MarginAccount`) | Initial margin for orders + maintenance margin for positions. Per-instrument (isolated) *and* account-wide (cross) scopes. |
| `Betting` (`BettingAccount`) | Only the venue-required stake. Leverage/margin N/A. |

Core invariant: **`total == locked + free`** at currency precision. `AccountBalance(total, locked, free)` (single currency); `MarginBalance(initial, maintenance, currency, instrument_id)`.

`MarginAccount` query API (isolated vs cross scopes):

| Method | Scope |
|---|---|
| `margin(instrument_id)` / `margin_init(instrument_id)` / `margin_maint(instrument_id)` / `margins()` | Per-instrument (isolated). |
| `margin_for_currency(currency)` / `account_margins()` | Account-wide (cross), keyed by currency; `instrument_id=None`. |
| `total_margin_init(currency)` / `total_margin_maint(currency)` | Sum across both scopes. |
| `clear_margin(instrument_id)` / `clear_account_margin(currency)` | Remove an entry. |
| `apply(event: AccountState)` | **Replaces** both margin stores from the event (not a merge). |
| `set_margin_model(model)` | Install a `MarginModel`. |

Margin models (pluggable): `MarginModel.calculate_margin_init(instrument, quantity, price, leverage, use_quote_for_inverse=False)` and `calculate_margin_maint(instrument, side, quantity, price, leverage, use_quote_for_inverse=False)`.

| Model | Formula |
|---|---|
| `LeveragedMarginModel` (**default**) | `(notional_value / leverage) * instrument.margin_init` — crypto-exchange style. |
| `StandardMarginModel` | `notional_value * instrument.margin_init` — fixed %, traditional broker. |

```python
from nautilus_trader.backtest.models import LeveragedMarginModel, StandardMarginModel
account.set_margin_model(StandardMarginModel())  # explicit fixed-% broker behavior
```

Reduce-only orders **do not** lock funds (cash) or contribute to initial margin (margin) — they only reduce exposure.

`Portfolio` account-level queries (all accept `venue=`/`account_id=`, return `dict` keyed by `Currency` or `InstrumentId`): `margins_init`, `margins_maint`, `unrealized_pnls`, `realized_pnls`, `total_pnls`, `net_exposures`, `equity`, `account(venue)`.

Position-telemetry config (Live/ExecEngine): `snapshot_positions` (bool) + `snapshot_positions_interval_secs` periodically record **open**-position state for telemetry — this is *not* the historical close/reopen snapshot mechanism and does not preserve closed PnL.

## Live-only execution config (`LiveExecEngineConfig`)

| Field | Default | Meaning |
|---|---|---|
| `allow_overfills` | `False` | Reject cumulative overfills, or log-and-track excess in `overfill_qty`. |
| `open_check_threshold_ms` | `5000` | Threshold for checking open orders; below venue latency → overfill race risk. |
| `inflight_check_threshold_ms` | `5000` | Threshold for in-flight orders; below venue latency → overfill race risk. |
| `open_check_interval_secs` | — | Interval for open-order checks. |
| `position_check_interval_secs` | — | Interval for position checks. |
| `own_books_audit_interval_secs` | — | Interval for auditing own order books. |
| `reconciliation_startup_delay_secs` | `10` | Delay before startup reconciliation; lowering → race risk. |

Reconciliation report types (positions are reconstructed from fills, never bootstrapped) — full detail in [live-trading](live-trading.md):

| Report | Behavior |
|---|---|
| `OrderStatusReport` | Standalone order-state update; can *infer* a fill from `avg_px`/`filled_qty`. |
| `FillReport` | Standalone execution; creates external order and applies real fill, preserving `trade_id`. |
| `ExecutionMassStatus` | Venue mass-status bundle grouping per-instrument `order_reports` + `fill_reports` + `position_reports`; engine reconciles order state, applies supplied fills, and infers residual. |
| `PositionStatusReport` | Position snapshot — **logged only**; does not bootstrap positions. |

## Gotchas

- **Custom `position_id` under NETTING** → invalid; there is one position per instrument and the engine overrides it with `{instrument_id}-{strategy_id}`. Let the engine assign it; only set custom `position_id` where HEDGING applies.
- **Assuming HEDGING nets/reopens like NETTING** → each HEDGING position has a unique `PositionId`, does *not* reopen, and consumes margin independently. Track concurrent LONG/SHORT positions by distinct `PositionId`.
- **Trusting the requested OMS at the venue** → some venues net regardless (e.g. Binance futures must stay in **BOTH** mode; LONG/SHORT hedge mode breaks the single-netting-position assumption). Verify venue support; keep strategy and venue OMS aligned.
- **Expecting closed-PnL loss on NETTING reopen** → it is preserved via automatic snapshots; `Portfolio` sums realized PnL across snapshots of the same `PositionId`.
- **Confusing `snapshot_positions` with the close/reopen snapshot** → the former is *open*-position telemetry only; historical snapshotting is what preserves closed PnL.
- **`unrealized_pnl` on a FLAT position** → always `Money(0, settlement_currency)` regardless of price. Only interpret it for open positions.
- **Inverse PnL without `base_currency`** → the inverse path panics; quanto contracts return quote (not settlement) currency. Set `base_currency`; don't use this path for quanto.
- **`exec_algorithm_params` treated as validated** → it's an untyped `dict[str, Any]`; validate every key/value inside your algorithm.
- **Spawn qty > primary `leaves_qty` with `reduce_primary=True`** → denied/rejected (auto-restores primary). Keep spawns within `leaves_qty`.
- **Including `PENDING_CANCEL` when selecting own-book orders to cancel** → re-issues cancels, causing order-state explosion. Exclude `PENDING_CANCEL`.
- **`MarginAccount.apply()` assumed to merge** → it *replaces* both margin stores from the event. Adapters emitting partial snapshots must include **every** live margin entry each update or omitted ones are dropped.
- **Counting reduce-only orders toward locked funds/initial margin** → they don't lock; exclude them when reasoning about available funds.
- **`AccountBalance` where `total != locked + free`** → invariant violation. In Rust adapters use `from_total_and_locked` / `from_total_and_free` to derive the third field safely.
- **Assuming `StandardMarginModel` is the default** → `LeveragedMarginModel` is. Call `set_margin_model(StandardMarginModel())` explicitly for fixed-% behavior.
- **Aggressive live-reconciliation timing** → lowering `open_check_threshold_ms` / `inflight_check_threshold_ms` below venue latency, or lowering `reconciliation_startup_delay_secs`, raises overfill/race risk. Keep thresholds above expected venue latency.
- **`allow_overfills=False` without a reconciliation plan** → rejected fills leave local/venue position discrepancies; rely on reconciliation to resolve. Set `True` only to log-and-track in `overfill_qty`.
- **Expecting `PositionStatusReport` to bootstrap positions** → it's logged only; positions come from `FillReport` / `OrderStatusReport` (bundled per-venue in `ExecutionMassStatus`).
- **Internal denials assumed to be venue reject codes** → `OrderDenied` carries a standardized `reason` string (a plain `str`, e.g. `QUANTITY_EXCEEDS_MAXIMUM`); handle it separately from venue `OrderRejected`.
- **Relying on f64 PnL for audit arithmetic** → amounts below ~1e-15 round to zero; use `Decimal` for regulatory/audit exactness.
- **Expecting `Position` objects for spreads** → none are created; contingent orders can trigger for spreads but without position linkage.

## See also

- [orders](orders.md) — order types, `OrderList`/bracket, emulation, `reduce_only`.
- [strategies](strategies.md) / [actors](actors.md) — command methods and event handlers.
- [live-trading](live-trading.md) — reconciliation detail and live engine config.
- [portfolio-and-reports](portfolio-and-reports.md) — `Portfolio` queries and PnL reporting.
- [gotchas](gotchas.md) · master [SKILL.md](../SKILL.md).

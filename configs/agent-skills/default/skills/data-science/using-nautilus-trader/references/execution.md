# Execution and accounting

- Construct order values to the instrument's precision and increments; the risk engine can deny invalid orders instead of rounding. `OrderDenied` is a local pre-submission outcome, distinct from a venue `OrderRejected`.
- An emulated order can change type and object on release. Re-query the cache by client order ID rather than holding an old Python reference. Risk checks can deny the order on submission or release.
- Handle denied or rejected protective bracket children: an entry may fill while a protective leg is absent. Backtest OTO children can release on partial parent fills; `oto_trigger_mode="FULL"` waits for a full parent fill, potentially leaving an unprotected window.
- A netting position can close and later reopen under the same ID. Historical realized PnL is preserved in position snapshots; custom reports must include them, or use the trader positions report. Open-position telemetry snapshots are a separate mechanism.
- Check venue and strategy OMS semantics rather than assuming requested hedging is supported. Different strategies sharing an account and instrument can face account-level netting during reconciliation.
- Portfolio valuation can skip positions without a usable price. Check `missing_price_instruments`; failed currency conversion can yield `None` or missing keys rather than a complete total. Aggregate currencies only with appropriate exchange rates.
- `MarginAccount.apply()` replaces margin stores rather than merging partial updates. Adapters must include all live margin entries in each update or omitted entries disappear.
- Execution algorithm parameters are untyped; validate them in the algorithm. Avoid reissuing cancellation for orders already pending cancel.
- Report types differ: order fills are filtered orders, while fills reports contain individual fill events. Capture reports before disposing the engine.

- `modify_order` needs a changed quantity, price or trigger; an execution-algorithm-controlled order can be canceled but not directly modified. During `market_exit`, non-reduce-only orders are denied; check `is_exiting()` before ordinary order logic.
- When managing GTD expiry in the strategy, avoid conflicting native venue GTD expiry; check the adapter's `use_gtd` setting. Validate supported order types and instructions against the adapter before relying on emulation or venue submission.
- A mixed-instrument contingent order list can be misrouted or rejected by position-based risk checks. Keep linked orders on one instrument when relying on those checks.
- Inverse-instrument PnL requires `base_currency`; the inverse path does not handle quanto contracts. Validate settlement math for the installed version and instrument.
- Select `StandardMarginModel` explicitly for fixed-percentage broker behavior; check whether `LeveragedMarginModel` is the default in the installed version.
- `engine.get_result()` exposes `stats_pnls` and `stats_returns`; general statistics come from `engine.portfolio.analyzer.get_performance_stats_general()`. Reports are on `engine.trader`; account reports require the venue.

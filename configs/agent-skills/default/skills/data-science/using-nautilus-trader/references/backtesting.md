# Backtesting

Use `BacktestEngine` for direct in-memory control and `BacktestNode` for catalog-backed, config-driven runs. Neither removes the need to establish that simulated data and fills represent the intended experiment.

- Bar execution requires a bar's initialization timestamp to reflect when the completed bar is available. Feeding a completed bar at its open introduces look-ahead. Confirm timestamp conventions and adjust the data before replay.
- Match venue book type to data: L2/L3 matching needs book deltas; quotes and bars alone do not update that book. L1 matching does not use deltas as L2/L3 does. Validate actual fills, not just strategy callbacks.
- Historical book depth is immutable; without liquidity consumption, simulated orders can repeatedly consume the same displayed liquidity. Enable the appropriate setting when modeling consumption, and check custom fill models separately.
- OHLC bars do not reveal the intrabar path. High/low ordering changes which contingent order executes first; adaptive ordering is still an assumption, not observed tick history.
- Trade-tick matching concerns the opposite side of the aggressor. Check the configured fill model, latency, fees, order type and venue behavior before interpreting performance.
- Add venue and instrument definitions before their data. For many data batches, use `add_data(..., sort=False)` and call `sort_data()` before running; repeated full-stream sorts are costly. Iterator inputs must yield batches, not individual items.
- In manual streaming runs, finish with `end()` to finalize the run. `reset()` retains data, venues, instruments and components; explicitly clear what should not carry into the next run. Capture reports and state before disposal.
- In a replay qualification, distinguish simulated delivery and order delays from measured physical latency. Check the real engine and accounting behavior with bounded fixtures, including failure after fills; compare cached orders, fills, positions, account state and delivered callbacks before disposal. For parity, compare clocks, fills, settlement and readouts, normalizing generated IDs only in comparison copies.

## Wiring and version-sensitive settings

Low-level setup order is `add_venue` → `add_instrument` → `add_data` → `add_strategy`/`add_actor` → `run`. `add_instrument` takes an instrument object; strategy configuration generally refers to its ID. For a replacement strategy after `reset()`, call `clear_strategies()` before adding the new one.

For catalog-driven runs, put `ImportableStrategyConfig(strategy_path="module:Class", config_path="module:Config", config={...})` in `BacktestEngineConfig(strategies=[...])`, then pass that engine config, `BacktestVenueConfig` entries and `BacktestDataConfig` entries to `BacktestRunConfig`; run `BacktestNode(configs=[run_config]).run()`. Venue config uses strings such as `"NETTING"` and `"100000 USD"` rather than the low-level enum and `Money` objects. Use `catalog_path=str(path)` and string-form bar types in importable config dictionaries. Check signatures for the installed version.

For manual streaming: add each batch, call `run(streaming=True)`, then `clear_data()` before adding the next batch; call `end()` once after the final batch. For `add_data_iterator(name, generator)`, each yield is a batch.

- To correct open-stamped bars, use the relevant adapter's `bars_timestamp_on_close` setting or a `ts_init_delta` equal to the bar duration. Confirm the actual result before replay.
- `liquidity_consumption=True` tracks consumed displayed liquidity; custom fill-model synthetic books must track their own consumption. `bar_adaptive_high_low_ordering=True` changes the assumed bar path, not the observed data.
- `Bar.volume` must be in base-currency units; convert quote-currency volume before loading. Match data price/size precision to the instrument.
- The engine reads the first data point before start-time timers. Data added by a start-time timer should have timestamps strictly after the start time. Fill-reactive logic should not depend on post-shutdown callbacks from `on_stop`.

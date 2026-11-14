# Live trading and reconciliation

- A timeout, disconnect or other ambiguous command failure is not proof of rejection. The order may still be in flight or live at the venue; resolve it through venue updates and reconciliation before retrying or assuming exposure is absent.
- Register client factories before building the node and ensure instruments are loaded before subscribing. Keep callback work short: blocking the event loop delays market data, fills and submissions.
- Startup reconciliation and ongoing open-order and position checks are distinct. Check the installed version's defaults and configure continuous checks when needed; overly short thresholds relative to venue latency can create false missing-order or overfill races.
- Choose a reconciliation lookback that covers relevant executions and retain execution events. A truncated venue history can reconcile alignment while losing information.
- Venue account positions may net across strategies; reconcile at account and instrument scope rather than assuming strategy-local caches map one-to-one to venue positions.
- Do not assume position status alone reconstructs all position history: fills and order reports matter. Inspect reconciliation output and distinguish venue-originated orders from synthetic alignment orders.
- Long-lived nodes retain state unless configured to purge it. Database purging deletes persisted state too; review retention and recovery requirements before enabling it.
- A live node in an interactive notebook can have event-loop and operational-monitoring conflicts. Use a managed standalone process when those conflicts cannot be controlled; avoid concurrent nodes sharing process-global state.
- Logging initialization is process-global; when running sequential engines, keep the first engine's log guard alive across the loop rather than reinitializing logging.
- On Windows, asyncio signal handlers are unavailable; handle interruption explicitly and stop and dispose the node in a `finally` block.

## Node and adapter wiring

Configure `TradingNodeConfig(data_clients={KEY: DataClientConfig(...)}, exec_clients={KEY: ExecClientConfig(...)})` with each adapter's typed config. A plain dict may be decoded as the base client config and reject adapter-specific keys. Configure the adapter's `InstrumentProviderConfig(load_all=True)` or `load_ids` before subscribing; availability and credentials are adapter-specific.

```python
from nautilus_trader.live.node import TradingNode

node = TradingNode(config=config)
node.add_data_client_factory(KEY, DataClientFactory)
node.add_exec_client_factory(KEY, ExecClientFactory)  # if this adapter supports execution
node.build()
try:
    node.run()
finally:
    try:
        node.stop()
    finally:
        node.dispose()
```

Use the adapter's actual key and factory classes; some adapters provide data only. Secrets may be supplied through adapter-supported environment variables rather than hard-coded config.

`LiveExecEngineConfig(open_check_interval_secs=..., position_check_interval_secs=...)` enables the two continuous checks; check their defaults in the installed version. `reconciliation_lookback_mins` bounds requested history. `graceful_shutdown_on_exception=True` selects graceful shutdown on unhandled execution-queue exceptions; it is an execution-engine setting, not a node-level setting.

`VENUE` marks an external order discovered at the venue; `RECONCILIATION` marks a synthetic alignment order. Unclaimed external orders retain strategy ID `EXTERNAL`; `StrategyConfig.external_order_claims` allows a strategy to claim activity for an instrument. Fills may precede order status reports, so do not assume their arrival order.

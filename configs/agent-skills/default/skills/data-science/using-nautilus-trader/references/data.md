# Components and data

- Framework handles such as the clock, logger and cache are wired after component registration. Initialize ordinary state in the constructor and use framework services from `on_start` onward.
- Historical requests deliver through `on_historical_data`; subscriptions deliver through the corresponding streaming handler. When sequence validation is enabled and history is requested before live bars, subscribe in the request completion callback to avoid a history/live race.
- Register indicators before requesting historical bars or subscribing, and check warm-up before using their values. Load the instrument into the cache before subscribing.
- Use the component clock for strategy timing during replay. A timer without an explicit callback dispatches to `on_event`; clean up active timers when stopping. A due alert may already have left `timer_names` while its callback is queued, so check membership before cancellation and clear local bookkeeping independently.
- Distinct strategy instances need distinct strategy IDs; key mutable state by instrument when a single instance handles multiple instruments. `StrategyConfig` subclasses with required fields after defaulted inherited fields need keyword-only fields.
- `BarType` distinguishes internal aggregation from externally supplied bars. Confirm whether bar timestamps represent open or close; they are not interchangeable for execution.
- An order-book delta group needs `F_LAST` on its final delta, including a clear-only snapshot, or buffered consumers may wait indefinitely.
- Cache market-data index zero is the newest item, not the oldest. An order book is maintained separately from the quote/trade cache; quotes alone do not imply an initialized book.
- Build exact prices and quantities from decimal strings or appropriate instrument helpers, and check instrument precision and increments: risk validation may deny an order rather than round it. Value-type arithmetic can return a Python numeric type rather than the original Nautilus type.
- Model derivatives with their actual instrument type and settlement conventions rather than as spot pairs merely because their symbols look similar. Synthetic instruments are analytical constructs; trade their real components.
- Catalogs need instrument definitions as well as market data. Keep files spanning a precision change separate; serialized precision is part of the data representation. Overlapping writes are rejected by default, and range deletion is permanent: verify the intended range and back up before deleting.
- Register serializers for external message-bus custom types; unregistered inbound types can be skipped. Custom data routing and persistence have additional requirements in [custom-data.md](custom-data.md).

## Bars, catalog and messaging

- Standard bar strings use `{instrument_id}-{step}-{aggregation}-{price_type}-{INTERNAL|EXTERNAL}`, e.g. `AAPL.XNAS-5-MINUTE-LAST-INTERNAL`. For composite bars `target@source`, the target must be `INTERNAL`. Time-bar steps must divide their parent unit; information-driven bars requiring aggressor side need trades rather than quotes.
- The v1 wranglers, including `QuoteTickDataWrangler(instrument).process(df)`, produce Cython data for `BacktestEngine`. Sort the UTC-indexed DataFrame first. PyO3/v2 wrangler output is not interchangeable with v1 engine input; convert it or use v1.
- `ParquetDataCatalog.from_env()` appends `/catalog` to `NAUTILUS_PATH`; set the variable to its parent. Write a single instrument as `catalog.write_data([instrument])`, then write the data. Intentional overlapping writes require `skip_disjoint_check=True`; verify duplicate semantics before using it.
- `ts_event` is source time and `ts_init` is initialization/receipt time. Clock skew can make `ts_init < ts_event`; their difference is not necessarily physical latency.
- Signals carry a single `int`, `float`, or `str`; the signal name is not exposed in `on_signal`. Encode any discriminator in the value, or use custom data for structured payloads. `data.response` is a capture channel, not the correlated request/response reply path.
- For external Redis streams, `MessageBusConfig(database=DatabaseConfig(type="redis", ...))` configures the backing database; `types_filter` excludes types, and `stream_per_topic=False` avoids wildcard-stream limitations. Configure `LiveDataEngineConfig.external_clients` on a consumer to avoid duplicate subscriptions and republish inbound types.
- `cache.add(key, value)` accepts bytes; serialize objects explicitly. Instrument purging is not automatic, and `purge_instrument` refuses instruments with working orders or open positions.
- A specific order or position handler can be followed by its category handler and `on_event`; avoid duplicating actions across them. A rejected cancel or modify leaves the order working; a position flip emits close and open events.
- `log_components_only=True` with an empty `log_component_levels` emits no logs. `log_level` and `log_level_file` control separate sinks. Confirm the installed build's fixed-point precision mode before assuming its decimal capacity.

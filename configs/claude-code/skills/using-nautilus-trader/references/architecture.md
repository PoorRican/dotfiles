# System Architecture & the Backtest==Live Design Philosophy

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/overview.md
- https://nautilustrader.io/docs/md/latest/concepts/architecture.md
- https://nautilustrader.io/docs/md/latest/concepts/configuration.md
- https://nautilustrader.io/docs/md/latest/concepts/logging.md
- https://nautilustrader.io/docs/md/latest/getting_started/installation.md

## TL;DR

NautilusTrader runs one **NautilusKernel** per process that wires together a fixed set of
components — `MessageBus`, `Cache`, `DataEngine`, `ExecutionEngine`, `RiskEngine`,
`Portfolio`, and a `Trader` holding your strategies/actors. The kernel core is
**single-threaded and deterministic** (background threads only do I/O). That determinism is
what makes **research-to-live parity** real: the *same* `Strategy`/`Actor`/`ExecAlgorithm`
code runs unchanged across three **environment contexts** — **Backtest** (historical replay),
**Sandbox** (real-time data, simulated venue), and **Live** (real-time data, live venue).
You swap the *node* (`BacktestNode`/`BacktestEngine` vs `TradingNode`), not the strategy.
Everything is configured through typed `*Config` dataclass-style objects that **fail fast on
unknown fields**. This is the mental-model file; see [strategies](strategies.md),
[message-bus](message-bus.md), [backtesting](backtesting.md), and [live-trading](live-trading.md)
for depth.

## Component hierarchy

```
NautilusKernel  (one per process; owns config, clock, logging, messaging)
├── MessageBus     — Pub/Sub, Req/Rep, Command/Event backbone (optional Redis backing)
├── Cache          — in-memory store: instruments, accounts, orders, positions, market data
├── DataEngine     — routes quotes/trades/bars/order books to subscribers
├── ExecutionEngine— order lifecycle: routing, state tracking, fills
├── RiskEngine     — pre-trade validation, exposure limits
├── Portfolio      — account balances + positions/exposure across venues
└── Trader         — container for user components:
    ├── Actor            — base user component (data subscriptions, no order mgmt)
    ├── Strategy         — subclass of Actor; order/position logic
    └── ExecAlgorithm    — execution algorithms (order slicing etc.)
```

| Component | Role |
|---|---|
| `NautilusKernel` | Central orchestration: initializes components, configures messaging, holds environment-specific lifecycle behaviors |
| `MessageBus` | Inter-component communication (Pub/Sub, Req/Rep, Command/Event); optional Redis-backed persistence |
| `Cache` | High-performance in-memory store for instruments, accounts, orders, positions |
| `DataEngine` | Routes market data to subscribers based on subscriptions |
| `ExecutionEngine` | Manages order lifecycle: routing commands, tracking states, coordinating risk checks, handling fills |
| `RiskEngine` | Pre-trade validation, position/exposure monitoring, configurable real-time limits |
| `Portfolio` | Tracks account balances and positions/exposure across venues |
| `Actor` | Base user-defined component managed consistently across all contexts |
| `Strategy` | Subclass of `Actor` for order/position logic |
| `ExecAlgorithm` | User-defined execution algorithm component |

### Actor vs Component (the trait split)

Two orthogonal capabilities. Match the trait to the need:

- **Actor** — message dispatch (`handle`/`id`); registry-based routing. Throttler is Actor-only.
- **Component** — lifecycle (`register`, `start`, `stop`, `reset`, `dispose`). `DataEngine`/`ExecutionEngine` are Component-only.
- **Strategy** implements **both** — it needs message routing *and* lifecycle.

## Data & execution flows (conceptual)

These are conceptual flows, not literal API calls.

```
# Market data (quote example)
DataClient adapter -> MPSC channel -> DataEngine.process_data()
  -> DataEngine.handle_quote() -> Cache.add_quote()
  -> MessageBus.publish_quote() -> Strategy.on_quote_tick()
```
Cache-then-publish ordering guarantees strategy handlers always read the latest value from the `Cache`.

```
# Order submission / execution
Strategy.submit_order() -> RiskEngine (pre-trade checks)
  -> ExecutionEngine -> ExecutionClient -> Venue
  -> (OrderAccepted / OrderFilled events) -> Strategy handlers
```

## Environment contexts — why one strategy runs in all three

The environment context selects the **data source** + **venue simulation**. Your components are
managed identically across all three, so you write logic once against the common core.

| Context | Data source | Venue | Node |
|---|---|---|---|
| **Backtest** | Historical (replayed) | Simulated | `BacktestEngine` (low-level) / `BacktestNode` (high-level orchestrator) |
| **Sandbox** | Real-time (live) | Simulated (virtual execution via sandbox adapter) | `TradingNode` |
| **Live** | Real-time (live) | Live | `TradingNode` |

- **Backtest** replays historical data through simulated venues. Use `BacktestEngine` directly
  for full control, or `BacktestNode` to configure/orchestrate runs from config.
- **Sandbox** is *not* backtest: it runs real-time simulation (virtual execution against live
  data) — use it to shake out a strategy before risking capital.
- **Live** deploys the same components to demo/paper or real accounts via `TradingNode`.

The parity guarantee: `Actor`, `Strategy`, and `ExecAlgorithm` run under a common system core
with identical execution semantics across all three. See [live-trading](live-trading.md).

## The config system

Every component is configured with a typed, dataclass-style `*Config` object. Defaults resolve
at the config boundary as plain typed values; an optional field set to `None` means **genuine
semantic absence**, not "use default". **Unknown/misspelled fields fail validation immediately**
(`forbid_unknown_fields`/`deny_unknown_fields`), so always use exact documented field names.

### Two top-level node configs

| Config | Pairs with | Environment |
|---|---|---|
| `BacktestRunConfig` | `BacktestNode` | Backtest — declares venues, data, and strategies for a run |
| `TradingNodeConfig` | `TradingNode` | Sandbox / Live |

`BacktestEngineConfig` configures the low-level `BacktestEngine` directly (both accept a
`logging` field).

### Importable component configs

Strategies and actors are attached to a node via *importable* configs that name the class by
its fully-qualified path plus a nested config — this is how a node instantiates your components
from declarative config (e.g. TOML/JSON-driven runs):

- `ImportableStrategyConfig` — points at a `Strategy` subclass + its `StrategyConfig`.
- `ImportableActorConfig` — points at an `Actor` subclass + its `ActorConfig`.

See [strategies](strategies.md) and [actors](actors.md) for the concrete `StrategyConfig`/
`ActorConfig` fields and construction examples.

## Logging

High-performance Rust logging on a dedicated thread fed by an MPSC channel, so log I/O never
blocks the trading thread. Configure declaratively via `LoggingConfig` on your node/engine
config, or drive it directly with `init_logging()` / `Logger`.

```python
LoggingConfig(
    log_level='INFO',              # stdout/stderr minimum level
    log_level_file='INFO',         # file sink minimum level (independent of stdout)
    log_file_format=None,          # 'json' for JSON-lines; None = plain text
    log_file_name=None,            # custom basename; disables default date rotation
    log_directory=None,            # defaults to CWD
    log_file_max_size=None,        # bytes -> size-based rotation
    log_file_max_backup_count=5,
    log_component_levels={},       # per-component levels, e.g. {'Portfolio': 'INFO'}
    log_colors=True,
    log_components_only=False,     # only log listed components (empty dict => NO logs!)
    use_pyo3=False,
    bypass_logging=False,
    print_config=False,
    clear_log_file=False,
)
```

`LogLevel`: `OFF | TRACE | DEBUG | INFO | WARNING | ERROR`. **TRACE is emitted only by Rust
components** — use `DEBUG` for verbose Python diagnostics.

```python
from nautilus_trader.config import LoggingConfig, TradingNodeConfig

config_node = TradingNodeConfig(
    trader_id="TESTER-001",
    logging=LoggingConfig(
        log_level="INFO",
        log_level_file="DEBUG",
        log_file_format="json",
        log_component_levels={"Portfolio": "INFO"},
    ),
)
```

### Direct logging (scripts) & multi-engine loops

```python
from nautilus_trader.common.component import init_logging, Logger

log_guard = init_logging()   # exactly ONCE per process; returns a LogGuard
logger = Logger("MyLogger")
```

When running **multiple engines sequentially** in one process, engine disposal can tear down
the logging subsystem and you cannot re-init. Hold the first engine's `LogGuard`:

```python
log_guard = None
for i in range(number_of_backtests):
    engine = setup_engine(...)
    if log_guard is None:
        log_guard = engine.get_log_guard()   # keep alive across the loop
    engine.add_actors(setup_actors(...))
    engine.run()
    engine.dispose()
```

`get_log_guard()` works on both `BacktestEngine` and `TradingNode`. Up to 255 concurrent
`LogGuard` instances are supported.

### NAUTILUS_LOG env override (grammar)

Overrides logging config for Rust binaries / at runtime. Semicolon-separated entries; levels
case-insensitive (`Off, Trace, Debug, Info, Warning/Warn, Error`). Grammar confirmed against
`concepts/logging.md` and the parser `LoggerConfig::from_spec` in
`crates/common/src/logging/config.rs` (splits on `;`, then `=`; keys containing `::` route to the
module-path map, others to the exact-component map).

| Key | Meaning |
|---|---|
| `stdout=<Level>` | stdout minimum level |
| `fileout=<Level>` | file minimum level |
| `<Component>=<Level>` | exact component-name match |
| `<module::path>=<Level>` | prefix match (Rust only, longest prefix wins) |
| `is_colored` / `print_config` / `log_components_only` | bare flags |

```bash
export NAUTILUS_LOG="stdout=Info;fileout=Debug;RiskEngine=Error;is_colored"
```

Log file names — size-based rotation: `{trader_id}_{%Y-%m-%d_%H%M%S:%3f}_{instance_id}.{log|json}`;
default/date-based: `{trader_id}_{%Y-%m-%d}_{instance_id}.{log|json}`.

`use_tracing=True` + `RUST_LOG` (e.g. `RUST_LOG="my_feature_extractor=debug,hyper=warn"`) route
external Rust-crate output; both are **process-global, set-once, before startup**.

## Component lifecycle states

`ComponentState` is a per-component state machine.

**Stable states:**
```
PRE_INITIALIZED -> READY -> RUNNING -> STOPPED -> DISPOSED
```
plus `DEGRADED` (partial functionality) and `FAULTED` (detected fault).

**Transitional states:** `STARTING, STOPPING, RESUMING, RESETTING, DISPOSING, DEGRADING, FAULTING`.

Normal teardown uses `stop()` / `dispose()`. Crash-only design applies only to *unrecoverable*
faults; graceful shutdown still uses the stop/dispose flow.

## Installation essentials

Platform matrix is narrow: 64-bit Linux (Ubuntu 22.04+, glibc ≥ 2.35), macOS 15.0+ ARM64,
Windows Server 2022+ x86_64; **Python 3.12–3.14 only**. Use **uv** with vanilla CPython
(Conda not recommended).

```bash
uv pip install nautilus_trader                       # stable, PyPI
uv pip install "nautilus_trader[docker,ib]"          # with extras
uv pip install nautilus_trader --pre \
    --index-url=https://packages.nautechsystems.io/simple   # nightly (TEST ONLY)
```

- **Extras:** `betfair, docker, ib, polymarket, visualization`.
- Prefer `--extra-index-url` over `--index-url` (the latter *replaces* PyPI, breaking transitive deps).
- **Redis** is optional (message bus persistence / streams); requires **≥ 6.2**.
- Never use `--pre`/nightly/dev wheels in live trading.

### Precision modes

| Mode | Backing | Max decimals | Where |
|---|---|---|---|
| **High-precision** (default on Linux/macOS wheels) | 128-bit | 16 | `Price`/`Money`/`Quantity` |
| **Standard** (Windows wheels; MSVC lacks `__int128`) | 64-bit | 9 | same types |

Building from source: `export HIGH_PRECISION=true` (or `false`) before `make install-debug`.
Rust crates default to standard; enable `features = ["high-precision"]`. Confirm which mode the
installed build uses before assuming decimal capacity. See [value-types](value-types.md).

## Value-type & identifier grammars

| Grammar | Format | Example |
|---|---|---|
| Timestamp | UTC, ISO 8601, nanosecond precision (9-digit fractional), `Z` suffix | `2024-01-05T15:30:45.123456789Z` |
| Identifier (UUIDv4, RFC 4122) | 8-4-4-4-12 hex groups | `2d89666b-1a1e-4a75-b193-4eb3b454c757` |

## Gotchas

- **Rewriting strategy code for live.** Why: the platform gives research-to-live parity — same
  `Actor`/`Strategy`/`ExecAlgorithm` under a common core with identical semantics. Correct:
  write logic once; deploy by swapping the node (`BacktestNode`/`BacktestEngine` ↔ `TradingNode`).
- **Confusing Sandbox with Backtest.** Why: Sandbox runs *real-time* virtual execution against
  live data; Backtest replays history. Correct: Backtest for historical replay, Sandbox for
  real-time virtual execution before going live.
- **Running multiple `TradingNode`/`BacktestNode` instances in one process.** Why: per-process
  singleton state (force-stop flag, logger mode, runtime singletons) collides. Correct: run
  nodes **sequentially**; use multiple strategies within one node.
- **Expecting kernel parallelism for throughput.** Why: MessageBus dispatch, strategy logic,
  risk checks, and cache ops run **single-threaded** for deterministic ordering / parity.
  Correct: background threads only for network I/O, persistence, adapters.
- **Assuming corrupt data is tolerated.** Why: fail-fast — "corrupt data is worse than no data";
  system panics on overflow/underflow, NaN/Infinity deserialization, invalid conversions.
  Correct: feed valid, in-range data; treat panics as intended guards.
- **Passing `None`/wrong types to non-nullable params.** Why: Cython enforces types at runtime.
  Correct: pass correctly-typed, non-None args; expect `TypeError`/`ValueError` otherwise.
- **Misspelled config fields.** Why: config decoding fails fast on unknown fields. Correct: use
  exact documented field names.
- **`init_logging()` more than once per process.** Why: only one init per process; a second call
  fails. Correct: init once; in multi-engine loops capture the first `engine.get_log_guard()`
  and keep the reference alive across the loop.
- **`log_components_only=True` with empty `log_component_levels`.** Why: components-only mode
  with no filters emits **no logs at all**. Correct: populate `log_component_levels`.
- **Expecting TRACE from Python components.** Why: TRACE is Rust-only. Correct: use DEBUG in Python.
- **Confusing stdout vs file level.** Why: `log_level` and `log_level_file` govern independent
  sinks. Correct: set both explicitly for the sinks you care about.
- **Treating precision as fixed at 9 decimals.** Why: default (Linux/macOS) is high-precision
  128-bit / 16 decimals; Windows wheels are standard 64-bit / 9. Correct: confirm the build's mode.
- **Assuming Python 3.10/3.11 works.** Why: wheels/source build for 3.12–3.14 only. Correct: use
  CPython 3.12–3.14 (64-bit).

See also: [SKILL.md](../SKILL.md), [backtesting](backtesting.md), [live-trading](live-trading.md),
[message-bus](message-bus.md), [gotchas](gotchas.md).

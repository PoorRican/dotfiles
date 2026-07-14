# Custom Data Types & the `CustomData` Delivery Contract

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- https://nautilustrader.io/docs/md/latest/concepts/custom_data.md

## TL;DR

A custom data type is any subclass of `nautilus_trader.core.data.Data` that carries two nanosecond timestamps: `ts_event` (when the event happened) and `ts_init` (when the object was created/ingested). The engine identifies and routes custom data by a **`DataType`** descriptor — a `(type, metadata)` pair — not by the Python class alone. Three things must line up:

1. **Definition** — subclass `Data`, expose `ts_event`/`ts_init`. The `@customdataclass` decorator generates the boilerplate (init, dict/bytes/arrow serialization, `ts_event`/`ts_init` properties).
2. **Delivery/routing** — everything flows through the message bus keyed on `DataType`. Subscribe with `subscribe_data(DataType(T))`, publish with `self.publish_data(DataType(T), obj)`, receive in `on_data(self, data)`.
3. **The wrapping asymmetry** — when you feed data *directly* into the engine (backtest add-data paths), you must hand it a `CustomData(DataType(T), obj)` wrapper; publishing from *inside* a component wraps for you.

The single biggest trap is #3 — see the warning below.

---

## ⚠️ CRITICAL GOTCHA: bare `Data` vs. `CustomData` wrapping

> **A BARE custom `Data` subclass fed to the engine is REJECTED and never reaches `on_data`.**
>
> Verified 1.223.0, behavior unchanged through 1.230.0. If you push a bare instance of your custom type into the engine via `BacktestEngine.add_data(...)` / `add_data_iterator(...)`, the `DataEngine` rejects it with an error like **"Cannot handle data: unrecognized type"** and it **never** reaches any `on_data` subscriber of `subscribe_data(DataType(T))`.
>
> **You MUST wrap it** when feeding it in:
> ```python
> from nautilus_trader.model.data import CustomData, DataType
> engine.add_data([CustomData(DataType(MyData), obj) for obj in objs])
> ```
> Nautilus **UNWRAPS** the `CustomData` before calling `Actor.on_data`, so your handler receives the **INNER** object — `isinstance(data, MyData)` is `True`, not `isinstance(data, CustomData)`.
>
> **When publishing from inside a component**, `self.publish_data(DataType(MyData), obj)` does the wrapping for you — pass the raw `obj`, never a pre-wrapped `CustomData`.
>
> This bare-vs-wrapped asymmetry is the most common custom-data bug: subscribers silently never fire.

**Mental model:** the *bus* speaks `CustomData`; *handlers* speak the inner type; *engine ingestion* needs the bus dialect, so you speak `CustomData` at the door.

---

## Defining a custom data type

### The `@customdataclass` path (recommended)

```python
from nautilus_trader.core.data import Data
from nautilus_trader.model.custom import customdataclass
from nautilus_trader.model.identifiers import InstrumentId


@customdataclass
class MySignalData(Data):
    instrument_id: InstrumentId = InstrumentId.from_str("ES.GLBX")
    delta: float = 0.0
    gamma: float = 0.0
    ts_event: int = 0   # nanoseconds since UNIX epoch
    ts_init: int = 0    # nanoseconds since UNIX epoch
```

`@customdataclass` (from `nautilus_trader.model.custom`) auto-generates:

| Generated | Purpose |
|---|---|
| `__init__` from annotated fields | constructor with defaults |
| `ts_event` / `ts_init` properties | required by the engine for ordering & timestamps |
| `to_dict()` / `from_dict()` | JSON-friendly (de)serialization |
| `to_bytes()` / `from_bytes()` | binary serialization |
| `to_arrow()` / `from_arrow()` | pyarrow `RecordBatch` (de)serialization for the catalog |

Every custom type **must** end up with `ts_event` and `ts_init` (integer nanoseconds). Include them as annotated fields (as above) or provide the properties yourself if hand-rolling.

### Hand-rolled path (without the decorator)

Subclass `Data` and implement the two abstract timestamp properties:

```python
from nautilus_trader.core.data import Data

class MyData(Data):
    def __init__(self, value: float, ts_event: int, ts_init: int) -> None:
        self._value = value
        self._ts_event = ts_event
        self._ts_init = ts_init

    @property
    def ts_event(self) -> int:
        return self._ts_event

    @property
    def ts_init(self) -> int:
        return self._ts_init
```

Without `@customdataclass` you get no serialization/Arrow machinery — you must register those yourself (see [Catalog persistence](#catalog-persistence--arrow-schema-registration)) if you want to persist/query the type.

---

## `DataType` — the routing/identity descriptor

```python
from nautilus_trader.model.data import DataType

DataType(MySignalData)                                  # type only
DataType(MySignalData, metadata={"instrument_id": "ES"})  # type + metadata
```

| Field | Type | Role |
|---|---|---|
| `type` | the custom `Data` subclass | primary identity; drives equality, hashing, and message-bus topic |
| `metadata` | `dict \| None` | **also** part of equality & topic routing; two `DataType`s with different metadata are distinct subscriptions/topics |

- **Subscriptions and publishes must use matching `DataType`s** (same `type` **and** same `metadata`) or they won't line up on the bus.
- `metadata` is how you fan out one Python type into multiple logical streams (e.g. per-instrument). Use it — not the storage `identifier` — to differentiate routing.
- Timestamps do **not** live on `DataType`; they live on the payload/`CustomData`.

> **Architecture note (registry internals):** the underlying Rust `DataRegistry` keys handlers by a `type_name` string and additionally supports an `identifier` that affects only the on-disk storage path (`data/custom/<type_name>/<identifier...>`), never routing or equality. For ordinary Python usage you interact with `DataType(type, metadata)`; reach for `identifier`/`type_name` semantics only when working with the low-level registry/catalog layout described in the source doc.

---

## Publishing & subscribing (the message-bus flow)

Inside an `Actor` or `Strategy`:

```python
class MyPublisher(Actor):
    def on_start(self) -> None:
        greeks = MySignalData(delta=0.5, ts_event=now, ts_init=now)
        # Wraps as CustomData(DataType(MySignalData), greeks) internally:
        self.publish_data(DataType(MySignalData), greeks)


class MySubscriber(Actor):
    def on_start(self) -> None:
        self.subscribe_data(DataType(MySignalData))

    def on_data(self, data: Data) -> None:
        # Receives the UNWRAPPED inner object:
        if isinstance(data, MySignalData):
            self.log.info(f"delta={data.delta}")
```

| Method (on `Actor` / `Strategy`) | Signature (essentials) | Notes |
|---|---|---|
| `publish_data` | `publish_data(data_type: DataType, data: Data)` | pass the **raw** payload; wraps to `CustomData` for you |
| `subscribe_data` | `subscribe_data(data_type: DataType, client_id: ClientId = None)` | matches on `type` + `metadata` |
| `unsubscribe_data` | `unsubscribe_data(data_type: DataType, client_id: ClientId = None)` | |
| `request_data` | `request_data(data_type: DataType, client_id: ClientId, ...)` | historical/one-shot request; result arrives via `on_historical_data`/`on_data` |
| `on_data` | `on_data(self, data: Data)` | callback for **live/streamed** custom data; receives inner object |

**Delivery flow:** `publish_data` (or wrapped engine ingestion) → `MessageBus` topic derived from `DataType` → `DataEngine` → matched subscribers' `on_data`, unwrapped. A bare `Data` skipping the `CustomData` wrap breaks this chain at the `DataEngine` (see warning above).

---

## Feeding into a `BacktestEngine`

```python
from nautilus_trader.model.data import CustomData, DataType

wrapped = [CustomData(DataType(MySignalData), g) for g in greeks_objects]
engine.add_data(wrapped)          # sorted by ts_init across all data
# or, streaming huge volumes — the generator MUST yield list[Data] BATCHES, not items:
def batched(items, n=1_000):
    for i in range(0, len(items), n):
        yield items[i:i + n]                       # each yield is a list[Data]
engine.add_data_iterator("greeks", batched(wrapped))
```

- Always wrap. `add_data` / `add_data_iterator` require the bus dialect (`CustomData`).
- `add_data` sorts all data by `ts_init`; keep timestamps correct or ordering breaks.
- See [backtesting](backtesting.md) for the full engine setup.

---

## Catalog persistence & Arrow schema registration

`@customdataclass` gives you `to_arrow()`/`from_arrow()` and lets the type round-trip through a `ParquetDataCatalog`:

```python
catalog.write_data([obj1, obj2])           # write custom Data objects
data = catalog.custom_data(cls=MySignalData) # returns list[CustomData] — WRAPPED
```

Note: `catalog.custom_data(...)` returns `list[CustomData]` (each row re-wrapped as `CustomData(DataType(T), obj)`), unlike `on_data`, which delivers the bare inner object. Reach the payload via `wrapped.data`.

Custom data lands on disk (ParquetDataCatalog) under the path grammar:

| Grammar | Format | Examples |
|---|---|---|
| Custom data storage path | `data/custom_<snake_type_name>/<start>_<end>.parquet` | `data/custom_my_signal_data/…parquet`, `data/custom_greeks_data/…` |

For **hand-rolled** types (no decorator), register Arrow encode/decode with the serializer before writing/querying:

```python
from nautilus_trader.serialization.arrow.serializer import register_arrow

register_arrow(
    data_cls=MyData,
    schema=my_pyarrow_schema,
    encoder=my_encoder,   # single MyData -> pyarrow.RecordBatch (use batch_encoder= for list[MyData] -> RecordBatch)
    decoder=my_decoder,   # pyarrow.RecordBatch -> list[MyData]
)
```

On write, `type_name` (and `metadata`) are attached to the Arrow schema metadata; on read they are extracted to locate the decoder. The type **must be registered** (via `@customdataclass` or `register_arrow`) at query time or reconstruction fails. See [data-catalog](data-catalog.md).

---

## Gotchas

- **Bare `Data` into the engine is silently dropped from delivery.** → The `DataEngine` only routes `CustomData`; a bare instance is "unrecognized." → Wrap: `CustomData(DataType(T), obj)` for `add_data`/`add_data_iterator`. (See top warning — this is #1.)
- **Expecting `on_data` to receive a `CustomData`.** → Nautilus unwraps before calling handlers. → Test `isinstance(data, MyData)`, access `data.<field>` directly; never `data.data`.
- **Double-wrapping when publishing.** → `publish_data` wraps internally. → Pass the raw payload to `publish_data(DataType(T), obj)`, not a pre-built `CustomData`.
- **Subscribe/publish `metadata` mismatch.** → `metadata` is part of `DataType` equality and the bus topic; `DataType(T)` and `DataType(T, {"k":"v"})` are different topics. → Use identical `DataType` on both sides.
- **Missing / wrong `ts_init`.** → The engine orders all data by `ts_init`; bad values scramble replay ordering. → Always set integer-nanosecond `ts_event` and `ts_init`.
- **Assuming `CustomData` compares/hashes by value.** → `CustomData` inherits `object.__eq__`/`object.__hash__` — it **is** hashable but uses **identity** semantics (two wrappers of equal payloads are neither `==` nor the same dict/set key). → Compare/route on the inner payload or on `DataType`, not on the wrapper.
- **Using storage `identifier` to distinguish instances at runtime.** → `identifier` affects only the on-disk path; two instances differing only in `identifier` compare equal and publish to the same topic. → Differentiate via `metadata` for routing/equality; use `identifier` only to control disk layout.
- **Custom `Data` class name collides with a built-in.** → Registration keys on the **bare class name** (`cls.__name__`), so defining a class whose name matches an already-registered type raises `KeyError: '...' already contained in '_OBJECT_TO_DICT_MAP'` at class-definition time. Nautilus ships auto-registered custom types (e.g. `nautilus_trader.model.greeks_data.GreeksData`) — reusing those names detonates on import. → Give every custom `Data` class a globally unique name.
- **Querying a type that was never registered.** → Decoder is looked up by schema `type_name`; unregistered ⇒ no decoder. → Ensure `@customdataclass` (or `register_arrow`) ran before `catalog.custom_data(...)`.
- **Confusing `@customdataclass` (Cython) with `@customdataclass_pyo3` / `#[custom_data]` (PyO3/Rust registry).** → They are separate registration paths. → For normal Python custom data use `@customdataclass`; the PyO3 `register_custom_data_class` / Arrow C FFI path is the lower-level architecture described in the source doc.

See also: [data](data.md), [actors](actors.md), [strategies](strategies.md), [message-bus](message-bus.md), [data-catalog](data-catalog.md), [gotchas](gotchas.md), and the master [SKILL.md](../SKILL.md).

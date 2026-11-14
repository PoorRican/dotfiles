# Custom data

For the Python `@customdataclass` implementation, do not declare `ts_event` or `ts_init` as annotated data fields with defaults. Those class attributes prevent the decorator from installing timestamp properties, so the visible timestamps can remain at their defaults even when constructor timestamps were supplied. Pass timestamps to the generated constructor instead:

```python
from nautilus_trader.core.data import Data
from nautilus_trader.model.custom import customdataclass

@customdataclass
class MySignalData(Data):
    value: float = 0.0

signal = MySignalData(value=1.5, ts_event=123, ts_init=456)
assert signal.ts_event == 123 and signal.ts_init == 456
```

The timestamps are integer nanoseconds. The generated `_schema` already includes `ts_event` and `ts_init`; when supplying your own `_schema`, include both columns without declaring them as dataclass fields. For a hand-written `Data` type, implement the timestamp properties and register serialization separately.

- When feeding custom Python data directly to a backtest engine, wrap each item as `CustomData(DataType(MySignalData), item)`. A bare custom `Data` instance can be rejected as an unrecognized type and never reach subscribers.
- Inside a component, pass the unwrapped item to `publish_data(DataType(MySignalData), item)`; `on_data` receives the inner object. Catalog `custom_data` queries instead return wrappers: access the payload through `.data`.
- Publisher and subscriber `DataType` metadata must match. Storage identifiers do not substitute for routing metadata.
- Custom types must have Arrow serialization registered when writing and querying a catalog. The decorator handles registration; a hand-written type needs the appropriate Arrow registration as well as any message serialization.
- Custom class registration uses the class name; a collision with an already registered class can fail at definition time. Choose a distinct name.
- Verify timestamps round-trip and that replay order matches the intended availability time; replay is ordered by `ts_init`, not necessarily event time.

```python
from nautilus_trader.model.data import CustomData, DataType

data_type = DataType(MySignalData)
engine.add_data([CustomData(data_type, signal)])
# In a component: self.subscribe_data(data_type)
# Publishing from a component: self.publish_data(data_type, signal)
catalog.write_data([signal])
payloads = [row.data for row in catalog.custom_data(cls=MySignalData)]
```

For a hand-written type, `register_serializable_type` covers message serialization, not Parquet. Register Arrow separately before writing **and** querying:

```python
from nautilus_trader.serialization.arrow.serializer import register_arrow

register_arrow(data_cls=MyData, schema=my_schema, encoder=my_encoder, decoder=my_decoder)
```

The encoder converts one object to a `pyarrow.RecordBatch`; the decoder returns a list of objects. Use `batch_encoder` instead for a list-to-batch encoder. The Python decorator and the PyO3 custom-data registration paths are distinct.

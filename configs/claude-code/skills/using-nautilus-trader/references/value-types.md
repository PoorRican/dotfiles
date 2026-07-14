# Core Value Types & Identifiers

> Curated for NautilusTrader v1.230.0. Online docs track `latest` (currently v1.230.0).

**Source docs:**
- [Value Types](https://nautilustrader.io/docs/md/latest/concepts/value_types.md)

## TL;DR

NautilusTrader money/price/size values are **immutable fixed-point** types stored
internally as **scaled integers**, never floats — this makes arithmetic
deterministic and cross-platform. Three types: `Quantity` (unsigned size, no
currency), `Price` (signed price, no currency), `Money` (signed amount, requires a
`Currency`). Each carries an immutable `precision` that controls **display and
serialization only — not equality**. Because they are immutable they are hashable
and thread-safe; every operation returns a **new** instance.

The single most important discipline: **build values from `from_str(...)`** (or
integer raw), not from Python floats, so a value like `0.1` never enters as a
lossy binary float. Identifiers (`InstrumentId`, `TraderId`, …) are likewise
immutable typed strings — use them instead of bare `str` so the type system
enforces well-formedness.

---

## The three value types

| Type | Signature | Signed? | Currency? | Use |
|---|---|---|---|---|
| `Quantity` | `Quantity(value, precision)` | No (unsigned, ≥ 0) | No | Trade size, order amount, position size |
| `Price` | `Price(value, precision)` | Yes | No | Market price, quote, price level |
| `Money` | `Money(value, currency)` | Yes | **Required** | P&L, balances, cash amounts |

`precision` is **required** (no default) for `Price`/`Quantity` —
`Quantity(100)` raises; write `Quantity(100, 0)`. In v1.230.0 the direct
constructors take a Python `float`; prefer `from_str` / `make_qty` / `make_price`
to avoid float error (see Gotchas).

Import from `nautilus_trader.model.objects`; currencies from
`nautilus_trader.model.currencies`.

```python
from nautilus_trader.model.objects import Quantity, Price, Money
from nautilus_trader.model.currencies import USD, EUR
```

### Construction

```python
# Direct construction (value + precision). Money takes a Currency, not precision.
qty   = Quantity(100, precision=0)
price = Price(123.456, precision=3)
usd   = Money(100.00, USD)

# from_str — PREFERRED for exact values (no float round-trip)
qty   = Quantity.from_str("100.5")
price = Price.from_str("99.95")
money = Money.from_str("1000.00 USD")   # "amount CURRENCY"
```

`from_str` parses the exact decimal text, so `Price.from_str("0.1")` is exact
whereas `Price(0.1, precision=1)` first goes through a lossy Python float. When a
value originates from JSON, a config string, or user input, prefer `from_str`.

`Money.from_str` string grammar:

| Format | Examples |
|---|---|
| `"<amount> <CURRENCY_CODE>"` (space-separated) | `"1000.00 USD"`, `"50.00 EUR"` |

### Conversions

| Method | Returns | Notes |
|---|---|---|
| `as_decimal()` | `decimal.Decimal` | Preserves fixed-point precision exactly |
| `as_double()` | `float` | Loses fixed-point exactness — display/interop only |
| `str(x)` | `str` | Uses `precision` for formatting, e.g. `"123.456"` |

```python
price = Price(123.456, precision=3)
price.as_decimal()   # Decimal("123.456")  — exact
price.as_double()    # 123.456             — float
str(price)           # "123.456"
```

`precision` is an immutable property (`price.precision -> int`). It is the number
of decimal places used for output/serialization and **does not affect equality**.

---

## Fixed-precision & equality semantics

Values compare by **numeric value**, not by precision:

```python
Price(1.23, precision=2) == Price(1.230, precision=3)   # True
```

So use `precision` purely for formatting/serialization; never assume two values
with different precision are unequal, or that a precision change alters identity.

**Increment / tick-size note:** precision metadata is baked into serialized
Parquet/Arrow files. Do **not** consolidate market-data files across a venue
tick-size (precision) change — pre- and post-change data have different precision
and must be kept in separate files. See [data-catalog](data-catalog.md).

---

## Arithmetic & type promotion (the pitfalls)

Value types are immutable — every operation returns a new object; originals are
never mutated.

```python
qty1 = Quantity(100, precision=0)
qty2 = Quantity(50, precision=0)
result = qty1 + qty2      # NEW Quantity(150); qty1/qty2 unchanged
```

### Same-type operations

| Operation | Result type |
|---|---|
| `+`, `-` between two same-type values | Same type (`Quantity`/`Price`/`Money`) |
| `*`, `/`, `//`, `%` | **`Decimal`** (not the value type) |
| `round(x)` (no ndigits) | **`int`** |
| `round(x, n)` | **`Decimal`** |
| `-Price` (unary neg) | `Price` |
| `-Quantity` (unary neg) | **`Decimal`** (Quantity is unsigned) |
| `abs(Money)` | `Money` |

### Mixed-type promotion (value-type ⊕ scalar)

```python
qty = Quantity(100, precision=0)
type(qty + 50)             # <class 'decimal.Decimal'>   (int  -> Decimal)
type(qty + 50.5)           # <class 'float'>             (float -> float)
type(qty + Decimal("50"))  # <class 'decimal.Decimal'>   (Decimal -> Decimal)
```

Rule of thumb: combining with **int or Decimal → Decimal**; with **float →
float**. Re-wrap explicitly if you need the value type back:
`Quantity(qty + 50, precision=0)`.

### Money currency rules — no implicit FX

```python
Money(100.00, USD) + Money(25.00, USD)   # OK -> Money(125.00, USD)
Money(100.00, USD) + Money(50.00, EUR)   # ValueError — currency mismatch
```

### Quantity is unsigned

```python
Quantity(-100, precision=0)               # ValueError
Quantity(50) - Quantity(100)              # ValueError — would be negative
```

### Accumulating (immutable → reassign)

```python
total = Money(0.00, USD)
for amount in [Money(100.00, USD), Money(50.00, USD), Money(25.00, USD)]:
    total = total + amount   # reassign to the new instance; no in-place mutation
# total == Money(175.00, USD)
```

---

## Currency

`Currency` objects (e.g. `USD`, `EUR`, `BTC`, `USDT`) live in
`nautilus_trader.model.currencies` and carry code, precision, and type (fiat /
crypto). They are required by `Money` and by instrument definitions. A `Currency`
also defines the precision `Money` uses; pass the `Currency` object, not a string.

---

## Identifiers

Identifiers are immutable, hashable, typed wrappers around strings, from
`nautilus_trader.model.identifiers`. Prefer them over bare `str` — the constructor
validates the value, and the type prevents mixing (e.g. a `Venue` where a `Symbol`
is expected). All support `.from_str(...)` and stringify back to their canonical
form; `.value` returns the underlying string.

```python
from nautilus_trader.model.identifiers import (
    InstrumentId, Symbol, Venue, TraderId, StrategyId,
    ClientOrderId, VenueOrderId, PositionId, AccountId, ClientId, ComponentId,
)
```

| Identifier | Meaning | String grammar | Example |
|---|---|---|---|
| `Symbol` | Raw instrument symbol | free-form token | `Symbol("AAPL")` |
| `Venue` | Trading venue / exchange | free-form token | `Venue("NASDAQ")` |
| `InstrumentId` | Symbol + Venue | `{Symbol}.{Venue}` | `AAPL.NASDAQ` |
| `TraderId` | Node/trader instance | `{name}-{tag}` (one hyphen) | `TESTER-001` |
| `StrategyId` | Strategy instance | `{name}-{tag}` (one hyphen) | `EMACross-001` |
| `AccountId` | Account | `{issuer}-{number}` (one hyphen) | `SIM-001` |
| `ClientOrderId` | Client-assigned order id | free-form | `O-19700101-0000-000-001` |
| `VenueOrderId` | Venue-assigned order id | free-form | `1` |
| `PositionId` | Position id | free-form | `P-19700101-0000-000-001` |
| `ClientId` | Adapter/data-execution client | free-form | `BINANCE` |
| `ComponentId` | Generic component id | free-form | `MyActor` |

### InstrumentId

Composite of `Symbol` and `Venue`; the canonical string joins them with `.`:

```python
instrument_id = InstrumentId(Symbol("AAPL"), Venue("NASDAQ"))
instrument_id = InstrumentId.from_str("AAPL.NASDAQ")   # equivalent

instrument_id.symbol   # Symbol("AAPL")
instrument_id.venue    # Venue("NASDAQ")
str(instrument_id)     # "AAPL.NASDAQ"
```

Because `.` is the separator, a `Symbol` that itself contains dots (some venues)
parses with the **last** `.` as the venue boundary — construct from
`Symbol`/`Venue` objects directly when in doubt.

### Structured ids: `{name}-{tag}` / `{issuer}-{number}`

`TraderId`, `StrategyId`, and `AccountId` require a hyphen; the trailing segment
must be a valid tag/number. The trader and strategy tags feed deterministic order
id generation, so they must be unique per instance:

```python
TraderId("TESTER-001")       # name=TESTER, tag=001
StrategyId("EMACross-001")   # name=EMACross, tag=001
AccountId("SIM-001")         # issuer=SIM, number=001
```

Passing a value with no hyphen (e.g. `TraderId("TESTER")`) is rejected by a **Rust
panic that aborts the process (SIGABRT), not a catchable Python exception** — so
validate identifier strings *before* constructing; you cannot `try/except` a
malformed `TraderId`/`StrategyId`/`AccountId`. For the exact tag/number rules,
consult the source doc and API reference rather than guessing.

---

## Gotchas

- **Building values from Python floats.** Why: `Price(0.1, precision=1)` first
  materializes a lossy binary float. Correct: use `Price.from_str("0.1")` (or an
  integer raw value) for any value that must be exact.
- **Assuming precision affects equality.** Why: precision is display/serialization
  only. `Price(1.23, precision=2) == Price(1.230, precision=3)` is `True`.
  Correct: compare by value; use precision solely for formatting.
- **Expecting `Quantity + int` (or `+ Decimal`) to stay a `Quantity`.** Why: mixed
  arithmetic follows Python's numeric tower — value+int/Decimal → `Decimal`,
  value+float → `float`. Correct: re-wrap explicitly (`Quantity(result, precision=…)`).
- **Negating a `Quantity`.** Why: `Quantity` is unsigned; `-qty` returns a
  `Decimal`. (`-Price` returns `Price`; `abs(Money)` returns `Money`.) Correct:
  treat negated Quantity as `Decimal`.
- **Constructing/subtracting into a negative `Quantity`.** Why: negative Quantity
  is invalid — `Quantity(-100, …)` and `Quantity(50) - Quantity(100)` both raise
  `ValueError`. Correct: guard subtractions, or use signed `Price`/`Money`.
- **Adding `Money` across currencies.** Why: no implicit FX — mismatch raises
  `ValueError`. Correct: convert to a common currency first.
- **Expecting `*` / `/` / `round()` to return the value type.** Why: only `+`/`-`
  between same-type values stay the type; multiply/divide/floor-div/modulo return
  `Decimal`, while `round(x)` (no ndigits) returns a plain `int` and `round(x, n)`
  returns `Decimal`. Correct: expect `int`/`Decimal` and re-wrap if needed.
- **Trying to mutate in place.** Why: all value types are immutable (what makes
  them hashable/thread-safe). Correct: reassign to the returned new instance.
- **Consolidating Parquet/Arrow across a tick-size change.** Why: precision is
  stored in the files; pre/post-change data have different precision. Correct:
  keep them in separate files. See [data-catalog](data-catalog.md).
- **Using bare `str` where an identifier is expected.** Why: skips validation and
  loses type safety across the API. Correct: wrap in the typed identifier
  (`InstrumentId.from_str(...)`, `Venue(...)`, …).

---

See also: [instruments](instruments.md) (Price/Quantity increments per
instrument), [orders](orders.md), [portfolio-and-reports](portfolio-and-reports.md)
(Money in P&L/balances), [data-catalog](data-catalog.md) (serialization &
precision), and the master [SKILL.md](../SKILL.md).

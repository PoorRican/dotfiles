# Dataframe traps

## NumPy

- A fixed-width Unicode array can silently truncate identifiers: `np.full(n, s, dtype="U")` allocates one character. Infer the dtype or specify sufficient width, and test distinct identities through the actual key-building path.
- Structured `S` fields return bytes; compare with bytes or decode before comparing to text.
- Boolean subtraction and `np.allclose` can fail. Compare boolean arrays directly; a comparison error is an instrument failure, not evidence that values differ.

## Polars

- In conditional expressions, bare strings denote columns; use `pl.lit` for literal text. A bare aggregate in `with_columns` broadcasts globally; use a group window when each row needs its group aggregate.
- Filters retain true predicates, so null comparisons drop rows unless nulls are explicitly included. Null join keys do not match by default; use `nulls_equal=True` when nulls should match. Duplicate join keys can multiply rows.
- `pl.lit(1).cum_sum().over(group)` does not count rows per group. Use `pl.int_range(pl.len()).over(group)` and add 1 for a 1-based count. First and last depend on row ordering; sort by the intended key first.
- Non-strict casts can turn invalid values into nulls. When translating pandas code, check output ordering and fractional-second parsing against the installed version: Polars/Chrono uses `%.f` for a fractional part including the decimal point. Polars `cut` takes interior breakpoints with outer bounds implicit, unlike pandas' explicit bin edges.
- Lazy scans allow predicate and projection pushdown; inspect schema before composing expressions and compare `lf.explain()` with `lf.explain(optimized=False)` to see the plan. Materialization loses subsequent plan-wide optimization. Streaming does not guarantee every plan or its materialized result fits memory; consider a sink for large output. Consult the [Polars API reference](https://docs.pola.rs/api/python/stable/reference/) matching the installed version for API semantics.

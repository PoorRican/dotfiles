# Polars correctness and performance

Scope: Preserve Polars semantics that can silently alter row meaning, and point to the detailed reference pack for API-specific work.

## Expression and row semantics

- In `when(...).then(...)` and `.otherwise(...)`, a bare string resolves as a column reference rather than literal text; `pl.lit(...)` expresses a string literal. (src: polars, 2026-07-24)
- A bare aggregation inside `with_columns` broadcasts the global scalar to every row; `.over(group)` produces a group aggregate aligned to each row. (src: polars, 2026-07-24)
- A comparison against null produces null, and filters retain only true rows, so `filter(pl.col("x") > value)` drops null-valued rows; including those rows requires a separate `.is_null()` condition. (src: polars, 2026-07-24)
- Join null-key behavior is semantic: null keys do not match by default, so inner joins can lose those rows; `nulls_equal=True` enables null-key matches when that is the intended meaning. (src: polars, 2026-07-24)

## Planning and migration

- Lazy scans allow plan-wide predicate and projection pushdown; schema inspection before composing expressions catches wrong names or dtypes. An unfamiliar method's availability and semantics depend on the installed Polars version, not pandas spellings or memory. Lazy execution is an optimization option, not a universal requirement. (src: polars, 2026-07-24)
- pandas datetime format `%f` does not transfer verbatim for fractional seconds: Polars/Chrono uses `%.f`; Polars `cut` takes interior breakpoints, with outer bounds implicit, unlike pandas' explicit `bins` edges. (src: polars, 2026-07-24)

## Detailed references

- [Expression and selector syntax](polars/expressions.md) covers string, temporal, list, struct, casting, conditionals, null handling, and an expression-to-documentation map. (src: polars)
- [Context semantics](polars/contexts.md) details `select`, `with_columns`, `filter`, grouping, windows, sorting, and joins. (src: polars)
- [Lazy scans and plans](polars/lazy-api.md) covers scan options, schema discovery, plan inspection, streaming, and sinks. (src: polars)
- [Pandas translation](polars/pandas-to-polars.md) collects migration traps and output-shape differences. (src: polars)
- [Insight query shapes](polars/insight-recipes.md) has examples for common grouped, temporal, and distribution analyses. (src: polars)

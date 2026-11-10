# Large Parquet row-group reads

Scope: auditing multi-GB Parquet (for example a dataframe artifact stored on object storage) from a memory-constrained workstation without loading it whole.

## Read by row group, keep only small results

- Read by row group with column projection (`ParquetFile.read_row_group(i, columns=[...])`), aggregate per chunk, and keep only small per-chunk results, so peak memory stays near one row group of the selected columns. Sample inside each row group for distributions; for "last row per key", take the last row within each chunk and again across chunks. (src: large-parquet-audit; 2026-10)
- Footer statistics per row group give `null_count` and min/max without reading data. Check `has_null_count` and `has_min_max` before using them, and convert min/max to strings before building a frame (types differ across columns). They catch high-null, constant, and impossible-range columns cheaply; a missing statistic proves nothing about the data. (src: large-parquet-audit; 2026-10)

## Report on one population

- Compare rates on one shared population: put every row in exactly one category and assert the categories sum to the population. A value observed at one instant is not a duration, and "always null when X" does not mean "null implies X". (src: large-parquet-audit; 2026-10)
- Check coverage per unit against an independent source of truth (for example terminal events) rather than a proxy such as half of the unit's span. (src: large-parquet-audit; 2026-10)

See [local-columnar-inspection.md](local-columnar-inspection.md) for footer-only timestamp extrema and population-dependent "earliest" semantics.

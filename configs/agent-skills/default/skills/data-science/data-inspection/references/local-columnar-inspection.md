# Coverage and inspection

## Population and coverage

- Availability metadata and inventory entries do not prove corresponding rows were stored. Define the population before reporting an earliest timestamp: metadata, all stored rows, and a filtered subset can have different extrema.
- Narrow with structured identifiers; text searches need controlled synonyms and exclusions. A missing listing match or a successful sample does not establish population-wide absence or coverage.
- For paginated APIs, bound selected records, request timeouts, and response bytes; do not bypass access refusals. Preserve responses and per-record reports, inspect pagination metadata, follow pages as needed, and reconcile reported counts with collected items. Report sample success separately from qualified population coverage.
- Compare rates on a common population; ensure categories partition that population and their counts sum to it. An observation at an instant is not a duration, and “always null when X” does not imply “null only when X”. Compare coverage with an independent source where available.

## Parquet and asynchronous persistence

- Row-group footer statistics can cheaply identify extrema, nulls, constants, and impossible ranges without decoding data. Check whether each statistic exists; missing statistics do not prove absence. Footer extrema describe the whole row group, not necessarily a filtered subset.
- For limited memory, project needed columns and aggregate one row group at a time using `ParquetFile.read_row_group(i, columns=[...])`. Check `has_null_count` and `has_min_max` before using footer statistics. For last row per key, reduce within and across groups using the intended ordering, not file order unless that is the intended order.
- The [footer scanner](../scripts/parquet_footer_min_ts.py) accepts files or directories and emits JSON lines for timestamp-named INT32/INT64 statistics interpreted as Unix seconds. Its `--min-epoch` and `--max-epoch` defaults bound both extrema; override them for the intended interval. `--limit` stops after matching hits, and errors are emitted as JSON lines. It does not infer units; missing, unsupported, filtered, or failed statistics are not evidence of no data.
- Compare asynchronously persisted datasets using the same fixed row-time window, identity and channel filters; preserve scan time, counts and last timestamps. Repeat after persistence catches up. A recovered tail supports visibility lag for that interval only; check interior buckets and row identities separately, because equal totals do not prove equal rows.

## DuckDB file-backed databases

- DuckDB infers a file-backed database's catalog name from its filename stem. A file named `<name>.duckdb` that also creates schema `<name>` makes two-part SQL (`<name>.table`) ambiguous between catalog and schema. Give the file a distinct name or use three-part names, and test with a real file-backed database, not `:memory:`.

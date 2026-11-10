# Local columnar inspection

Scope: Distinguish descriptive inventories from row-level data and keep data-coverage queries tied to an explicit population.

## Metadata and observed data

- Market metadata fields such as `open_time` and `close_time` describe availability; statistics from a relevant data column (for example, `end_ts`) describe observed Parquet-row coverage. (src: local-columnar-data-inspection)
- A local SQLite inventory can expose tables, schemas, row counts, and provenance fields that narrow a search across large data files; it is an index of the export, not proof that every indexed item has corresponding row data. (src: local-columnar-data-inspection)

## Search scope and extrema

- Structured identifiers or exact ticker fields constrain the search population; title/rules text contributes controlled synonyms and exclusions because broad substrings can match unrelated records. (src: local-columnar-data-inspection)
- “Earliest” is population-dependent: the earliest metadata record, stored row, and row for a filtered subset can differ, so the population determines the timestamp's meaning. (src: local-columnar-data-inspection)
- Footer statistics can answer extrema questions without decoding row data when the relevant column statistics are present; a missing statistic cannot establish that the file has no matching values. (src: local-columnar-data-inspection)
- The bundled [footer scanner](../scripts/parquet_footer_min_ts.py) reads integer INT32/INT64 min/max statistics and interprets them directly as Unix seconds; timestamps encoded in another unit or representation, or lacking usable statistics, are outside that assumption. (src: local-columnar-data-inspection, 2026-06-09)

## Asynchronous persistence comparisons

- For two asynchronously persisted datasets, preserve the exact row-time window, identity and channel filters, scan time, counts and last observed timestamps. Repeat the same fixed window after persistence catches up: newly visible rows that explain an earlier tail deficit support visibility lag for that interval, not completeness in general. Check interior time buckets and population/key compatibility separately; matching totals alone do not establish identical rows. (src: local-columnar-data-inspection; method)

## Reconstructable analysis inputs

- Preserve policy-independent forecast issues and all opportunities, including refusals, missing support, zero fills and untraded siblings; retain execution slices, holdings and pending reservations for later analysis. Retain reconstructable timestamped paths rather than interval extrema alone, and distinguish physical-event evidence, source-body completion, forecast usability and market clocks. (src: reconstructable-analysis-inputs; method)
- Preserve negative receipt-relative lags, gaps, overlapping event associations and interval censoring. Label moves as candidate associations, not causal effects; freeze cutoffs before scoring and distinguish contract payoff determination, observable determination, closure and settlement. (src: reconstructable-analysis-inputs; method)
- Bound storage with durable source identities, verified regeneration inputs, decoders and offsets, numerical settings and random streams. A manifest alone does not keep inputs alive. (src: reconstructable-analysis-inputs; method)

## DuckDB file-backed databases

- DuckDB infers a file-backed database's catalog name from its filename stem. A shadow copy named `<name>.duckdb` that also creates a schema `<name>` makes two-part SQL (`<name>.table`) ambiguous between the catalog and the schema. Give the file a distinct name or use three-part names, and test with a real file-backed database, not `:memory:`. (src: duckdb-catalog-name-collision)

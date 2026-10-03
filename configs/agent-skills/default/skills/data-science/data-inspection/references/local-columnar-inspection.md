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

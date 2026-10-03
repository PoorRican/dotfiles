---
name: data-inspection
description: "Use when inspecting local Parquet, SQLite, JSONL, or partitioned data for schema, provenance, coverage, and timestamp extrema, or when writing/debugging Polars dataframe code and pandas migrations. Covers metadata-versus-row-data distinctions, controlled identifier filtering, Parquet footer statistics, null/window/join semantics, lazy planning, and parsing/API differences."
---

# Data Inspection

Availability metadata and stored-row coverage answer different questions; broad text matches and familiar pandas spellings can also hide scope or API mistakes. The references separate local-file forensics from Polars semantics and point to detailed expression, query-planning, and migration material; the bundled footer scanner is limited to timestamp statistics represented as Unix seconds.

| When you are… | Open |
|---|---|
| Distinguishing metadata availability from actual Parquet/partition coverage, narrowing a search, or deciding which “earliest” population is meant | [references/local-columnar-inspection.md](references/local-columnar-inspection.md) |
| Writing or debugging Polars expressions, grouped values, filters, joins, and lazy scans | [references/polars-correctness-and-performance.md](references/polars-correctness-and-performance.md) |
| Translating pandas idioms, looking up expression syntax, inspecting contexts, query plans, or common analysis shapes | [references/polars-correctness-and-performance.md](references/polars-correctness-and-performance.md) |
| Reading Parquet timestamp extrema without a reader library | [scripts/parquet_footer_min_ts.py](scripts/parquet_footer_min_ts.py) — scans footer statistics only; expects Unix-second timestamp values. |

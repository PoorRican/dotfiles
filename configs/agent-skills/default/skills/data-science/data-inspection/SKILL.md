---
name: data-inspection
description: "Use when inspecting local Parquet, SQLite, JSONL, or partitioned data for schema, provenance, coverage, and timestamp extrema, or when writing/debugging Polars dataframe code and pandas migrations. Covers metadata-versus-row-data distinctions, controlled identifier filtering, Parquet footer statistics, null/window/join semantics, lazy planning, and parsing/API differences. Also covers reading multi-GB Parquet by row group, NumPy dtype traps, and planning a dataset-to-schema consolidation. Also covers bounded paginated API collection and qualified coverage; batched per-entity validation and parity; recorded revision fixture discovery."
---

# Data Inspection

Availability metadata and stored-row coverage answer different questions; broad text matches and familiar pandas spellings can also hide scope or API mistakes. The references separate local-file forensics from Polars semantics and point to detailed expression, query-planning, and migration material; the bundled footer scanner is limited to timestamp statistics represented as Unix seconds.

| When you are… | Open |
|---|---|
| Distinguishing metadata availability from actual Parquet/partition coverage, narrowing a search, or deciding which “earliest” population is meant | [references/local-columnar-inspection.md](references/local-columnar-inspection.md) |
| Writing or debugging Polars expressions, grouped values, filters, joins, and lazy scans | [references/polars-correctness-and-performance.md](references/polars-correctness-and-performance.md) |
| Translating pandas idioms, looking up expression syntax, inspecting contexts, query plans, or common analysis shapes | [references/polars-correctness-and-performance.md](references/polars-correctness-and-performance.md) |
| Reading Parquet timestamp extrema without a reader library | [scripts/parquet_footer_min_ts.py](scripts/parquet_footer_min_ts.py) — scans footer statistics only; expects Unix-second timestamp values. |
| Auditing a multi-GB Parquet file or artifact from a memory-constrained machine (row-group reads, footer null/range stats, shared-population rates) | [references/large-parquet-row-group-reads.md](references/large-parquet-row-group-reads.md) |
| Seeing impossible keys, truncated strings, or odd comparison verdicts from NumPy arrays (fixed-width string dtypes, bool or bytes dtypes) | [references/numpy-array-traps.md](references/numpy-array-traps.md) |
| Planning a consolidation of messy local datasets into a canonical warehouse or data-lake schema before any copy | [references/schema-consolidation-planning.md](references/schema-consolidation-planning.md) |
| Inspecting paginated API responses without mistaking a sample for complete coverage | [references/bounded-api-collection.md](references/bounded-api-collection.md) |
| Optimizing repeated per-entity validation reads while preserving evidence and refusal semantics | [references/batched-validation-parity.md](references/batched-validation-parity.md) |
| Discovering candidate revision fixtures from retained responses and receipts | [references/recorded-revision-fixtures.md](references/recorded-revision-fixtures.md) |

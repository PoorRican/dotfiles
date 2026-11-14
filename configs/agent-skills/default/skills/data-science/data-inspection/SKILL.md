---
name: data-inspection
description: Inspect datasets and paginated records for coverage, integrity, schema, and timestamp extrema; troubleshoot dataframe semantics that can silently alter results.
---

# Data inspection

Availability metadata, file statistics, and observed rows describe different populations. Inspection must preserve that distinction, and dataframe operations can silently change keys, nulls, or row counts.

| When working on | Reference |
|---|---|
| File coverage, Parquet statistics, pagination, or asynchronous persistence | [Coverage and inspection](references/local-columnar-inspection.md) |
| NumPy or Polars correctness and migration traps | [Dataframe traps](references/polars-correctness-and-performance.md) |
| Schema consolidation, batched validation, or recorded revision fixtures | [Integrity and reconciliation](references/schema-consolidation-planning.md) |

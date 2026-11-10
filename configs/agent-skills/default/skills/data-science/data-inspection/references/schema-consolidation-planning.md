# Schema consolidation planning

Scope: the analysis phase before copying or rewriting messy local datasets into a canonical warehouse or data-lake schema. Applying a migration is a separate step with its own owner procedure.

## Validate before proposing a mapping

- Do not propose a merge plan from documents alone. Read the target contract first, then the code that actually implements it, then sample real source files (schemas, SQLite tables, sizes) before mapping. Documents and code disagree often enough that dataset-name drift and partition-naming differences are the first things to check. (src: schema-consolidation-planning; 2026-05)
- Classify every source as canonical facts, canonical business metadata, or operational lineage and sync metadata, and keep the last two out of one table. (src: schema-consolidation-planning; 2026-05)
- Fix source precedence explicitly (newer live data versus a designated canonical source), keep local staging separate from the final archive, and list the unresolved decisions rather than resolving them silently. (src: schema-consolidation-planning; 2026-05)
- Before treating overlapping source roots as independent populations, identify their source history and compare the complete overlap at the intended row identity and scope. Matching samples do not prove containment. Use a complete scoped multiset comparison, such as comparing grouped row counts, so duplicate multiplicity is preserved before asserting that one source has no unique rows. (src: schema-consolidation-planning; method)

## Migration execution and reconciliation

- If multiple input groups can write to the same output partition, allocate part filenames uniquely across the entire run, not just within each group. Exercise the naming scheme on a bounded fixture; preserve failed output for diagnosis and retry only into a fresh destination. (src: schema-consolidation-planning; method)
- Validation while a producer is still changing output is provisional. Run final count, schema and manifest reconciliation only after the producer has exited and output is stable; report failed or rejected input explicitly instead of calling the result lossless. (src: schema-consolidation-planning; method)

See the transfer and symlink checks in the verification skill's destructive-paths reference when the plan ends in a bulk copy.

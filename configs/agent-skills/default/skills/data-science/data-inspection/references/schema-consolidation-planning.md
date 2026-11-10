# Schema consolidation planning

Scope: the analysis phase before copying or rewriting messy local datasets into a canonical warehouse or data-lake schema. Applying a migration is a separate step with its own owner procedure.

## Validate before proposing a mapping

- Do not propose a merge plan from documents alone. Read the target contract first, then the code that actually implements it, then sample real source files (schemas, SQLite tables, sizes) before mapping. Documents and code disagree often enough that dataset-name drift and partition-naming differences are the first things to check. (src: schema-consolidation-planning; 2026-05)
- Classify every source as canonical facts, canonical business metadata, or operational lineage and sync metadata, and keep the last two out of one table. (src: schema-consolidation-planning; 2026-05)
- Fix source precedence explicitly (newer live data versus a designated canonical source), keep local staging separate from the final archive, and list the unresolved decisions rather than resolving them silently. (src: schema-consolidation-planning; 2026-05)

See the transfer and symlink checks in the verification skill's destructive-paths reference when the plan ends in a bulk copy.

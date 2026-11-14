# Skill Library Governance Workflow


### 1. Declare scope and exclusions

Record each requested source root, proposed target root, and exclusions. Classify roots and entries as maintained or shared sources, deployment aliases, project-linked managed skills, runtime/system bundles, package caches, generated memories, or archives. State whether system bundles are comparison baselines or migration candidates. Keep excluded sources visible in the inventory summary.


### 2. Inventory root entries and symlinks

Enumerate immediate root entries as well as recursively discovered `SKILL.md` files. Recursive file search commonly does not traverse directory symlinks, so relying on it alone silently misses deployment aliases and project-linked managed skills.

For each root entry, record its path and type, raw and resolved symlink target, whether the link is valid in the checkout, only after deployment, or broken, and whether `SKILL.md` is present at the resolved root. Follow a root skill symlink once for content inspection; record nested links as bundle entries rather than traversing arbitrary symlink graphs. Account for category containers separately from resident bundles and aliases.


### 3. Parse identity from frontmatter

Record `name`, `description`, source directory basename, malformed or missing frontmatter, directory/name mismatches, and platform or tool metadata relevant to migration. The logical identity is `name`, not the source directory name. A file without valid `name` and `description` is not a valid Hermes skill; repair it or give it an explicit disposition rather than copying it blindly.


### 4. Fingerprint the whole bundle

Compute a deterministic tree fingerprint over each relative entry's path, entry type, executable bit, symlink target, and regular-file bytes. Compare `SKILL.md` separately for diagnostics, but do not infer bundle equality from it alone. For mechanical normalization, whitelist only explicitly understood transformations; preserve both raw and normalized results.


### 5. Detect substantive duplicate families

Group candidates by identical frontmatter name, equivalent trigger descriptions, promised outcome or workflow, renamed near-copies, apparent memory promotion, or a narrow skill whose behavior is covered by a broader one. Read candidate bodies and supporting files before deciding. Similar subject matter is not enough: skills may be complementary specializations. Different names can still compete for the same trigger and produce contradictory instructions.


### 6. Choose the canonical source

Prefer an authoritative, maintainable, portable source adapted to the target runtime. A useful default order is an existing maintained central skill, repository-tracked authoritative source, shared user-managed source, then runtime copy. Treat system bundles as upstream baselines; do not choose caches, generated memories, or backups as canonical without explicit promotion. Do not pick by size, modification time, or apparent novelty alone. Name one base and list valuable deltas to harvest from other versions so update provenance remains clear.

### 7. Build the target map

For each surviving skill, record its target location and frontmatter name, canonical source path or class, action (copy, relocate, normalize, merge, rename, fold, or drop), duplicate family, and portability work. Account for every source entry, including aliases and rejected candidates. Grouped rows are acceptable only when each source skill remains traceable. Use the target's existing organization where it fits; do not assume every catalog is categorized.

### 8. Audit collision and portability risks

Check duplicate frontmatter names, active backups, directory/name mismatches, broken or deployment-relative aliases, hardcoded paths and runtime assumptions, foreign tool dialects, and relative links that relocation will break. Review trigger overlap and contradictory operational or domain rules. Do not erase intentional platform-specific behavior: gate it by platform or rewrite the common workflow in platform-neutral terms.

### 9. Report counts that reconcile

Separate aliases and copied payloads from unique source payloads; then account for payloads already represented in the target and those folded or dropped to arrive at new target bundles. Account for category containers separately rather than treating every root entry as one payload. Report excluded system bundles, caches, memories, and backups separately.

### 10. Verify audit or migration outcomes

For a read-only audit, distinguish pre-existing changes from changes made by the audit; an authorized report outside the source tree is not a source edit. For an executed migration, check valid frontmatter, directory/name agreement, supporting files, resolving relative references, active duplicate names, excluded sources, and target inventory against the decision map.

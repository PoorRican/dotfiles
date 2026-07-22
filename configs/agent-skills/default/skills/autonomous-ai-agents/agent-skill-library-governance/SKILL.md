---
name: agent-skill-library-governance
description: Use when inventorying, deduplicating, categorizing, centralizing, or migrating skills across Claude Code, Codex, Pi/shared agents, OMP, Hermes, or similar agent runtimes. Distinguishes authoritative user-managed skills from system bundles, plugin caches, memories, backups, and symlink aliases; selects canonical full bundles and produces a collision-aware migration map.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [skills, governance, migration, deduplication, provenance, multi-agent]
    related_skills: [hermes-agent-skill-authoring, coding-agent-output-styles, hermes-agent]
---

# Agent Skill Library Governance

## Overview

Govern a skill library as a collection of durable, class-level capabilities rather than a pile of runtime copies. The job is to identify authoritative bundles, preserve provenance, collapse exact and substantive duplicates, normalize platform-specific assumptions, and place each surviving skill in a categorized central tree.

The unit of migration is the **whole skill bundle**: `SKILL.md` plus references, scripts, templates, assets, executable bits, and intentional symlinks. A matching `SKILL.md` alone does not prove two bundles are identical.

## When to Use

Use this skill for:

- Auditing user/global skill roots across multiple agent runtimes
- Designing or reviewing a shared central skill tree
- Migrating skills from one agent format to another
- Finding duplicate skill names, trigger overlap, or divergent forks
- Separating authored skills from generated memories and package caches
- Choosing a canonical source when several runtimes carry copies

Do not use it to author the content of one new skill from scratch; use `hermes-agent-skill-authoring` for that.

## Source Classification Comes First

Before comparing content, classify every discovered path:

1. **Authoritative managed root** — user- or repository-maintained skill bundles.
2. **Shared global root** — one tree intentionally consumed by several agents.
3. **Deployment alias** — a symlink exposing an authoritative bundle to another runtime.
4. **Project-linked managed skill** — active through a global managed root but authored in a project repository.
5. **Bundled/system skill** — shipped by the runtime; treat as an upstream or protected baseline.
6. **Plugin/package cache** — generated install material; never choose it as canonical merely because it is readable.
7. **Project/session memory skill** — generated local learning, not a global skill unless explicitly promoted.
8. **Backup/archive** — evidence for lineage, not an active migration candidate.

Read `references/cross-agent-source-classification.md` for a reusable classification table and decision-record schema.

## Workflow

### 1. Declare scope and exclusions

Record each requested source root, the proposed target root, and exclusions before scanning. State whether bundled/system skills are comparison baselines or migration candidates. Keep caches, memories, and backups visible in the inventory summary even when excluded, so the audit proves they were intentionally separated rather than accidentally missed.

**Complete when:** every root has a source class and an explicit include/exclude decision.

### 2. Inventory root entries and symlinks

Enumerate immediate root entries as well as recursively discovered `SKILL.md` files. Recursive file search commonly does not traverse directory symlinks, so relying on it alone silently misses deployment aliases and project-linked managed skills.

For each root entry, record:

- Entry path and whether it is a directory or symlink
- Raw symlink target and resolved target, if valid
- Whether the link is valid in the source checkout, only after deployment, or broken everywhere
- Presence of `SKILL.md` at the resolved root

Follow a root skill symlink once for content inspection. Do not recursively traverse arbitrary nested symlink graphs; record nested links as bundle entries instead.

**Complete when:** direct-entry counts reconcile with resident bundles, valid aliases, and broken aliases.

### 3. Parse identity from frontmatter

Parse frontmatter before assigning a target. The logical identity is `name`, not the source directory name.

Record:

- `name` and `description`
- Source directory basename
- Missing or malformed frontmatter
- Directory/name mismatches
- Platform/tool metadata relevant to migration

A file without valid `name` and `description` is not a valid Hermes skill. It may be repaired or folded into another skill, but must not be copied blindly.

**Complete when:** every included payload has a parsed identity or an explicit invalid-frontmatter disposition.

### 4. Fingerprint the whole bundle

Compute a deterministic tree fingerprint over each relative entry's:

- Path
- Entry type
- Executable bit
- Symlink target
- Regular-file bytes

Use full-tree comparison to label exact duplicates. Also compare `SKILL.md` separately for diagnostics, but never infer bundle equality from it alone.

For safe mechanical normalization, whitelist only transformations that are explicitly understood, such as removing a generated platform line or normalizing a machine-specific interpreter prefix. Preserve both raw and normalized results.

**Complete when:** exact duplicate claims are backed by full-tree equality or an itemized mechanical diff.

### 5. Detect substantive duplicate families

Exact hashes are only the first pass. Group possible substantive duplicates by:

- Identical frontmatter name
- Equivalent trigger descriptions
- Same promised outcome or workflow
- Renamed near-copies
- A managed skill that appears promoted from a memory skill
- A narrow skill whose entire behavior is already covered by a broader maintained skill

Read candidate bodies and supporting files before deciding. Similar subject matter is not enough: two skills may be complementary specializations. Conversely, different names can still compete for the same trigger and produce contradictory instructions.

**Complete when:** every duplicate family has a canonical source, merge/rename/drop decision, and reason.

### 6. Choose the canonical source

Prefer the source that is authoritative, maintainable, portable, and already adapted to the target runtime. A useful default order is:

1. Existing maintained central skill
2. Repository-tracked authoritative source
3. Shared user-managed global source
4. Runtime copy

Never choose plugin caches, generated memories, or backups as canonical unless the user explicitly promotes them. Do not pick by size, modification time, or apparent novelty alone. When one version is the better base but another contains valuable deltas, name the base as canonical and list the deltas to harvest.

### 7. Build the categorized target map

Map each surviving frontmatter name to an existing broad category. Use nested established domains when the target already supports them, for example `mlops/evaluation`. Avoid inventing a top-level category for one or two skills.

Each map row should include:

- Target category and frontmatter name
- Canonical source path or source class
- Action: copy, relocate, normalize, merge, rename, fold, or drop
- Duplicate family, if any
- Portability work required

Account for every source-root entry, including aliases and rejected candidates. Grouped rows are acceptable only when each source skill remains traceable.

### 8. Audit collision and portability risks

Check at least:

- Globally duplicate frontmatter names
- Active backups such as `.bak` directories
- Top-level uncategorized skills in a categorized target
- Directory/frontmatter name mismatches
- Broken or deployment-relative aliases
- Hardcoded home directories, project paths, model names, or runtime versions
- Foreign tool dialects (`Task`, `AskUserQuestion`, `WebFetch`, runtime-specific edit tools)
- Relative links to support files or project documentation that relocation will break
- Trigger overlap between broad process skills and narrow domain skills
- Contradictory operational or domain rules across skills

Do not erase intentional platform-specific behavior. Gate it by platform or rewrite the common workflow in platform-neutral terms.

### 9. Report counts that reconcile

Provide a compact accounting chain:

```text
source-root entries
- alias/copy duplicates
= unique source payloads
- existing canonical skills
- folded or dropped payloads
= new target bundles
```

Also report excluded system, cache, memory, and backup counts separately. This catches silent omissions and makes the proposed tree size reviewable.

### 10. Verify read-only and migration outcomes

For a read-only audit, verify that no audit-generated files or edits were made. A pre-existing dirty worktree is not evidence the audit changed it; report the distinction.

For an executed migration, verify:

- Every target bundle has valid frontmatter
- Directory name matches frontmatter name
- All supporting files arrived
- Relative references still resolve
- No active duplicate names remain
- Excluded caches/memories/backups were not copied
- Target inventory count matches the decision map

## Common Pitfalls

1. **Recursive search as the only inventory.** It often misses directory symlinks. Reconcile recursive results with immediate root entries.
2. **Hashing only `SKILL.md`.** Supporting scripts or references may differ materially. Compare complete trees.
3. **Treating every file called `SKILL.md` as global.** Caches and project memories frequently contain them.
4. **Using directory names as identity.** Frontmatter may declare a different name and collide elsewhere.
5. **Copying backups into the active tree.** Backups create duplicate logical names and stale behavior.
6. **Selecting the largest version as canonical.** Larger may mean stale, platform-specific, or sedimented.
7. **Merging related but complementary skills.** Keep specializations when their triggers and outcomes are genuinely distinct; tighten descriptions instead.
8. **Ignoring contradictory overlaps.** Two valid skills can disagree on fees, safety gates, or execution semantics. Resolve the rule, not just the name.
9. **Moving bundles without rewriting links.** Project-relative references and scripts commonly break after centralization.
10. **Losing provenance.** Preserve the canonical source and alias lineage so future updates flow from the right place.

## Verification Checklist

- [ ] Every requested source root classified
- [ ] Immediate root entries reconciled with recursive discovery
- [ ] Root symlinks and broken aliases recorded
- [ ] Frontmatter identity parsed for every included payload
- [ ] Exact duplicates proven at full-bundle level
- [ ] Substantive duplicate families reviewed manually
- [ ] One canonical source selected per family
- [ ] Every source entry has a migration disposition
- [ ] Target paths use broad existing categories
- [ ] Tool/path/reference portability risks listed
- [ ] Caches, memories, system bundles, and backups counted separately
- [ ] Counts reconcile to the proposed target total
- [ ] Read-only or executed-migration state verified

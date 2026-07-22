# Cross-Agent Skill Source Classification

Use this reference when a machine has several agent runtimes and many paths containing `SKILL.md`.

## Source classes

| Class | Common examples | Include in canonical migration? | Canonical-source rule |
|---|---|---:|---|
| Repository-managed skill | Dotfiles or a maintained project skill directory | Yes | Prefer the tracked source over deployed copies |
| Shared global skill root | `~/.agents/skills`, or another root intentionally consumed by several agents | Yes | Treat one physical bundle as canonical; record all runtime aliases |
| Runtime user skill root | User-managed `skills/` under a runtime home | Yes | Include resident bundles; compare against repo/global sources |
| Deployment alias | A symlink from one runtime root to another skill bundle | No separate payload | Resolve once, inventory the target, and retain alias provenance |
| Project-linked managed skill | A global managed-root symlink into a project repository | Usually yes | The project target is authoritative; centralization may require rewriting project-relative links |
| Bundled/system skill | Runtime-shipped or hidden system skill directories | Usually baseline only | Treat as protected/upstream unless explicitly vendoring |
| Plugin/package cache | Plugin install cache, package manager tree, `node_modules`, remote catalog cache | No | Never promote the cache path; locate its maintained upstream if needed |
| Project/session memory skill | Memory-generated skill under a project/session memory tree | No by default | Promote only after explicit review; prefer an already-promoted managed version |
| Backup/archive | `.bak`, snapshots, curator archives | No active copy | Use for lineage and delta recovery only |

## Discovery rule

Use two complementary views:

1. **Recursive skill discovery** finds resident `SKILL.md` files.
2. **Immediate root-entry inspection** finds symlinked skill directories that recursive search may not traverse.

Reconcile them as:

```text
resident bundles + valid root aliases + broken root aliases = direct root entries in scope
```

A relative alias may be dangling inside a source checkout but valid at its deployment location. Record both facts; do not label the design invalid solely from the checkout view.

## Full-tree exactness

A deterministic bundle fingerprint should include, in sorted relative-path order:

```text
relative path
entry type
executable bit
symlink target or file bytes
```

Two identical `SKILL.md` files with different scripts, references, assets, permissions, or symlink targets are not exact duplicate bundles.

## Substantive-duplicate decision record

For every reviewed family, record:

```yaml
family: logical capability or colliding name
members:
  - source: source class/path
    frontmatter_name: parsed name
    relation: exact | near-copy | overlapping-trigger | specialization | lineage
canonical: chosen source
reason: why it is authoritative and portable
action:
  - copy | relocate | normalize | merge | rename | fold | drop
harvest:
  - valuable deltas from non-canonical members
risks:
  - name, trigger, tool, path, or domain-rule conflicts
```

## Canonical selection questions

Ask in order:

1. Which path is actually maintained?
2. Is a central or target-native version already present?
3. Are copies byte-identical at full-tree level?
4. Does one version contain runtime-specific commands or stale model names?
5. Are the skills true duplicates, or complementary specializations?
6. Would relocation break support-file or project-document references?
7. Does any candidate contain a domain rule that contradicts another candidate?

Choose one base even when merging deltas. “Merge both” without naming a canonical base loses update provenance.

## Migration-map accounting

Keep aliases separate from payload counts:

```text
root entries
- deployment aliases and exact copied payloads
= unique payloads
- payloads already represented by the target
- malformed, folded, or intentionally dropped payloads
= new target bundles
```

Report system/bundled skills, plugin caches, memories, and backups outside this equation. They are source classes, not silent omissions.

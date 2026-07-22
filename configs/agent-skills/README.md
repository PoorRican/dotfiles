# Central agent skills

This directory is the source of truth for user-managed skills shared by coding agents.
It deliberately separates curated skill content from each agent's mutable runtime state,
plugin caches, memories, system bundles, and updater bookkeeping.

## Layout

```text
configs/agent-skills/
├── default/
│   └── skills/
│       └── <category>/[<subcategory>/]<skill>/
│           ├── SKILL.md
│           └── ... supporting files
├── <host>/
│   └── skills/
│       └── <category>/<skill>/
└── collections.nix
```

`default/skills` is portable across machines. A host tree is an additive overlay;
for example, cbox-only skills live under `cbox/skills`. Skill directory basenames
match their `SKILL.md` frontmatter names and names must be globally unique across
the default and selected host trees.

Categories follow Hermes's categorized organization. Nested categories such as
`mlops/training` are allowed. Skills are always complete bundles: `SKILL.md` plus
references, scripts, templates, assets, executable bits, and intentional links.

## Distribution

`nix/modules/agent-skills.nix` recursively scans the selected categorized trees.

`collections.nix` separates catalog storage from distribution:

- `coding` is the explicit allowlist shared by coding agents.
- `hermes` is additive; Hermes receives `coding` plus the Hermes-specific list.
- `hosts.<name>` adds narrowly scoped skills for one machine.

- **Hermes** receives an immutable categorized Nix-store view through
  `skills.external_dirs`. Its mutable `$HERMES_HOME/skills` directory remains local
  runtime state, and `.no-bundled-skills` prevents Hermes updates from reseeding the
  bundled catalog.
- **Claude Code** receives a Nix-built flat union under `~/.claude/skills`.
- **Codex** receives a Nix-built flat union under `~/.codex/skills`.
- **Pi** receives a Nix-built flat union under `~/.pi/agent/skills`.
- **OMP** receives a Nix-built flat union under `~/.omp/agent/skills`.
- **OpenCode** receives a Nix-built flat union under
  `~/.config/opencode/skills`.

Coding agents receive only the names in the explicit `coding` collection, not the
entire catalog. Home Manager links each selected top-level member of the Nix-built
views into the agent's mutable skill root; it does not recursively expand bundles
during Nix evaluation. Unrelated runtime entries such as Codex's `.system` directory
therefore remain possible. A same-name legacy entry is replaced by the centralized
copy.

OMP's `~/.omp/agent/managed-skills` remains agent-owned and is never managed by this
module. OMP can continue creating and updating skills there independently of the
portable coding collection published under `~/.omp/agent/skills`.

## Inclusion policy

The initial catalog migration incorporated:

- live Hermes skills, excluding backups and runtime metadata;
- repository-managed Claude Code skills;
- direct Codex user skills, excluding `.system`;
- shared user skills from `~/.agents/skills`;
- a snapshot of selected OMP-managed skills, pending provenance review and removal
  from the portable catalog.

It intentionally excluded:

- agent plugin/marketplace/package caches;
- runtime-provided system skills;
- project, session, and memory-generated skills;
- Hermes `.bak`, curator, usage, hub, and bundled-manifest state.

## Adding or promoting a skill

1. Decide whether the skill is portable (`default`) or genuinely host-specific.
2. Place the complete bundle under `skills/<category>/<skill-name>`.
3. Ensure the directory basename equals the frontmatter `name`.
4. Ensure no other selected skill exposes the same name.
5. Add the skill name to `coding`, `hermes`, or a host collection only when it should
   be distributed by that collection.
6. Run all-host Home Manager evaluation before committing. The Nix module rejects
   duplicate names, uncategorized skills, backup/hidden paths, and invalid names.
7. Apply Home Manager to publish the new immutable views.

Hermes-created and agent-memory skills remain runtime-local until explicitly reviewed
and promoted. Agent updates must not write into this library automatically.

## Validation

From the repository root:

```sh
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.dgx.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.emc.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.mbp.activationPackage.drvPath' --no-write-lock-file
```

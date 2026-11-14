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

`nix/lib/agent-skills.nix` scans the categorized trees; `nix/modules/agent-skills.nix`
publishes the coding collection, and `nix/modules/hermes.nix` builds one
categorized view per Hermes profile from the same roots.

`collections.nix` separates catalog storage from distribution:

- `coding` is the explicit allowlist shared by coding agents.
- `hermes` is additive; the default Hermes profile receives `coding` plus this list.
- `hermesBundled` names upstream Hermes-bundled skills the default profile
  exposes without seeding the full bundled catalog.
- `hosts.<name>` adds narrowly scoped skills for one machine.

- **Hermes** profiles receive immutable categorized Nix-store views through
  `skills.external_dirs`, selected per profile by
  `programs.hermes.profiles.<name>.skills.names`. Named profiles (including
  private ones from another flake) pick their own names and may add private
  roots; nothing is inherited automatically. An optional second view per
  profile exposes only the upstream Hermes-bundled skills named in
  `skills.bundledNames` (the default profile takes them from
  `collections.nix`'s `hermesBundled` allowlist). The mutable
  `$HERMES_HOME/skills` directory remains local runtime state, and
  `.no-bundled-skills` prevents Hermes from reseeding the full bundled
  catalog. See `configs/hermes/README.md`.
- **OMP** receives a Nix-built flat union under `~/.omp/agent/skills`.

OMP receives only the names in the explicit `coding` and `omp` collections, not
the entire catalog. Home Manager links each selected top-level member of the
Nix-built view into the agent's mutable skill root; it does not recursively
expand bundles during Nix evaluation. Unrelated runtime entries with other names
therefore remain possible. A same-name legacy entry is replaced by the
centralized copy.

OMP's `~/.omp/agent/managed-skills` remains agent-owned and is never managed by this
module. OMP can continue creating and updating skills there independently of the
portable coding collection published under `~/.omp/agent/skills`.

## What belongs here

The catalog holds what some collection or profile actually loads. A skill that
nothing selects is removed rather than kept in case; git history has it.

A skill holds the reusable judgement and procedure an agent needs for a piece of
work and would not otherwise have:

- **Workflow skills** (interviews, planning, review, task protocols): the steps,
  decision points, question sets, templates and tool calls. The procedure is the
  product; keep it complete and state defaults as defaults, not as law.
- **Tool skills** (a CLI, service, SDK or host procedure): the invocation surface
  an agent cannot cheaply discover or would get wrong, and every trap. Link to
  upstream documentation instead of copying it.
- **Judgement skills** (debugging, verification, evaluation, engineering
  practice): traps with their mechanism, decision rules and trust checks. Generic
  truths and textbook material stay out.

Results, incident narration, dates, provenance tails and rules learned from one
case do not belong in any of them. Each statement lives in one skill.

This repository is public. A skill here carries no facts about private projects,
their repositories, hosts beyond this flake's own, people, addresses, volume
labels or measurements. Private knowledge lives in a private catalog that a
private flake adds with `skills.roots`.

Upstream copies stay as close to upstream as their use allows, so they can be
refreshed; local additions go in a clearly separate reference file. Agent
plugin and package caches, runtime-provided system skills, and project, session
and memory-generated skills are never part of the catalog.

## Adding or promoting a skill

1. Decide whether the skill is portable (`default`) or genuinely host-specific.
2. Place the complete bundle under `skills/<category>/<skill-name>`.
3. Ensure the directory basename equals the frontmatter `name`.
4. Ensure no other selected skill exposes the same name.
5. Add the skill name to `coding`, `hermes`, or a host collection only when it should
   be distributed by that collection. To allow an upstream Hermes-provided skill
   without importing the whole bundled catalog, add its frontmatter `name` to
   `hermesBundled` instead, and remove that name from the relevant
   `configs/hermes/<profile>/config.nix` `skills.disabled` list if present.
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

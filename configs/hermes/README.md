# Hermes profiles

`nix/modules/hermes.nix` installs the upstream Hermes package and owns the
declared configuration of each profile. `config.yaml` is replaced, not merged
with runtime edits: a key removed from Nix disappears on the next
`home-manager switch`. Runtime learning stays runtime-owned.

The runtime comes from the upstream package; profile management uses this local
adapter rather than `inputs.hermes-agent.homeManagerModules.default`. Internal
Python helpers live in `scripts/hermes/` and use Hermes' packaged interpreter:
`render-config.py` runs at build time; `seed-file.py` and `reconcile-cron.py` run
during activation. The renderer adds the installed schema version and rejects
unknown top-level settings; it is not a separate Hermes installation.

| Nix owns (replaced on activation) | Runtime owns (preserved after initialization) |
|---|---|
| `config.yaml`, `.managed`, `.no-bundled-skills` | `.env`, `auth.json`, OAuth tokens |
| `SOUL.md` and `files.*` | `memories/`, `sessions/`, `state.db`, logs, caches |
| the immutable skill view (`skills.external_dirs`) | the mutable `$HERMES_HOME/skills` overlay |
| cron jobs declared in `cron.jobs` | cron jobs created by the agent or `hermes cron` |
| `~/.local/bin/<profile>` launchers, gateway units | |
| `seedFiles.*` supplies initial snapshots only | existing seed destinations, even when empty or different |

`.managed` puts the profile in Hermes' managed mode: `hermes setup`,
`hermes config set`, `hermes model`, `hermes gateway install` and `hermes update`
refuse to run and name Home Manager instead. Secrets go into `$HERMES_HOME/.env`
by hand; `hermes login` still writes `auth.json`.

## Profiles

`programs.hermes.profiles.default` is `~/.hermes`. Any other attribute name is a
named profile at `~/.hermes/profiles/<name>`, reachable as `hermes -p <name>`
or through the generated `<name>` launcher. Every enabled profile gets:

- `settings` — the complete non-secret `config.yaml`. Only deviations from the
  Hermes defaults belong here; the build injects `_config_version` from the
  installed package and fails on top-level keys that release does not know.
  Definitions from several modules merge per key; override an existing leaf
  with `lib.mkForce`.
- `soul` / `files` — `SOUL.md` and extra files below `HERMES_HOME`, installed as
  owner-only copies on every activation (executables keep their bit).
- `seedFiles` — initial snapshots copied only when the destination is absent.
  Existing files remain runtime-owned; changing or removing a seed declaration
  does not replace or delete them. See [Runtime seeds](#runtime-seeds).
- `skills.names` — the explicit allowlist, resolved against
  `programs.agent-skills.catalogRoots` plus the profile's own `skills.roots`.
  Names must be unique across all roots. `skills.allowBundled` re-enables
  bundled-skill seeding; it is off so the catalog stays the only source.
  Hermes scans the mutable `$HERMES_HOME/skills` *before* the Nix view and
  refuses to load a name present in both, so a profile that predates Nix
  ownership must have its old local copies moved aside (never deleted) before
  the allowlist is what the agent actually sees. `hermes -p <name> skills list`
  should then show exactly the allowlisted names; "builtin" in its Source
  column only means a name matches the bundled manifest, not that the package
  tree is scanned.
- `cron.jobs.<name>` — reconciled into `cron/jobs.json` through Hermes' own
  cron API at activation. Jobs carry `managed_by: nix`; a job removed from Nix
  is removed from the profile, everything else in `jobs.json` is left alone.
- `gateway.enable` — a `hermes-gateway[-<name>]` user unit (launchd agent on
  Darwin) running `hermes [-p <name>] gateway run` from the Nix package. A unit
  that `hermes gateway install` wrote earlier is moved to
  `~/.local/state/hermes/pre-nix-units/` on the first activation.

The default profile's policy lives in `default/config.nix` and `default/SOUL.md`;
its skills are `coding ++ hermes` (plus the host overlays) from
`configs/agent-skills/collections.nix`. Hosts add to it in `nix/hosts/<host>.nix`
(see `mbp.nix` for MCP servers and `cbox.nix` for LAN providers and the gateway).

## Runtime seeds

Use `seedFiles`, not `files`, for an initial memory snapshot:

```nix
programs.hermes.profiles.my-agent.seedFiles."memories/USER.md" = ./USER.md;
```

A new destination receives a regular mode-0600 copy, not a store symlink.
Publication never replaces an existing directory entry, including an empty file
or a dangling symlink. If an agent creates the destination during activation,
its file wins. Existing destination symlinks and non-regular files are preserved
without reading them; symlink parents are refused.

Ordinary activation prints one status per seed: **seeded**, **matches snapshot;
preserved**, or **differs from snapshot; preserved**. `home-manager --verbose
switch` additionally prints a unified text diff, with the stored snapshot as
`---` and the runtime file as `+++`. Non-UTF-8/binary differences get a status,
not a content dump. `--dry-run` performs read-only comparison (and verbose
diffs), reporting missing files as **would seed** without creating anything.

Paths must be normalized and relative. Seed declarations cannot overlap
Nix-owned files, `cron/jobs.json`, another seeded file's path, or the default
home's nested `profiles/` subtree.

Snapshot promotion is manual: review runtime learning, then deliberately update
the source snapshot. Activation never copies runtime content back into the
repository. Keep personal snapshots in the private profile repository, not
these public configs. **Private does not mean secret:** seed sources enter the
locally readable Nix store, and verbose diffs may expose personal information
in terminal logs. Never put credentials in a seed.

## Privileged profiles: public policy, private knowledge

A profile can be declared here and completed from a private repository,
because every option of `programs.hermes.profiles.<name>` merges across
modules: `skills.names` and `skills.roots` concatenate, `cron.jobs` merges by
name, `settings` merges per key (`lib.mkForce` overrides a public leaf).

dotfiles keeps the **policy** — model, toolsets, limits, public catalog picks,
gateway — in `nix/hosts/<host>.nix` and `configs/hermes/<profile>/`. The
private repository (`~/kairos/agent-profiles`) supplies the persona, private
skill bundles *and their names*, initial memory snapshots, and scheduled work; none of that appears in
this repository. `k-research-agent` on cbox is the first profile built this way.

### How the private repository is composed

`flake.nix` takes it as a flake input pinned to a local clone:

```nix
agent-profiles = {
  url = "git+file:///home/swe/kairos/agent-profiles";
};
```

and appends `inputs.agent-profiles.homeManagerModules.cbox` to cbox's modules.
The private flake has no dependencies: it exports the existing host module and
uses Home Manager, packages, and module arguments supplied by dotfiles.
`git+file` keeps the lock tied to a committed revision rather than the working
directory. The lock records the local URL, a commit and a narHash; private
configuration stays in the private repository.

Only cbox composes a private module today; mbp, dgx, emc and wst still evaluate
without consuming that export. A missing required export fails cbox evaluation
loudly rather than silently dropping the private profile.

Update the private pin from a host with the clone, after committing all files
referenced by the export. An older locked revision without the new flake/module
cannot supply it; use the path override below while reviewing uncommitted work.
The earlier clone-absence command matrix covered the non-flake input, not this
flake conversion; it is not evidence for clone-absent lock operations here.

### Changing the private half

```sh
# in ~/kairos/agent-profiles
git commit …
# in ~/dotfiles, on a host with the clone
nix flake update agent-profiles
home-manager switch --flake .#cbox
```

To try uncommitted private changes first:

```sh
home-manager switch --flake .#cbox \
  --override-input agent-profiles path:$HOME/kairos/agent-profiles --no-write-lock-file
```

Adding a host: create `home/<host>.nix` in the private repository, export it as
`homeManagerModules.<host>` from its flake, and add
`inputs.agent-profiles.homeManagerModules.<host>` to that host's dotfiles module
list. Clone the private repository at the same path on that host.

## Skill provenance

The audit that preceded this module preserved every live skill bundle under
`~/.local/state/hermes-profile-audit/<timestamp>/` on cbox. It found no
research skill absent from public baselines; the six sysadmin bundles absent
from the catalog are the material for the private repository's `skills/` root.

## Verification

```sh
nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file
home-manager switch --flake .#<host> --dry-run
hermes doctor                     # "Config version up to date"
hermes config set agent.max_turns 1   # refused: managed by home-manager
hermes cron list                  # Nix jobs show managed_by: nix in cron/jobs.json
systemctl --user status hermes-gateway.service
```

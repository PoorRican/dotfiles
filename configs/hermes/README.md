# Hermes profiles

`nix/modules/hermes.nix` installs the upstream Hermes package and owns every
non-secret part of each Hermes profile. Nothing is merged with what Hermes
wrote at runtime: a key removed from Nix disappears from the profile on the
next `home-manager switch`.

| Nix owns (replaced on activation) | Runtime owns (never touched) |
|---|---|
| `config.yaml`, `.managed`, `.no-bundled-skills` | `.env`, `auth.json`, OAuth tokens |
| `SOUL.md` and `files.*` | `memories/`, `sessions/`, `state.db`, logs, caches |
| the immutable skill view (`skills.external_dirs`) | the mutable `$HERMES_HOME/skills` overlay |
| cron jobs declared in `cron.jobs` | cron jobs created by the agent or `hermes cron` |
| `~/.local/bin/<profile>` launchers, gateway units | |

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
  owner-only copies (executables keep their bit).
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

## Privileged profiles: public policy, private knowledge

A profile can be declared here and completed from a private repository,
because every option of `programs.hermes.profiles.<name>` merges across
modules: `skills.names` and `skills.roots` concatenate, `cron.jobs` merges by
name, `settings` merges per key (`lib.mkForce` overrides a public leaf).

dotfiles keeps the **policy** — model, toolsets, limits, public catalog picks,
gateway — in `nix/hosts/<host>.nix` and `configs/hermes/<profile>/`. The
private repository (`~/kairos/agent-profiles`) supplies the persona, private
skill bundles *and their names*, and scheduled work; none of that appears in
this repository. `k-research-agent` on cbox is the first profile built this way.

### How the private repository is composed

`flake.nix` takes it as a non-flake input pinned to a local clone:

```nix
agent-profiles = {
  url = "git+file:///home/swe/kairos/agent-profiles";
  flake = false;
};
```

and appends `inputs.agent-profiles + "/home/<host>.nix"` to the host's
modules. `git+file` rather than `path:` because a `path:` input copies `.git`
into the store and its narHash then changes with git internals. The lock
records only a `file://` URL, a commit and a narHash. Only committed content
in the private clone is visible to Nix.

Inputs are fetched lazily, so hosts that do not compose it (mbp, dgx, emc, wst
today) evaluate and switch without the clone present — verified by hiding the
clone and evicting its store copy. What still needs the clone, because it
resolves or evaluates every input or every host:

| Command | Without the clone |
|---|---|
| `home-manager switch --flake .#<other host>` | works |
| `nix flake metadata`, `nix flake lock`, `nix flake update <other input>` | work |
| editing `flake.nix` (unrelated inputs, hosts, modules), then switching another host | works: the implicit re-lock keeps the pinned node |
| editing the `agent-profiles` input itself, or a lock without its node | fails on every host until re-locked |
| `nix flake update` (all inputs), `nix flake show`, `nix flake check` | fail |
| anything evaluating `.#homeConfigurations.cbox` | fails loudly |

Run those from cbox or wst, and re-lock there before another host switches
after touching the `agent-profiles` input line. If the clone is missing or the
locked commit lacks the module, evaluation fails with a clear "does not exist"
error; it never silently drops the private profile.

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

Adding a host: create `home/<host>.nix` in the private repository, append the
input path to that host's modules in `flake.nix`, and clone the repository at
the same path on that host.

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

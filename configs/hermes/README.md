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

## Privileged profiles from a private flake

Profiles that hold business secrets or private skills do not live here. A
private flake extends a host's home instead:

```nix
{
  inputs.dotfiles.url = "github:PoorRican/dotfiles";

  outputs = { dotfiles, ... }: {
    homeConfigurations.wst = dotfiles.homeConfigurations.wst.extendModules {
      modules = [ ./home/hermes-privileged.nix ];
    };
  };
}
```

```nix
# home/hermes-privileged.nix
{ lib, ... }: {
  programs.hermes.profiles.k-system-admin = {
    skills.roots = [ ./skills ];          # <category>/<skill>/SKILL.md, private
    skills.names = [
      "linux-system-debugging"            # from the public catalog
      "kubernetes-node-storage-debugging" # from ./skills
    ];
    soul = ./k-system-admin/SOUL.md;
    settings = {
      model = { default = "gpt-5.5"; provider = "openai-codex"; };
      toolsets = [ "terminal" "file" "web" "skills" "memory" "cronjob" ];
    };
    cron.jobs.nightly-audit = {
      schedule = "0 3 * * *";
      prompt = "Audit the node and report anomalies.";
      skills = [ "kubernetes-node-storage-debugging" ];
      deliver = "discord:#ops";
    };
    gateway.enable = true;
  };
}
```

Switch with `home-manager switch --flake ~/repos/personal-nixos-hosts#wst`.
The extended configuration reuses this flake's `pkgs` and special args, so the
private module sees the same `dotfiles` path and Hermes package. The same
pattern adds `k-research-agent` on cbox and the privileged sysadmin profile
there.

## Skill provenance

The audit that preceded this module preserved every live skill bundle under
`~/.local/state/hermes-profile-audit/<timestamp>/` on cbox; the six sysadmin
bundles absent from the catalog and the eight divergent research bundles are
the material for the private flake's `skills/` roots.

## Verification

```sh
nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file
home-manager switch --flake .#<host> --dry-run
hermes doctor                     # "Config version up to date"
hermes config set agent.max_turns 1   # refused: managed by home-manager
hermes cron list                  # Nix jobs show managed_by: nix in cron/jobs.json
systemctl --user status hermes-gateway.service
```

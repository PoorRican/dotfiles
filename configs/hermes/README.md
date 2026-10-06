# Hermes profiles

`nix/modules/hermes.nix` installs the upstream Hermes package and owns the
declared configuration of each profile. `config.yaml` is replaced, not merged
with runtime edits: a key removed from Nix disappears on the next
`home-manager switch`. Runtime learning stays runtime-owned.

The runtime comes from the upstream package; profile management uses this local
adapter rather than `inputs.hermes-agent.homeManagerModules.default`. The
seed-file and review-only capture helpers and their tests live in
`scripts/hermes/`; the renderer and cron helper remain in
`nix/modules/hermes/`. All use Hermes' packaged interpreter. `render-config.py`
runs at build time; `seed-file.py` and `reconcile-cron.py` run during
activation. `hermes-profile-capture` is an explicit review-only command; it
does not run during activation. The renderer adds the installed schema version
and rejects unknown top-level settings; it is not a separate Hermes
installation.
The renderer uses Hermes' own YAML compatibility module, keeping its YAML
read/write policy aligned with the installed runtime without adding PyYAML.

| Nix owns (replaced on activation) | Runtime owns (preserved after initialization) |
|---|---|
| `config.yaml`, `.managed`, `.no-bundled-skills` | `.env`, `auth.json`, OAuth tokens |
| `SOUL.md` and `files.*` | `memories/`, `sessions/`, `state.db`, logs, caches |
| the immutable skill view (`skills.external_dirs`) | the mutable `$HERMES_HOME/skills` overlay |
| cron jobs declared in `cron.jobs` | cron jobs created by the agent or `hermes cron` |
| `~/.local/bin/<profile>` launchers, gateway units | |
| `seedFiles.*` supplies initial snapshots only | existing seed destinations, even when empty or different |

`.managed` puts the profile in Hermes' managed mode: commands that persist
configuration, including model selection, refuse writes and name Home Manager
instead. Change model policy in Nix and apply it with `home-manager switch`;
`hermes model --refresh` refreshes the runtime-owned model catalog, not the
declared model configuration. OAuth credentials remain runtime-owned:
`hermes auth refresh openai-codex` refreshes a pooled Codex credential.
Secrets go into `$HERMES_HOME/.env` by hand.

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

The shared default is `gpt-6.1-sol` through `openai-codex` at the ChatGPT Codex
endpoint. cbox retains LM Studio as an optional custom provider; its former
Spark/RadixArk Qwen entry is disabled. Keep the model, provider, and endpoint
together when changing policy: a mismatched current model can appear in the
wrong provider's picker.

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

## Review-only profile captures

`hermes-profile-capture` is installed alongside Hermes on every Hermes-enabled
host. Its wrapper runs the capture command with Hermes' sealed Python interpreter
and provides Git for read-only source provenance. It reads the current host's
Nix-generated deployment-info file, so `--profile` must name an enabled profile
on that host; `k-research-agent` is currently enabled on cbox.

Capture the runtime state of that profile for review:

```sh
hermes-profile-capture --profile k-research-agent
```

To also import the private skill source for comparison with the deployed view,
select that source explicitly:

```sh
hermes-profile-capture --profile k-research-agent \
  --source private-skills="$HOME/kairos/agent-profiles/skills"
```

Each `--source` is a deliberate `LABEL=PATH` selection; prefer a narrow skill
root rather than the whole private repository. In a Git repository the capture
includes selected tracked and untracked, non-ignored regular files, but never
`.git` or ignored files. It records scoped Git status and revision information
without staging, editing, checking out, committing, or otherwise changing the
source tree. The private repository's working changes remain untouched.

The command prints the created snapshot path. By default it creates a new
directory under
`$XDG_STATE_HOME/hermes/captures/<hostname>/k-research-agent/<UTC-timestamp-and-unique-suffix>`
(`$HOME/.local/state` is used when `XDG_STATE_HOME` is unset). `--output PATH`
selects an exact destination directory, which must not already exist. The
capture is built in private staging, the destination is exclusively created,
and `manifest.json` is written last as the completion marker. An existing
destination is never overwritten; a failed publication removes only the
destination/staging it created.

The snapshot is a review artifact, not a promotion path. Its manifest separates
runtime state (`runtime/skills/` overlay and mutation ledger, runtime
skill-history blobs, memories, and `SOUL.md`), explicitly selected source trees
(`sources/LABEL/`), and the deployed skill view (bundle/file hashes inventoried
from the profile's actual `skills.external_dirs`). Old
`runtime/skills/.curator_backups/` snapshots are not copied; skill history is
limited to `runtime/skill-history/`. History blobs require matching content hashes
and non-credential path references in the captured mutation ledger; blobs linked
to excluded credential paths or lacking verifiable references are omitted.
Malformed ledgers and corrupt or missing referenced blobs abort capture; a
missing ledger omits history. It also records the declared package and flake-input
revisions, declared versus live config hashes, and declared versus actual skill
directories. Config drift is a byte-level comparison, so formatting
changes can differ even when settings are equivalent. Package metadata describes
the Nix declaration, not an attestation of a running gateway process. The
store-backed deployment-info contains only paths and revision metadata: it does
not serialize profile settings or full `config.yaml`. The capture records only an
integer live config version; other version values are treated as unknown rather
than exported as configuration payloads.

The Hermes package revision comes from the shared `hermes-agent` input.
Additional input revisions are opt-in through
`programs.hermes.capture.sourceRevisions` and appear in the optional
`source_revisions` map. cbox declares `agent-profiles` because it composes that
private input; `agent_profiles_revision` mirrors the map entry. Other hosts
leave the map empty, so they do not force the local-only private input during
evaluation.

Snapshots can still contain sensitive persona, memory, skill, and other user
text; capture is not a general content redactor. Its case-insensitive secret
filename exclusions include `.env`/`.env.*`, `auth.json`, `vault.key`,
`vault.json.enc`, `credentials.json`/`credentials.*`, `id_rsa`, `id_ed25519`,
and `.key`, `.pem`, `.p12`, or `.pfx` files; `.git` is also excluded. Review
the result before sharing or committing it. Keep captures private. Do not use
Hermes full-backup or curator backup commands as a substitute: those have
separate backup/retention behavior.

Import is not promotion. The capture command does not modify the runtime profile,
selected source files, their Git index, or the flake lock. Its only writes are
the new review snapshot and any missing destination directories. An explicitly
selected output can live in a separate review area of a repository, but cannot
overlap an input tree. Review the snapshot first. If changes should become a
durable source snapshot, make and commit those changes in the private repository
as a separate manual action. Updating the `agent-profiles` pin in dotfiles is
another separate manual action, and applying it with Home Manager is a further
explicit action.
None of these steps is performed by capture:

1. Review the capture before deciding whether any source change should be
   promoted.
2. If intentionally promoting reviewed source changes, commit those changes in
   the private repository:

   ```sh
   cd "$HOME/kairos/agent-profiles"
   git status --short
   git add <reviewed-paths>
   git commit
   ```

3. Separately update the private input pin in dotfiles:

   ```sh
   cd "$HOME/dotfiles"
   nix flake update agent-profiles
   ```

4. Separately apply the reviewed pin/configuration:

   ```sh
   home-manager switch --flake .#cbox
   ```

## Privileged profiles: public policy, private knowledge

A profile can be declared here and completed from a private repository,
because every option of `programs.hermes.profiles.<name>` merges across
modules: `skills.names` and `skills.roots` concatenate, `cron.jobs` merges by
name, `settings` merges per key (`lib.mkForce` overrides a public leaf).

dotfiles keeps the **policy** — model, toolsets, limits, public catalog picks,
gateway — in `nix/hosts/<host>.nix` and `configs/hermes/<profile>/`. The
private repository (`~/kairos/agent-profiles`) supplies the persona, private
skill bundles *and their names*, initial memory snapshots, and scheduled work; none of that appears in
this repository. It also links its private skills into its project's
repositories for coding agents, and adds those link paths to the global
gitignore through `my.git.extraIgnores` (`nix/modules/git.nix`).
`k-research-agent` on cbox is the first profile built this way.

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

Review and commit private source changes, update the dotfiles pin, and apply
that pin as separate manual steps. Capture performs none of them.

1. Commit only the reviewed private source paths:

   ```sh
   cd "$HOME/kairos/agent-profiles"
   git status --short
   git add <reviewed-paths>
   git commit
   ```

2. Separately update the private input pin from a host with the clone:

   ```sh
   cd "$HOME/dotfiles"
   nix flake update agent-profiles
   ```

3. Separately apply that reviewed pin/configuration:

   ```sh
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

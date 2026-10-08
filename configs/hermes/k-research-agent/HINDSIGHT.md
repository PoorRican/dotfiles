# Hindsight memory for k-research-agent

## Declared configuration

`config.nix` selects `memory.provider = "hindsight"` and disables the old
markdown-memory injection/tool. Existing `memories/` files remain runtime-owned
and are preserved. `hindsight.nix` supplies the catalog-pinned plugin files,
profile-only connection settings, and supplemental Python wheels through Nix.
The plugin is not installed into the default profile.

The connection is the existing self-hosted WST service, bank
`kairos-hindsight`, not Hindsight Cloud or an embedded local daemon. The plugin
connects to `http://127.0.0.1:18888`; a profile-specific systemd user unit forwards
that loopback endpoint over authenticated SSH to WST's loopback port 30520. HTTP
never carries this client's credentials or memory over the LAN. SSH uses the
existing `wst` host configuration and key, requires a verified known host key,
and refuses interactive/password fallback through BatchMode. The gateway
requires and orders after the tunnel unit. Both units are enabled at user login.
The service pod was verified on WST, matching its librarian node selector.

The preliminary import/verification used the service's existing plaintext LAN
endpoint before the transport review. Moving subsequent traffic behind SSH does
not undo that prior exposure: consider rotating the tenant key as a separate
credential-management action. The underlying NodePort itself remains unchanged.

Automatic recall and automatic per-turn retention are enabled. Hybrid mode supplies the retain, recall, and reflect tools. Synchronous
recall includes raw world/experience facts as well as consolidated observations,
so slow observation consolidation does not hide newly retained memory.

Keep the tenant key in the profile's runtime-owned `.env` as
`HINDSIGHT_API_KEY`. Do not put it in Nix, plugin JSON, a seed, or Git. The
initial credential was read privately from kairos-infra's `.envrc`; shell
content was not executed. No bank missions or configuration were overwritten.

## Package identity and dependencies

The runtime uses Hermes revision
`aa30e02d860fb2683db0d9d2241d4980a6ee6978`. Its Nix package otherwise defaults
to a `0.0.0` install stamp and fails the plugin's `>=0.21.4` compatibility gate.
The package override records the verified release lineage: `v2026.9.24` shipped
`0.21.5`, and the selected revision is 8107 commits ahead, with that release
commit equal to the merge base and no commits behind. The resulting identity is
`0.21.5+8107.gaa30e02`; this does not describe it as the newest release.

The revision assertion deliberately fails if the input changes without
rechecking provenance. Recompute the base version and distance using immutable
upstream release/source evidence; never remove the plugin's minimum-version
requirement or set a fabricated version to make the gate pass.

The supplemental client/embed versions are `0.10.3`, matching the service
version checked during migration. `aiohttp-retry` is `2.9.1`. Hermes' sealed
runtime already supplies their other dependencies. Duplicate dependency
closures must not be propagated over the core environment. The actual final
wrapper's installed requirements and imports were checked, as well as the
plugin compatibility gate and live operation.

This change depends on the already-present Hermes input refresh in `flake.lock`
and removal of the obsolete `homeassistant` dependency group in
`nix/modules/hermes.nix`. Those pre-existing changes were intentionally not
absorbed into the Hindsight task commit. They must be retained/reviewed when
integrating this commit; the old lock alone will fail the revision assertion.

## Deployment

The normal complete deployment is `home-manager switch --flake .#cbox` from the
reviewed dotfiles checkout. Do not use that command while unrelated pending
configuration must remain undeployed.

The initial deployment instead activated only the target profile block from
evaluated `home.activation.hermesProfiles.data`, along with its evaluated
launcher, gateway unit, and SSH-tunnel unit. It did not run full Home Manager activation, switch
the global package, modify default-profile configuration, or restart the default
gateway. The exact built output is retained by a GC root at:

`~/.local/state/hermes/scoped-deployments/k-research-agent/current`

That bundle contains `activate-profile.sh`, `launcher`, `gateway.service`,
`tunnel.service`, `home-files`, and `package`. Consumer links point inside its
immutable `*-home-manager-files/` tree so a later Home Manager switch recognizes
ownership. Private rollback metadata is alongside the GC root in `before-*`.
The activation script is the evaluated target-profile script, not a separate
hand-authored YAML configuration or an in-place store modification. It preserves
existing seeds. The scoped deployment is not a new full Home Manager generation.

Until the full reviewed Home Manager switch adopts the new global package, use
`k-research-agent`, not the old global `hermes -p k-research-agent`, to ensure the
supplemental dependencies and corrected runtime identity are present:

```sh
k-research-agent memory status
k-research-agent chat
```

Existing agent-tool process environments may carry a stale `PYTHONPATH`; for
validation from such an environment use:

```sh
env -u PYTHONPATH -u PYTHONHOME -u HERMES_BIN k-research-agent memory status
```

Inspect the gateway's actual process/interpreter and supplemental package paths,
not only the declared unit or cached CLI installation diagnostics.

## Saved-memory document import

The import covered the existing `USER.md`, containing five entries at upload.
It did not backfill SQLite conversation history, skills, persona, or wiki files.
The original source bytes were preserved; a private snapshot and provenance
manifest are stored under:

`~/.local/state/hermes/hindsight-imports/k-research-agent/`

The document ID is `hermes-import:k-research-agent:USER.md`. The document carries
source profile/path/SHA-256 metadata and import tags. Snapshot the source and
recheck its hash before uploading. Timeless preferences must not be assigned
invented historical occurrence dates.

Use the service's multipart `/v1/default/banks/{bank_id}/files/retain` endpoint
for a file upload. Per-file `document_id`, context, metadata, and tags belong in
`files_metadata` inside the JSON `request` form field. Version 0.10.3 does not
accept `update_mode` on this endpoint; it always processes asynchronously. The
migration refused an existing mismatching document rather than replacing it
implicitly. Do not resend an acknowledged upload: retain its operation IDs and
inspect the operation/document first. A lost acknowledgement requires checking
the deterministic document before retrying; file upload does not support a
caller-selected operation UUID.

Completion checks performed:

- File conversion/retention operation completed without an error.
- Exact uploaded text and source-hash metadata read back from the document.
- All five preferences returned through raw-fact recall.
- A fresh target-profile session recalled browser/documentation preferences
  without tool calls; provider logs named the exact requested bank.
- The session's automatic-retention document read back with its actual question,
  answer, and `agent_identity = k-research-agent` metadata.

Observation-only recall was checked separately and was empty for the import.
Existing bank consolidation operations were pending/processing before the port;
that service backlog was not reset or reconfigured. Raw-fact recall is verified;
consolidation recovery is a separate infrastructure task.

## Local tests

```sh
"$HERMES_PYTHON" -m unittest discover -s scripts/hermes -p 'test_*.py' -q
nix build --no-link --no-write-lock-file \
  .#homeConfigurations.cbox.config.programs.hermes.package
```

Use Hermes' packaged interpreter for the full helper suite because the capture
helpers import `hermes_yaml`. Host Python alone is sufficient for the standalone
Nix configuration test, but not the full suite.

# Flake inputs and hosts

## Scope and provenance

A top-level flake input may be resolved even when only one host consumes it. A machine-local path there can therefore break other hosts. Put a host-local dependency behind the affected host's lazy evaluation path, or use a portable pinned source; a host-local `builtins.getFlake` still requires that path on the target host and may require impure evaluation. Do not assume a local-path example evaluates in pure mode.

Trace the input URL and `follows`, its lock node, consuming overlay or module, profile imports and host enablement, and finally the selected package attribute. A correct pin alone does not prove the host uses it. In a dirty checkout, the working lockfile, not necessarily the committed one, determines evaluation.

Keep lock changes limited to the requested inputs. If only one package needs a newer nixpkgs, consider a narrowly pinned secondary input instead of updating the primary package set. A Rust `overrideAttrs` changing only source and hash can retain old dependency patches; inspect the derivation or use the package from a suitable pinned nixpkgs.

A Git-backed flake excludes untracked files from its source snapshot. If a new imported file is invisible, inspect tracking state; stage only with permission, or evaluate from an appropriate source that includes the file. Do not mutate a shared index just to evaluate.

## Check the affected surface

Evaluate affected hosts and hosts that must remain independent; for Home Manager a narrow check is:

```bash
nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file
```

Evaluation does not build all derivations. If an input evaluates but the profile build fails, separate the input result from unrelated package or overlay failures. After an update, inspect upstream manifests when newly introduced dependencies are unavailable in the pinned package set. A matching package name or version alone does not prove the running binary comes from the selected derivation: inspect the applied profile and PATH as well.

For a globally installed Bun CLI, check its package metadata and the pinned Bun version before changing inputs; the installer's global bin directory must be on the activation and runtime PATH. A shared overlay must provide sources for each system that consumes it.

## Concrete proof and overlay workflow

1. Read `flake.nix`, locate the input and every consumer, and trace the
   consuming module through its profile to each affected host. Check the input's
   lock revision and evaluate the selected package attribute, for example
   `nix eval --raw '.#homeConfigurations.<host>.config.programs.<name>.package.name'`.
   Inspect the applied profile and PATH separately if the running binary may be
   stale or shadowed.
2. A top-level machine-local `path:` input can break unrelated hosts even if
   the overlay is used only on one. A local `builtins.getFlake` binding
   referenced only by that host can isolate it; the path must exist on that
   host and purity restrictions still apply. Remove an obsolete input and its
   lock node only when no longer referenced.
3. For a single newer package, inspect the pinned package and candidate
   nixpkgs versions before changing the lock:
   `nix eval --raw github:NixOS/nixpkgs/<ref>#<pkg>.version --refresh`.
   A narrowly pinned secondary package set avoids unrelated primary input
   churn. For a shared Bun overlay check npm `bin` and `engines`, set
   `version`, explicit `src`, and platform `passthru.sources` for all consumed
   systems; ensure `$HOME/.bun/bin` is in installer and runtime PATH.
4. Evaluate affected and independent Home Manager hosts using the activation
   derivation command above. A build can still fail in a different package;
   inspect upstream manifests when an updated input introduces dependencies
   missing from pinned nixpkgs. Report lock changes and which hosts consume
   the input.

For editor language servers, `nix/profiles/pkm.nix` scopes the heavier set to
importing hosts. Check Helix's language support and `hx --health <language>`;
syntax-only languages do not necessarily have a default LSP. Explicit
`configs/helix/languages.toml` overrides may be needed when choosing a server
or its executable differs from the default. If `rustup` and `rust-analyzer`
both provide the same binary, the profile uses priority to resolve the
Home Manager build conflict.

## Hermes profile and local snapshot automation

For Hermes-specific configuration, follow `configs/hermes/README.md` and
`nix/modules/hermes.nix`: the default profile is rooted at `~/.hermes`, and
named profiles have their own homes and launchers. Trace the host profile
override through those definitions instead of assuming a change applies to
every profile.

When explicitly asked for local-only automated skill snapshots, the original
pattern uses a deterministic script in `~/.hermes/scripts/` and a Hermes
`no_agent=true`, `deliver="local"` cron job. Resolve and verify the repo root,
allowlist only intended skill paths, and exclude runtime bookkeeping. Before
staging, delay if `git diff --cached --quiet` reports an occupied index; after
staging, validate that every staged path is allowlisted before committing.
Provide a dry-run and test an occupied index with `GIT_INDEX_FILE` pointing
to a temporary copy, leaving the real index untouched. Do not install such
automation without the user's request.

# Bun global-agent overlay pattern

Use this reference when a Bun-installed CLI or coding agent requires a newer Bun than the pinned nixpkgs branch provides.

## Trigger

- A tool is distributed as an npm package and expects `bun install -g ...`.
- The package metadata (`engines`, install/runtime error, or docs) requires a Bun version newer than `pkgs.bun` from the repo's pinned nixpkgs.
- The user wants minimal dotfiles churn rather than a broad `flake.lock` update.

## Workflow

1. Confirm the package metadata:
   - npm package name
   - exported `bin`
   - Bun version requirement
2. Confirm the pinned nixpkgs `pkgs.bun.version` and whether the target Bun exists upstream.
3. Prefer a narrow shared overlay over updating all flake inputs:
   - override `version`
   - override `src` selected from `passthru.sources.${system}`
   - replace all supported platform hashes used by the repo (`aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`, `x86_64-linux` when applicable)
4. Put the CLI installation behind a reusable Home Manager module/profile when the tool is generally useful, rather than a one-host activation hack.
5. Ensure external-install activation PATH includes the global-bin directory Bun uses:
   - `$HOME/.bun/bin`
   - usually before `$HOME/.local/bin` and the installer tool path
6. Add comments in the Nix files explaining:
   - why Bun is pinned
   - why the overlay is intentionally narrow
   - why the overlay is shared across hosts
   - why `$HOME/.bun/bin` is in the activation/runtime PATH
7. Stage newly added module files before flake evaluation so flakes can see tracked imports.
8. Verify:
   - `nix-instantiate --parse flake.nix` when available
   - `nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file` for all affected/shared hosts
   - real target-host smoke tests: `bun --version`, `command -v <binary>`, `<binary> --version`, and a help invocation
9. Commit only the intended Nix files. Leave unrelated generated skill/usage files and user config changes untouched unless explicitly requested.

## Notes

- Do not update `flake.lock` just to get a newer Bun unless the user asks for broader input updates.
- Do not hard-code one host's system; shared dev profiles usually need the overlay to evaluate on every declared host.
- If a verification shell cannot find `nix` via PATH, that is a live environment issue; use an absolute Nix path only for verification and do not encode the transient PATH failure as a durable rule.
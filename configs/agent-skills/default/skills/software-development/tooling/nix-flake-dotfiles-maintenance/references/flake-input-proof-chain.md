# Flake input proof chain

Scope: proving that a flake-managed package comes from the intended input and revision and is actually used by the host or profile being built; triage for what breaks after an input update; and Home Manager clobber handling.

## Prove all five links, not just one

1. The flake input exists and points at the intended upstream (`flake.nix`: input name, URL, whether it follows `nixpkgs`).
2. The module or overlay actually consumes it: the exact file and attribute path (`packages.${pkgs.system}.default`, an overlay, a module option) and how it is installed (`home.packages`, system packages, a module option).
3. The host or profile imports that module and enables it (host file, intermediate profiles, the `programs.<name>.enable`-style option).
4. `flake.lock` pins the input to a specific revision (owner/repo, locked `rev`).
5. `nix eval` resolves the expected package for the target host: `nix eval --raw .#homeConfigurations.<host>.config.programs.<name>.package.name`. Prefer a narrow attribute that proves the derivation selected by the configuration.

A correct pin does not prove the host uses it, and a correct `flake.nix` does not prove the module wiring. Conclude one of: the wiring is correct; the input exists but the host is not using it; or the flake is wired correctly but the installed binary may be stale or shadowed (the user may not have rebuilt).

## Changing versions

- When moving the `nixpkgs` release branch, move the companion release-tracking inputs (for example `home-manager`) with it unless the repo deliberately pins a different combination. Refresh the lockfile narrowly and report old and new refs for each.
- Evaluate the target package on candidate refs before touching the lock: `nix eval --raw github:NixOS/nixpkgs/<ref>#<pkg>.version --refresh`. Moving a branch that does not advance the package is churn.
- On a dirty repo `nix` evaluates the working-tree `flake.lock`, not the committed one. Compare it with `HEAD` (`git diff -- flake.lock`, `git show HEAD:flake.lock | jq -r '.nodes["<input>"].locked.rev'`), especially when the package version string is unchanged but the pinned commit changed.

## Evaluation passes, build fails

- Narrow `nix eval` success does not prove the whole host builds: unrelated overlays or packages in the same profile can still block `home-manager switch`. Report whether the input itself is healthy separately from whether the overall configuration is blocked elsewhere.
- After an input update, inspect the new upstream's own manifests (`pyproject.toml`, `uv.lock`, `package-lock.json`) for added extras or transitive dependencies, comparing old and new revisions (`nix flake archive --json github:<owner>/<repo>/<rev>` fetches the exact source). A new dependency may be absent from the pinned `nixpkgs`, in which case the parent input may also need to move.

## Activation: "would be clobbered"

- `Existing file '...' would be clobbered` is an activation failure that evaluation and build do not reveal. Do not delete the file. Diff the unmanaged file against its repo source and validate the repo copy (for example with `python -m json.tool`); preserve intentional local changes in the repo source first; then move the file aside with a timestamped backup and rerun `home-manager switch`. Verify it is now a managed link with `ls -l`.
- `Error installing file '...' outside $HOME` with `mkOutOfStoreSymlink`: the symlink target must come from the repo-injected source root, not a hard-coded `$HOME/<repo>` path that may not match the checkout location.

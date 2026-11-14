# Nix and crane Rust workspace builds

## Source visibility and sibling layout

A Git-backed flake source omits untracked files. A missing workspace manifest or Rust `E0583` module error under Nix, despite files existing locally, can mean the root or a sibling input omitted those files. Check trackedness and the flake fileset in each input; if appropriate, use intent-to-add on specific files, noting that the build depends on uncommitted work. Compare with local Cargo resolution and find the originating derivation failure rather than its downstream failure cascade.

Avoid `git add -N .`: it can pull unrelated worktrees, agent directories, and build output into the flake source. Compare `cargo metadata --locked --offline --format-version 1` in the same checkout with the Nix failure: a local resolution failure also needs investigation rather than being attributed to flake visibility.

For relative path dependencies in sibling repositories, reproduce the expected directory layout from pinned inputs. A directory `src` is unpacked under its source name, so the `sourceRoot` must include that directory and the workspace subdirectory. Symlink farms into read-only store paths can fail during post-unpack chmod or crane's source rewriting; copy the trees and make the copies writable. Point `cargoLock` at the lockfile in that layout. A virtual workspace manifest may require explicit `pname` and `version`, including for `cargoFmt`.

## Vendoring and identity

A sandboxed build attempting to fetch a Cargo git dependency can fail with DNS or revision errors. Inspect the lockfile's git sources and compare manifests at the actual pinned sibling revisions: a local path dependency and a pinned sibling that instead declares a git dependency can resolve differently. Ensure dependencies are available to the vendoring phase and the chosen sources agree with the lockfile; do not assume a network failure proves the revision is absent.

If the lockfile contains no `source = "git+..."` entries, a pinned sibling declaring a git dependency disagrees with path-based resolution; adding a fetch and `[patch]` can break `--locked`. Compare that sibling's manifest at the pinned revision and choose inputs consistent with the lockfile. Cargo ignores `[patch]` in a non-root workspace manifest.

Private flake inputs need fetch-time credentials. For GitHub, `NIX_CONFIG="access-tokens = github.com=$(gh auth token | tr -d '\r\n')"` supplies a token without printing it; the spaces around `=` are required by the configuration syntax. Verify token access without exposing credentials.

A dirty flake may lack `self.rev`, and a local `--override-input` path may lack `rev`, silently sending provenance labels to a `dev` fallback. Gate exact revision checks on locked revisions but retain structural checks for overrides; comparing a label with the same variable used to generate it is tautological, not independent provenance evidence. Building binaries separately can change the resolved feature set; match the intended release build when comparing artifacts.

## Image closure

For an OCI image, compare dynamic dependencies reported by `ldd` with `closureInfo { rootPaths = contents; }/store-paths`. `ldd` is in `pkgs.glibc.bin`, not the default `pkgs.glibc` output. Check that extraction found actual named store paths before asserting inclusion, so an empty or malformed extraction cannot pass vacuously. Execute the real image entrypoint to confirm the loader can start it; a missing-config error from the application is distinguishable from a dynamic linker failure.

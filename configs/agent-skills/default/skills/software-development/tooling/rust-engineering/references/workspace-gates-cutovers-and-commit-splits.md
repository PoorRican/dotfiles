# Workspace gates, cutovers, and commit splits

Scope: Cargo workspace formatting and lint boundaries, deletion correctness, and coupling among workspace additions.

## Workspace gates and formatting scope

- In a workspace with sibling path dependencies, `cargo fmt --all` can descend into and rewrite sibling checkouts, while `cargo clippy --workspace` treats path dependencies as dependencies rather than primary packages to lint. Formatting and lint scope are therefore asymmetric. (src: rust-workspace-ci-gate-preflight, 2026-08-08; cargo-workspace-incremental-commit-split, 2026-09-21)
- A package-scoped formatting gate can silently become unscoped if its derived package list is empty. Shell process substitution can also hide the helper's failure status, so the consumer's nonempty-list check is part of keeping the boundary closed. (src: rust-workspace-ci-gate-preflight, 2026-08-08)
- Clippy may stop after its first failing crate set, so a first pass can understate the warnings a new gate exposes; a follow-up using `--keep-going` can reveal more failing crate sets. A deny-warnings gate also changes compatibility for untouched code; mechanical fixes and structural refactors have different scope and risk. (src: rust-workspace-ci-gate-preflight, 2026-08-08)

## Deletions and cutovers

- `cargo check --workspace --lib` can pass while removed config types remain because parsing and tests may be their only consumers. What independent evidence establishes that removed symbols and behavior are actually gone, including deserialization paths? (src: rust-workspace-deletion-refactor, 2026-07-26)
- Builds and clippy do not reveal unused manifest dependencies; dependency declarations need a separate review after consumer deletion. (src: rust-workspace-deletion-refactor, 2026-07-26)
- Without `#[serde(deny_unknown_fields)]`, an obsolete configuration key can be silently ignored and the new behavior used under the old name. (src: rust-workspace-deletion-refactor, 2026-07-26)
- When deletion leaves a one-variant enum, one-implementation trait, constant tuple-key component, or empty options type, the remaining abstraction may be dead weight rather than a useful seam. Stale metrics and module vocabulary can also misdescribe the surviving system. (src: rust-workspace-deletion-refactor, 2026-07-26)

## Multi-crate workspace boundaries

- Cargo tolerates crate directories under a workspace that are omitted from `[workspace].members`, so member inclusion can be cumulative; lockfile metadata follows the selected member set. (src: cargo-workspace-incremental-commit-split, 2026-09-21)
- `include_str!` and `include_bytes!` make external config or fixture files compile-time crate dependencies; a split that lands those files later cannot compile that crate. Path dependencies likewise constrain which crate can compile before another. (src: cargo-workspace-incremental-commit-split, 2026-09-21)

## Open conflict: history rewriting

- Open question: which worktree ownership and branch preconditions, if any, make history rewriting appropriate during a workspace cutover? The deletion source warns against reset in a shared tree, but later recommends a soft reset for squashing without reconciling those conditions; neither recommendation is general guidance. (src: rust-workspace-deletion-refactor, 2026-07-26)

## Toolchain drift and shared build directories

- CI clippy on an unpinned stable toolchain (no `rust-toolchain.toml`) means a new stable release can turn the main branch red: one release (rustc 1.98) added a lint, `clippy::result_large_err`, that fired in several places. Reproduce with the CI toolchain (`rustup toolchain install <VER> --profile minimal --component clippy,rustfmt`, then `cargo +<VER> clippy ... -D warnings`) and prefer a targeted `#[allow]` on cold paths over a mass refactor. (src: unpinned-toolchain-drift, 2026)
- Sharing one `CARGO_TARGET_DIR` across worktrees of the same Rust workspace makes gates untrustworthy: path crates are keyed by workspace-relative path with mtime-based freshness, so another worktree's build counts as Fresh. The safe pattern on btrfs: `cp -a --reflink=always target <private copy>`, touch the sources, run the gate, delete the copy afterwards. (src: shared-target-dir-freshness, 2026-09-27)

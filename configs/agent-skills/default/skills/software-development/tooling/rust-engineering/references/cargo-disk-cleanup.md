# Cargo disk cleanup

Scope: reclaiming disk from the shared Cargo caches and from per-project `target/` directories with `cargo-cache` and `cargo-sweep`. Cleanup is destructive: get the owner's authorization for the scope first, and measure and dry-run before deleting. The flags below follow the tools' documented options but were not run here [INFERENCE]; confirm them with `cargo cache --help` and `cargo sweep --help` before relying on them.

## Measure and dry-run first

- Report savings by layer, because the layers behave differently: the shared Cargo cache (`~/.cargo`), Rust toolchains (`~/.rustup`), and per-project `target/` directories.
- `cargo cache -r registry` is a safe high-value default: it removes extracted registry sources and crate archives that Cargo re-creates or re-downloads on demand. `cargo sweep -t 30 -r <repo roots>` removes stale `target/` artifacts older than 30 days. Preview each with the dry-run flag first (`cargo cache -n`, `cargo sweep -d`).
- Find the top offenders with a shell pipeline: `find <root> -type d -name target -prune -print0 | xargs -0 du -sk | sort -nr | head -50`. Broad recursive walks written in Python time out on large trees.

## Worktrees

- Check Git worktrees separately, since each accumulates its own `target/`, and prefer `git worktree remove <path>` for old clean worktrees over `rm -rf`. Run `git status --short` in the real checkout first and leave dirty or orphaned worktrees alone until reviewed.

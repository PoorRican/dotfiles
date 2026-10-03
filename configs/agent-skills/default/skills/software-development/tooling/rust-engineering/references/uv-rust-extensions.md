# uv Rust extensions

Scope: Stale local Rust extensions in uv-managed Python workspaces and iteration-order differences across Python and Rust.

## Workspace build freshness

- A documented uv workspace cache check for a local path dependency uses the dependency's `pyproject.toml` modification time rather than its source-tree modification time. After Rust-only edits, a later `uv run` auto-sync can therefore restore a cached extension over a fresh local build; does the installed uv version still use this cache signal? (src: uv-workspace-rust-extension-staleness, 2026-08-24)
- A manually installed wheel is not durable against a subsequent uv auto-sync. `uv sync --reinstall-package` asks uv's build backend to rebuild the local package despite the stale project-metadata cache signal. (src: uv-workspace-rust-extension-staleness, 2026-08-24)

## Cross-language ordering

- Python dictionary equality ignores iteration order, while Rust `HashMap` iteration is randomized. A test comparing maps for equality can pass even when serialization or a digest changes because iteration order changed. If order is part of the consumer contract, an insertion-ordered map such as `IndexMap` and order-preserving removal (`shift_remove`) may be needed. (src: uv-workspace-rust-extension-staleness, 2026-08-24)

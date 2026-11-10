# uv Rust extensions

Scope: Stale local Rust extensions in uv-managed Python workspaces and iteration-order differences across Python and Rust.

## Workspace build freshness

- A documented uv workspace cache check for a local path dependency uses the dependency's `pyproject.toml` modification time rather than its source-tree modification time. After Rust-only edits, a later `uv run` auto-sync can therefore restore a cached extension over a fresh local build; does the installed uv version still use this cache signal? (src: uv-workspace-rust-extension-staleness, 2026-08-24)
- A manually installed wheel is not durable against a subsequent uv auto-sync. `uv sync --reinstall-package` asks uv's build backend to rebuild the local package despite the stale project-metadata cache signal. (src: uv-workspace-rust-extension-staleness, 2026-08-24)

## Cross-language ordering

- Python dictionary equality ignores iteration order, while Rust `HashMap` iteration is randomized. A test comparing maps for equality can pass even when serialization or a digest changes because iteration order changed. If order is part of the consumer contract, an insertion-ordered map such as `IndexMap` and order-preserving removal (`shift_remove`) may be needed. (src: uv-workspace-rust-extension-staleness, 2026-08-24)

## Stale binaries and copied environments

- Switching branches can leave the gitignored compiled extension (`*.abi3.so`) from the previous branch in place, so Python imports a binary whose function signature no longer matches the code (one session saw a 17-argument versus 14-argument mismatch fail dozens of tests). Check the loaded extension's signature and rebuild with `uv sync --reinstall-package <pkg>`. (src: branch-switch-stale-extension, 2026-09-22)
- Validating an isolated worktree: `uv run python` showing correct imports is not enough if `.venv` was copied. Console-script shebangs stay absolute to the ORIGINAL checkout, so pytest imported foreign code. Read the executable's first line, run `uv sync --all-packages --reinstall`, then rerun the hook. (src: copied-venv-shebang, 2026-09-22)
- `uv run --with '.[dev]' pytest` can reuse a stale overlay wheel of the current project after new package modules are added, giving a false `ModuleNotFoundError` while `uv run pytest` on the editable environment passes. Use `UV_NO_CACHE=1` on the same command, or `uv sync --extra dev` then `uv run pytest`, and confirm the imported module path. Reported on Python 3.14.5 and not re-run here [INFERENCE]. (src: uv-overlay-wheel-staleness)

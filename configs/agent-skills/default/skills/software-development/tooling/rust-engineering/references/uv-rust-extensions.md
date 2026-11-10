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

## Interpreter and wheel qualification

- Before a PyO3/maturin build, compare the target interpreter's `sys.version_info` with `sysconfig.get_config_var()` for `VERSION`, `SOABI`, `EXT_SUFFIX`, and `LIBDIR`. Investigate inherited `PYTHONPATH` before removing it: it may supply intentional dependencies or introduce incompatible build metadata. Scope removal of contaminated `PYTHONPATH` and unintended `PYTHONHOME` to affected build and check processes; select the target with `PYO3_PYTHON`. If a runner reinjects a variable, unset it on each affected command rather than changing global configuration. The contamination diagnosis is not re-run here [INFERENCE].
- PyO3 normally executes the selected interpreter to query `sysconfig`. Its [build guide](https://pyo3.rs/main/building-and-distribution.html#configuring-the-python-version) documents `PYO3_PRINT_CONFIG=1 cargo build` to print the configuration and intentionally halt compilation, and `PYO3_ENVIRONMENT_SIGNATURE` to trigger a rebuild when its value changes. These commands were not re-run here [INFERENCE]. Python's [path initialization documentation](https://docs.python.org/3/library/sys_path_init.html) explains how `PYTHONPATH` and `PYTHONHOME` affect initialization; behavior can vary by Python version, so inspect the actual interpreter.
- If contaminated configuration produced cached `pyo3-build-config` output, use an isolated Cargo target directory or invalidate only the identified build artifact; bound compiler concurrency and preserve unrelated caches and source data. Not re-run here [INFERENCE].
- Inspect the wheel ZIP, tags, and extension name against the target interpreter and intended ABI. An `abi3` extension need not have the runtime's exact minor version in its suffix; assess ABI and wheel-tag compatibility instead. Install the real wheel in an isolated environment, explicitly import the native module, and check that its `__file__` resolves inside that installation rather than the source tree. Make missing native code fail the intended acceptance gate instead of silently skipping it. Wheel qualification not re-run here [INFERENCE].
- If an embedded-Python Rust test using a relocated managed interpreter fails standard-library initialization, investigate a test-process-only `PYTHONHOME` set to that interpreter's `sys.base_prefix`, using the same interpreter as the build configuration. Inspect linked libraries and the selected environment rather than masking the failure; this is conditional, not a universal setting. Not re-run here [INFERENCE].
- Run relevant native and Python tests against the installed artifact. For packages supporting persistence, exercise a real example and verify readback, not just construction or array shapes. Inspect wheel members for private fixtures and secrets before distribution.

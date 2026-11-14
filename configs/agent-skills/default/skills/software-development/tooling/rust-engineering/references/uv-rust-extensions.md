# Python extensions

## Freshness and isolation

A local Rust extension can remain stale after a source-only edit or branch switch even while Python imports successfully. Inspect the loaded module path and signature, then rebuild the local package with `uv sync --reinstall-package <package>`; a manually installed wheel can be replaced by a later sync. A cached overlay can also hide newly added modules: retry the same invocation without cache and inspect the imported path.

Copied virtual environments can retain absolute console-script shebangs pointing to the original checkout. Inspect the executable and recreate or reinstall the environment before trusting its tests.

Python dictionary equality ignores iteration order and Rust `HashMap` iteration is not stable. Where serialized order or a digest is contractual, test iteration order explicitly and choose an order-preserving map and removal operation.

## Interpreter and wheel qualification

For PyO3 build mismatches, inspect the selected interpreter's version, ABI and `sysconfig`, and investigate inherited `PYTHONPATH` or `PYTHONHOME` before changing them. `PYO3_PYTHON` selects the interpreter. Cached build configuration can preserve a bad selection; isolate the Cargo target or invalidate the identified artifact.

`PYO3_PRINT_CONFIG=1 cargo build` prints the selected build configuration and intentionally stops compilation. If an embedded-Python test with a relocated managed interpreter fails standard-library initialization, investigate a test-process-only `PYTHONHOME` set to that interpreter's `sys.base_prefix`, using the same interpreter as the build configuration.

Inspect the wheel's tags and extension name for compatibility with the intended interpreter; an `abi3` extension need not match the runtime minor version. Install the actual wheel in an isolated environment and explicitly import the native module, checking that its path is inside that installation. Exercise relevant native and Python behavior, including persistence readback where applicable, and inspect wheel contents for secrets before distribution.

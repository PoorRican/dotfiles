# Workspace gates, Cargo and runtime traps

## Gate scope and cutovers

- In a workspace with sibling path dependencies, `cargo fmt --all` can descend into and rewrite sibling checkouts, while `cargo clippy --workspace` treats path dependencies as dependencies rather than primary packages to lint. A generated package list must be nonempty, and shell process substitution can hide the generator's failure.
- A first Clippy pass may stop before reporting other failing crates; `--keep-going` can reveal further failures. An unpinned CI toolchain can introduce new deny-warnings failures without a source change; reproduce with the CI toolchain before changing code.
- A library-only check does not prove removed configuration or deserialization behavior is gone. Inspect consumers, tests, and manifest dependencies separately; without `deny_unknown_fields`, obsolete configuration keys can be silently ignored.
- Compile-time includes and path dependencies constrain independently buildable workspace changes. After deletion, reconsider abstractions or vocabulary that no longer describe the surviving behavior.
- A shared `CARGO_TARGET_DIR` across worktrees can give misleading freshness evidence. When source identity matters, use an isolated target directory and verify that the intended source was compiled.

## Bounded verification and cleanup

An existing target directory is only a candidate cache. If builds are resource-bounded, supervise the authorized command and stop if it exceeds its permitted scope; report source compilation and test evidence separately from formatting or static inspection. A direct `rustc` harness against cached artifacts can exercise selected checked-out modules but is not evidence of a locked Cargo, full-package, or workspace build.

Cargo cache and target cleanup deletes reusable artifacts and can force downloads or rebuilds. Obtain authorization for the deletion scope, inspect the affected paths and use the installed cleanup tool's dry run and help before deleting. Review dirty worktrees before removing them.

## Async and storage runtime traps

A panic in a spawned Tokio task can terminate that task while the process and unrelated health flags remain alive. Await or supervise long-lived task handles and surface their failure; check task panic logs when one event stream stops but the process remains healthy. Validate fallible conversions at the transport boundary, and use reconciliation where loss of a stream would otherwise leave state stale.

`object_store::path::Path::join("a/b")` appends one path part and encodes the slash as `%2F`. A local filesystem can mask the difference from remote object keys; construct multi-segment paths with `Path::from_iter` over the `split('/')` parts, and check the resulting keys against the intended backend.

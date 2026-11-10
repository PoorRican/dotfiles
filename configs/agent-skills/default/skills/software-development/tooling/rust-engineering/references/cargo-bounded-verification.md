# Cache-bounded Rust verification

Scope: supervised verification when a cold build or unbounded compiler use is not permitted. Obtain the owner's current authorization before compilation; these methods do not grant it.

## Preflight and supervised Cargo

- Read workspace manifests, the toolchain pin, and hook scripts before choosing package-scoped commands. Inspect memory, load, free disk, installed toolchain, sibling path dependencies, and target artifacts first. Do not install tools or trigger a cold build outside the authorized scope.
- Treat an existing target as a candidate cache, not proof of usability. Supervise an authorized attempt with a short wall-clock deadline and no more than the authorized compiler-job count. Watch output and terminate its process group immediately if an unapproved dependency starts rebuilding; record the first package, exact command, and stop reason. Do not escalate to a workspace build. Fast output alone does not prove the intended worktree source compiled: require explicit source-compilation or test evidence. Supervision method not re-run here [INFERENCE].
- If compilation is blocked, perform only authorized package-scoped formatting, diff and configuration parsing, and read-only source-scope and identity checks. Label these accurately: they neither compile nor execute regression tests. Report exact remaining commands and do not imply activation, publication, deployment, restart, private reads, or live operations.

## Scoped source-module harness

- Where authorized, a separately bounded `rustc` source-module harness can exercise exact checked-out modules against existing cached rlibs. Include real implementations and interfaces, not copied classifiers or test substitutes; check toolchain compatibility and feature fingerprints, record source and extern hashes and the exact command, and run the actual regression files. Call the result scoped source-module acceptance, not locked-Cargo, whole-package, caller-runtime, or workspace acceptance; identify tests and paths outside the harness as unexercised. This method was not re-run here [INFERENCE].

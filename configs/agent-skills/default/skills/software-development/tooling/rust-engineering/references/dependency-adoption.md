# Dependency adoption

Scope: Cargo feature resolution and the engineering fit of replacing an in-house layer with an external crate.

## Resolved dependency cost

- Cargo features are additive and unify for a semver-compatible crate version. Adding a path dependency can therefore enable features in a crate already present in the host workspace without changing its locked version; a version-only lockfile diff misses this change. (src: cargo-feature-unification-audit, 2026-08-06)
- Enabling `reqwest`'s `rustls-tls` does not itself disable default TLS. Disabling defaults can also remove other needed capabilities such as HTTP/2, so the actual default-feature set and required features matter more than a remembered feature recipe. (src: cargo-feature-unification-audit, 2026-08-06)
- A newly resolved `-sys` dependency can add build-environment requirements such as system headers or `pkg-config`, even if runtime behavior is unchanged. Cargo.lock reveals resolved generations; incompatible major versions may coexist as compile-time/binary-size duplication, while proc-macro skew does not imply runtime cost. (src: cargo-feature-unification-audit, 2026-08-06; external-crate-replacement-assessment, 2026-08-03)
- Two linked TLS/crypto backends are evidence of dependency or binary cost, not proof of runtime incompatibility. Does a real request from a binary containing both stacks fail, or are the backends merely both present? (src: cargo-feature-unification-audit, 2026-08-06)

## Replacement fit

- What remains after deserialization: state machines, sequencing and gap recovery, domain conversion, correlation, and error or async contracts can survive a crate swap unchanged. If most of this remains, the replacement may not materially shrink the in-house layer. (src: external-crate-replacement-assessment, 2026-08-03)
- Does the crate replace a shared transport, retry, rate-limit, or connection substrate used by sibling modules? A self-contained client can bypass those conventions even when its protocol parser is polished. (src: external-crate-replacement-assessment, 2026-08-03)
- Are protocol details that affect domain correctness implemented, and do they match the upstream specification? A missing correctness-critical flag matters more than surface API quality. (src: external-crate-replacement-assessment, 2026-08-03)
- Is the boundary type model useful to the consumer, or does it allocate owned strings and then require reparsing into domain types? How does the resulting work compare with merely parsing the wire format? (src: external-crate-replacement-assessment, 2026-08-03)

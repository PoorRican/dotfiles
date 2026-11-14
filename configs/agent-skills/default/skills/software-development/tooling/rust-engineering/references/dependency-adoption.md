# Dependency adoption

## Resolved dependency cost

- Cargo features are additive within the relevant resolution context. A new dependency can activate features without changing a locked version, so inspect the resolved feature graph, not just the lockfile diff. Package-specific builds can expose a missing feature declaration masked by workspace-wide feature unification.
- Enabling an alternative TLS feature does not necessarily disable default TLS; check defaults and needed capabilities. Multiple TLS backends indicate potential dependency and binary cost, not by themselves a runtime incompatibility.
- A new `-sys` dependency may require native build tools or headers. Incompatible crate versions can coexist; distinguish runtime dependencies from compile-time proc macros when assessing cost.
- If `cargo tree -i <crate>` reports an ambiguous package specification, inspect each version with `<crate>@<version>`. A git-pinned revision may become unreachable after upstream history rewriting; plan the repin and update all direct consumers and the lockfile together.

## Replacement fit

Check what remains after replacing parsing: state machines, sequencing, recovery, domain conversion, correlation, and error or async contracts may still require the in-house layer. Check whether the replacement bypasses shared transport, retry, or rate-limit behavior; whether it implements correctness-critical protocol details; and whether its boundary types introduce allocations or reparsing.

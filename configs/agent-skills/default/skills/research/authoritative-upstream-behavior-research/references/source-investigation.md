# Source-backed behavior investigation

## Establish relevant baselines

Record separately, when relevant: the installed version, commit and dirty/clean state; the latest stable tag; the current upstream branch commit for unreleased behavior; and the documentation revision. Do not call `main` or current documentation equivalent to the installed release. A current page may already describe the next stable version.

Use tagged source or full commit SHAs and construct permalinks with line ranges. A mutable documentation URL is useful for current public guidance, but pair it with a pinned source link for exact claims. When official prose and tagged implementation conflict, state the conflict explicitly: implementation describes actual behavior; documentation describes intended or public behavior. Upstream tests can supply executable examples and edge cases; third-party sources do not prove native behavior.

When executing the target is prohibited, resolve and hash its on-disk executable, then compare its platform, byte size and digest with official release-asset metadata before selecting tagged source. Keep that match distinct from the running process's loaded image, native-addon provenance, effective configuration and historical creator attribution.

## Enumerate and trace

For a complete command inventory, locate the actual dispatch path and enumerate every recognized branch. Capture exact command tokens, accepted argument tokens and aliases; whether matching uses the entire token or only its first character; defaults, wrapping, clamping, no-op and error behavior; target selection; and introduction or removal version. Do not infer aliases or plugin-style names from analogous projects. Base absence claims on enumeration of the relevant parser in the pinned revision.

For dynamic configuration or switching, inspect the public API or command wrapper, target routing, rule/config mutation, refresh scheduling, object replacement, state migration and focus restoration, and persistence boundary. Distinguish state in memory, state surviving workspace recreation in the same process, state surviving config reload, and state written to disk that survives restart. Migrated objects and focus may survive while internal layout state is rebuilt.

When version differences matter, compare the relevant implementation files at the installed and stable tags and check release notes where available. Present version-specific availability rather than blending versions into one command list. Identify native and extension implementations by repository, namespace and supported versions; plugin commands are not native commands even if names overlap.

## Survey public configurations

When usage patterns matter, search several distinctive native tokens separately. Use code search for exact file hits and commit search to discover repositories when code search is sparse. Pin examples to full commit SHAs and record the file, relevant snippet and version clue; compare each against the upstream parser. Prove an example is native from its configuration or namespace, not merely an overlapping command name. Sample distinct repositories rather than forks, mirrors or copied examples. Separate recurring binding families from rare patterns and stale extension-only syntax. For an absent pattern, state what was searched; distinguish viewport operations from focus or object movement.

## Report

Lead with the answer, relevant baselines and direct answers to requested behaviors. Include command and argument details, version differences, runtime preservation, persistence, documentation/source conflicts and immutable evidence links as applicable. Disclose files changed or temporary artifacts created. Do not omit caveats that change whether a command works on the installed version.

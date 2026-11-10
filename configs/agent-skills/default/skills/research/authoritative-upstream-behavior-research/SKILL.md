---
name: authoritative-upstream-behavior-research
description: Investigate exact software behavior from authoritative upstream documentation, tagged source, release notes, and live-version evidence; use for command/API semantics, version drift, implementation-vs-doc conflicts, and concise evidence reports.
version: 1.1.0
---

# Authoritative Upstream Behavior Research

Use this skill when the user needs exact, source-backed behavior rather than a tutorial or best-effort recollection: accepted commands and arguments, runtime semantics, feature availability by version, persistence, migration behavior, or native-vs-plugin separation.

## Evidence hierarchy

Prefer evidence in this order, while reporting disagreements rather than hiding them:

1. **Live installed version and commit** for claims about the user's running system.
2. **Tagged upstream implementation** for exact parser branches and runtime behavior in that release.
3. **Current stable release notes and tagged implementation** for present availability.
4. **Official documentation** for supported public spelling and intended semantics.
5. **Upstream tests** for executable examples and edge behavior.
6. **Third-party sources** only to identify and separate plugin or compatibility behavior; never use them as proof of native behavior.

When official prose and tagged implementation conflict, state the conflict explicitly. Use implementation wording for actual behavior and documentation wording for intended/public behavior.

## Workflow

### 1. Establish all relevant baselines

Record separately:

- installed version, commit, and dirty/clean state when a live executable is accessible;
- latest stable tag and release date;
- current upstream branch commit if investigating unreleased behavior;
- documentation revision or repository commit.

Do not call `main` or current documentation equivalent to the user's installed release. A current page may already describe the next stable version. When executing the target is prohibited, resolve and hash its on-disk executable, then compare its platform, byte size and digest with official release-asset metadata before selecting tagged source. Keep that release match distinct from a running process's loaded image, native-addon provenance, effective configuration and historical creator attribution; matching today's executable cannot establish those other facts.

### 2. Pin evidence to immutable revisions

Use tagged source or full commit SHAs and construct permalinks with line ranges. A mutable documentation URL is useful for current public guidance, but pair it with a pinned source link for exact claims.

A reliable temporary-source pattern is:

```sh
d=$(mktemp -d "${SCRATCH_DIR:-.}/upstream-research.XXXXXX")
git clone --depth 1 https://github.com/ORG/REPO.git "$d"
git -C "$d" rev-parse HEAD
```

To compare an installed tag without disturbing the checkout:

```sh
git -C "$d" fetch --depth 1 origin tag vX.Y.Z
w=$(mktemp -d "${SCRATCH_DIR:-.}/upstream-tag.XXXXXX")
rmdir "$w"
git -C "$d" worktree add --detach "$w" vX.Y.Z
```

Use unique temporary directories instead of deleting a guessed path before cloning.

### 3. Enumerate behavior from the parser or dispatcher

For command inventories, locate the actual dispatch path and enumerate every recognized branch. Capture:

- exact command token;
- exact accepted argument tokens and aliases;
- whether matching uses the entire token or only its first character;
- defaults, wrapping, clamping, no-op behavior, and error behavior;
- target selection (focused window, active workspace, active special workspace, all workspaces, etc.);
- introduction/removal version.

Do not infer `first`, `last`, `toggle`, hyphenated aliases, or plugin-style names from analogous projects. Absence claims should be based on exhaustive parser enumeration in the pinned revision.

### 4. Trace runtime behavior end-to-end

For dynamic configuration or switching, inspect the complete path:

1. public API or command wrapper;
2. target routing;
3. rule/config mutation;
4. refresh scheduling;
5. algorithm/object replacement;
6. state migration and focus restoration;
7. persistence boundary.

Distinguish all state layers:

- in-memory until changed;
- survives workspace destruction/recreation in the same process;
- survives config reload;
- written to disk and survives restart.

Never describe an in-memory rule update as persistent configuration unless code writes it to durable storage.

### 5. Compare versions directly

Diff the installed tag against current stable for the exact implementation files. Confirm additions with both release notes and source. Present a small availability matrix rather than blending versions into one command list.

### 6. Separate native and extension namespaces

Identify each implementation by:

- repository and owner;
- built-in layout/module name;
- command/dispatcher namespace;
- archived/maintained status;
- supported upstream versions.

Plugin commands belong in a clearly labeled comparison section. Do not recommend them as native commands even when their semantics inspired the built-in feature.

### 7. Survey real public configurations when usage patterns matter

Treat repository examples as adoption evidence, not as authority for command validity.

1. Search for several distinctive native tokens separately, such as a layout's rare dispatcher names, config category, and one recently added command. A single broad query is usually polluted by unrelated projects.
2. Use authenticated GitHub code search for exact file hits and commit search to discover repositories from descriptive commits when code search is sparse or rate-limited.
3. Pin every example to the hit's full commit SHA. Record the repository, exact file, relevant snippet, commit date or a defensible version clue, and whether it agrees with the current upstream parser.
4. Prove an example is native from its configuration or namespace (for example, built-in layout selection or native config category), not merely because a command name overlaps with an older plugin.
5. Sample distinct repositories rather than forks, mirrors, generated references, issue reports, or copied plugin READMEs.
6. Synthesize recurring *families* of bindings—navigation, rearrangement, resizing, stacking, fit, and runtime switching—and separately list rare patterns and stale extension-only syntax.
7. For absent patterns such as direct first/last movement, state exactly what was searched and distinguish viewport/fit operations from focus or object movement.

GitHub code-search quotas are short-window resources. Batch only high-value queries, inspect rate status before issuing more, and use immutable raw URLs or commit endpoints for selected files rather than cloning many repositories. Temporary caches belong in a unique scratch directory (`$SCRATCH_DIR` or `mktemp -d`) and should be disclosed when the user prohibited edits.

### 8. Write the evidence report

Lead with the decisive answer. Prefer this order:

1. baselines checked;
2. direct answer to each requested behavior;
3. exact command/argument matrix;
4. version differences;
5. runtime preservation and persistence;
6. documentation/source discrepancies;
7. immutable evidence links;
8. files changed or temporary artifacts created.

Be concise, but do not omit caveats that change whether a command works on the installed version.

## Pitfalls

- **Current docs can be ahead of the installed version.** Verify every requested command against the installed tag.
- **Latest stable and current branch are different baselines.** Report unreleased behavior as such.
- **Documentation tables can omit implemented commands or simplify semantics.** Exhaustively inspect the parser.
- **A layout message may target an active special workspace before the regular workspace.** Trace routing rather than assuming.
- **Global layout configuration is not an active-workspace toggle.** Look for per-workspace rules or explicit target selectors.
- **Window preservation is not layout-state preservation.** Migrated windows and focus may survive while trees, columns, ratios, offsets, and widths are rebuilt.
- **Wrapping changes endpoint movement.** A repeated adjacent swap can overshoot when wrap is enabled; do not present it as a safe first/last operation.
- **Names can collide across native and plugin implementations.** Include the exact namespace in every command example.
- **“First-class support” may still be a cross-project protocol.** Inventory the key interceptor, process detector, editor dispatcher, companion plugin/WASM, CLI calls, permissions, and terminal key encoding separately; compare the complete integration rather than one repository.
- **Companion examples can lag companion releases.** Verify download URLs, minimum versions, native-API migrations, and first-load configuration semantics against the companion project’s latest release before recommending the parent README’s snippet.
- **Directional action names can hide asymmetry.** Trace every direction in the authoritative dispatcher; pane-or-tab actions may mean pane-then-tab horizontally but direct tab switching vertically.

## Verification checklist

Before finalizing, confirm:

- [ ] Installed version was checked when accessible.
- [ ] Latest stable was checked rather than assumed.
- [ ] Claims are tied to a tag or commit.
- [ ] Every recognized parser branch was inventoried.
- [ ] Exact and first-character argument matching are distinguished.
- [ ] Version-only commands are labeled.
- [ ] Target routing, state migration, and persistence were traced.
- [ ] Native and plugin behavior are separated.
- [ ] Documentation/source conflicts are called out.
- [ ] No user files were edited during research.

## References

| When you are… | Open |
|---|---|
| Comparing editor clients or plugins for a custom ACP agent, or judging what survives behind an ACP host | [references/acp-editor-integration-evaluation.md](references/acp-editor-integration-evaluation.md) |
| Designing an editor-observability workflow that must keep an agent's native TUI inside a terminal multiplexer | [references/native-agent-multiplexer-workspaces.md](references/native-agent-multiplexer-workspaces.md) |
| Asking whether one editor or plugin can emulate another's selection-first modal model | [references/selection-first-modal-editor-emulation.md](references/selection-first-modal-editor-emulation.md) |
| Researching one key family that must cross editor windows, multiplexer panes and tabs | [references/native-editor-multiplexer-navigation.md](references/native-editor-multiplexer-navigation.md) |
| Establishing why a harness produced large or recursively nested workspaces, and what actually prevents it | [references/worktree-cloning-and-gitignore.md](references/worktree-cloning-and-gitignore.md) |

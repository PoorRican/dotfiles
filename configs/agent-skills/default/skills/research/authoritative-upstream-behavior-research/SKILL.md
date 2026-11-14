---
name: authoritative-upstream-behavior-research
description: Investigate exact software behavior using version-specific upstream source, documentation, and live evidence. Use for command and API semantics, release drift, implementation conflicts, and comparisons of integrations.
version: 1.1.0
---

# Authoritative upstream behavior research

Current documentation, installed binaries, released source, and development branches may describe different behavior. Establish the relevant baseline before attributing behavior to any of them.

- Pin exact implementation claims to a tag or commit; distinguish documented intent from actual behavior and report conflicts.
- For a complete command inventory or absence claim, enumerate the relevant parser or dispatcher branches rather than relying on a failed search. Check argument matching, defaults, routing, and errors where relevant.
- Trace state changes to their persistence boundary: process memory, reload, recreation, and restart are different guarantees. Preserving objects does not necessarily preserve their internal layout or state.
- Separate native behavior from extensions and identify the namespace and version of each. Public configuration examples demonstrate usage, not validity.
- When execution is prohibited, a platform-specific official release-asset digest can help identify on-disk bytes; it does not establish the running image, loaded addons, configuration, or historical process identity.

| Research question | Reference |
|---|---|
| Establishing release baselines, tracing dispatch and persistence, or surveying public configurations | [Source investigation](references/source-investigation.md) |
| Comparing protocol integrations, MCP servers, authentication flows, or native and hosted interfaces | [Integration evaluation](references/acp-editor-integration-evaluation.md) |
| Comparing modal editors or routing keys between editors and terminal multiplexers | [Editor and multiplexer behavior](references/native-editor-multiplexer-navigation.md) |
| Investigating workspace copying, exclusion, or unexpectedly nested worktrees | [Worktree copying](references/worktree-cloning-and-gitignore.md) |

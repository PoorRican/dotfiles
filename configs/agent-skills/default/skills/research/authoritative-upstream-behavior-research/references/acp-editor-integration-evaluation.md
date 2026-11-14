# Evaluating protocol integrations

## Client, agent, and configuration

Separate the agent executable, client implementation, and effective local configuration. A client can connect successfully while failing to render permissions or structured diffs; an agent can support a capability that the client never advertises. Check enabled configurations, pinned revisions, command and environment setup, selectors, and key conflicts before recommending a replacement.

A successful ACP initialization establishes transport compatibility, not feature parity. When practical, probe the installed command and inspect negotiated capabilities, authentication methods, and protocol output; keep diagnostic output separate from the protocol stream. Compare client-advertised capabilities with agent fallback branches: missing filesystem, terminal, or elicitation support can change where actions execute, what is visible, or how approvals behave.

For a live ACP initialization probe, start the command and send one newline-delimited JSON-RPC object:

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"acp-research-probe","version":"1.0"},"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":false,"session":{"configOptions":true}}}}
```

Read and parse one stdout line with a bounded timeout. Record negotiated `protocolVersion`, `agentInfo`, prompt and session capabilities, load-session, MCP, image and embedded-context support, and advertised authentication methods. Terminate the subprocess after the response.

For a custom client provider, verify arbitrary adapter names, command and argv shape, environment variables, selector inclusion, whether switching preserves native state or creates a new session, and whether model/mode selection uses session config options or an extension. When practical, load the plugin headlessly from a temporary clone and inspect its merged configuration with synthetic providers.

Distinguish permission-request diffs, structured tool-call diffs, inline accept/reject, post-hoc worktree diffs, and a persistent review baseline. Rich rendering depends on what the agent emits as well as what the client supports.

## Native interface versus protocol host

Trace the CLI dispatcher and transport ownership to determine whether a protocol mode shares a live runtime with the native interface or starts a separate process. Resuming persisted sessions later does not prove concurrent attachment. Check for supported multi-frontend attachment or event fan-out before promising it; do not generalize a particular stdio implementation's architecture to the protocol itself.

For features that matter, trace the native handler, protocol dispatcher, shared engine, outbound event mapping, and client capability. Classify each as preserved, preserved but opaque, semantically changed, or unavailable. A shared engine does not prove equivalent autonomy, approval timing, background delivery, rewind behavior, or UI controls. Commands, session modes, prompt-triggered behavior, internal tools, and private extensions are distinct surfaces; a private extension requires a client that actually supports it.

If the requirement is only to observe files changed by a native agent, assess editor file reload and worktree review before introducing a protocol host. Session identity and continuation should be traced separately from live control: terminal or pane affinity can select a resume target without providing remote attachment. Terminal titles may convey transient state but are not stable session identifiers or proof of task completion.

Separate agent conversation persistence, pane lifetime, multiplexer detach and reattach, and server restart. Replacing a pane can change its terminal identity, so ordinary continuation in the same working directory does not guarantee the exact session will resume.

Trace how the installed agent derives terminal identity and what its continuation breadcrumb stores; inspect behavior when the working directory changes or the stored session moves or disappears. A session rail should keep manual priority independent of inferred idle or working state.

## MCP candidate comparison and authentication

Distinguish an official service API from an official MCP server. For serious candidates, inspect the actual exposed tools and implementation, not just registry listings or README claims. Compare read versus write coverage, deployment and authentication, maintenance and tests, licensing, and source transparency against the user's needs. Assess hosted offerings separately and label unverified capabilities as unknown. Forks, republished packages, or code-identical repositories are not independent implementations unless source divergence is established.

Discover candidates from vendor documentation, repository search and hosted listings. For serious repositories inspect metadata, README, package manifest, tool implementation, tests, changelog and issue tracker. Compare hashes of key source files and package manifests, and check package registries for wrappers or aliases pointing to the same repository. Note licensing differences even for identical code. For hosted options check whether authentication, tool coverage and source are actually public; do not infer coverage from marketing copy. Call out summary endpoints presented as live data.

Before promising an interactive login or refresh token, inspect the released package's documentation and authentication implementation. Distinguish client-credentials access, externally supplied bearer tokens, and authorization-code flows; identify which component performs consent, exchanges codes, and refreshes tokens. Check the application's grant type, registered redirect URI, and required scopes against the provider's current documentation. An upstream issue or proposed change does not establish that a released package supports the flow.

If an external authorization-code flow is needed, verify the grant type, exact redirect URI and scopes with the provider. Complete browser consent, exchange an issued code, securely store refresh credentials, and arrange for refreshed access tokens to reach the server; an externally supplied bearer token alone does not imply the server refreshes it. For headless use, initial consent can occur on a browser-equipped machine. If authorization fails before a callback is attempted, investigate provider-side app and redirect configuration before debugging the local listener.

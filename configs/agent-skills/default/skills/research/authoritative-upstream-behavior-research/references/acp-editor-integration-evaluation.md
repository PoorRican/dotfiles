# Evaluating ACP editor integrations

Use this reference when comparing editor clients for custom ACP agents, especially when the agent command is not a built-in preset.

## Separate the layers

Evaluate three independent layers rather than treating “ACP support” as one feature:

1. **Agent executable** — exact stdio startup command, ACP protocol version, advertised capabilities, authentication behavior, and stderr/stdout hygiene.
2. **Editor client** — custom command registration, agent/backend selector, selected-code context, tool/permission rendering, diff rendering, and session lifecycle.
3. **Local configuration** — enabled plugins, dead/unloaded configs, global keymap collisions, pinned revisions, and unrelated completion systems.

A plugin may have an excellent UI but incomplete ACP support; an agent may emit file edits that a client only renders as generic tool calls. Verify both sides.

## Repository inventory

Before recommending a replacement:

- Locate every AI/coding plugin config and trace which ones are actually imported by the plugin manager.
- Read the lockfile revision and date for each enabled plugin.
- Identify stale or platform-specific commands in custom provider definitions.
- Check global mappings for collisions with native editor behavior. In Neovim, `<C-i>` is the forward-jumplist key and should not be casually repurposed.
- Distinguish source-code completion from completion inside an agent prompt. `Tab` accepting `@file` or slash-command completion is not Cursor-style whole-code completion, but users may still want the binding removed.

## Live ACP initialization probe

Do not infer compatibility from `--help` alone. Start each command and send an ACP `initialize` JSON-RPC request as one newline-delimited JSON object:

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"acp-research-probe","version":"1.0"},"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":false,"session":{"configOptions":true}}}}
```

Read one stdout line with a bounded timeout, parse it as JSON, and record:

- negotiated `protocolVersion`;
- `agentInfo` name/version;
- `promptCapabilities`;
- `sessionCapabilities`;
- `loadSession`, MCP, image, and embedded-context support;
- advertised authentication methods.

Terminate the subprocess cleanly after the response. Treat stderr as diagnostics; stdout must remain protocol-only.

## Custom-command verification

For each candidate editor plugin, verify from current source or official docs:

- whether arbitrary ACP adapter/provider names are accepted;
- command and argv shape;
- whether environment variables can be supplied;
- whether the built-in selector includes user-defined providers;
- whether provider switching creates a fresh session, replays visible history, or preserves native agent state;
- whether model/mode selection uses ACP session config options or a legacy extension.

When practical, load the plugin in headless Neovim from a temporary clone, call its setup function with two synthetic custom providers, and inspect the merged configuration. This catches documentation/config-schema drift without editing the user’s files.

## Edit visibility matrix

“Shows edits” can mean different things. Report these separately:

- diff attached to a permission request before an edit;
- structured ACP file-diff/tool-call rendering;
- accept/reject of an inline generated edit;
- post-hoc worktree diff;
- persistent review baseline with hunk navigation/comments.

State when visibility depends on the agent emitting structured diff content. A client-side Git baseline can review edits even when ACP messages do not contain rich diffs, but has different semantics and complexity.

## Recommendation pattern

Prefer the smallest client that satisfies the primary workflow, then identify a concrete fallback trigger. Example:

- start with a lean ACP-native client for custom backends, explicit selected-code context, and permission diffs;
- move to a richer client only if structured review of every changed hunk becomes a real requirement;
- choose a feature-heavy “IDE-like” client when its workspace/Zen UI is itself a requirement.

Do not replace an already-installed client until checking whether the apparent limitation is only stale configuration or a pinned revision behind major upstream fixes.

## Native UI versus protocol-host UI

Do not assume that an ACP connection can sit quietly behind an agent's native TUI. Verify the process architecture separately from the protocol specification:

1. Inspect the CLI mode dispatcher: is ACP a mutually exclusive startup branch or a service attached to the interactive runtime?
2. Inspect transport ownership: if stdin/stdout are reserved for JSON-RPC, determine whether another supported UI transport exists.
3. Distinguish a second process from a second frontend on the same live session. Shared persisted session files allow later resume; they do not prove synchronized concurrent control.
4. Check whether the implementation supports daemon attachment, event fan-out, or multiple frontends. Without one of those, a separately launched TUI is an unrelated live process even if it can later load the same session.

ACP itself does not universally mandate a headless agent, but most stdio implementations make the client the UI owner. Phrase conclusions at the implementation level: “this agent's ACP subcommand is a dedicated headless server mode,” not “ACP can never have an agent-side UI.”

If the user's actual requirement is only reloading files edited by the native CLI, first inspect the editor's `autoread`/`checktime` behavior. ACP may add no value; an embedded/external terminal plus file-change detection preserves the native application control plane.

## Evaluate semantic preservation, not just protocol compatibility

For feature-rich agents, “initialize succeeded” proves transport compatibility only. Build a feature-survival matrix with four states:

- **preserved** — the same engine path and controls remain available;
- **preserved but opaque** — internal behavior runs, but the client cannot observe or control it;
- **semantically changed** — the feature runs with altered timing, approval, autonomy, or persistence;
- **unavailable** — no protocol command, extension method, or reachable text handler exposes it.

Trace each distinctive feature through:

1. the native TUI command/handler;
2. the ACP command dispatcher and advertised slash commands;
3. advertised session modes and config options;
4. the shared session/agent engine beneath both frontends;
5. outbound event mapping, including whether internal events are filtered;
6. client capabilities actually advertised by the editor plugin.

A shared engine does not imply equivalent behavior. In particular, inspect:

- agent-initiated turns versus client-owned request/response turns;
- background jobs and delivery-drain behavior;
- multi-agent peer messaging and whether chatter is intentionally hidden;
- rewind/retraction semantics after already-streamed output;
- interactive dashboards, selectors, widgets, status lines, and transcript viewers;
- cold-revival or process-global registries excluded from multi-session ACP hosts.

## Commands, modes, magic keywords, and extensions are different surfaces

Do not group every branded execution feature under “ACP modes.” Determine which mechanism actually implements it:

- **Session modes** must appear in `availableModes` and be accepted by `session/set_mode` or session config options.
- **Slash commands** survive only when the ACP/text dispatcher exposes a non-TUI handler; TUI-only handlers are normally filtered.
- **Magic keywords** may survive if ACP ultimately calls the same user-prompt method that injects hidden steering notices, even when they have no ACP mode entry.
- **Internal tools/subagents** may continue running while their native dashboard and peer-control UI disappear.
- **Private extension methods** preserve functionality only for clients explicitly written to advertise and call them; they are not generic interoperability.

Inspect command registries for separate `handle` and `handleTui` paths rather than inferring availability from command names or help text.

## Client capability mismatches can change safety semantics

Compare the agent's behavior against the exact `clientCapabilities` sent by each editor client. Check at least:

- filesystem read/write;
- terminal execution;
- form elicitation;
- session config-option types;
- authentication terminal support;
- session list/load/resume/fork support.

Then inspect fallback branches when a capability is absent. Missing form elicitation may silently select defaults, cancel workflows, or even auto-approve an action to avoid stranding the session. Missing client filesystem/terminal support may cause the agent to execute locally and merely report tool activity, reducing editor-mediated diff visibility.

Never describe a feature as supported merely because the agent implements it. State whether the chosen client advertises and renders the required capability.

## Evidence and hygiene

- Pin plugin claims to release tags or full commit SHAs and dates.
- Compare the local lock revision with current stable/current branch rather than saying only “outdated.”
- Use official agent documentation for startup semantics and live initialization for installed capabilities.
- Inspect installed source when proprietary behavior is newer or more specific than public documentation.
- Keep upstream clones under unique temporary directories (under `$SCRATCH_DIR` when set).
- Avoid broad searches through session/log directories: they may expose credential metadata or personal identifiers. Restrict searches to implementation and documentation trees.
- Do not change repository files during the research phase.

# Native agent workspaces in terminal multiplexers

Use this reference when designing an editor-observability workflow that must preserve a coding agent's native terminal UI. The concrete case that motivated it involved OMP, Zellij, and Neovim, but the research and design method applies to other terminal agents and multiplexers.

## Preserve the application control plane

Treat a feature-rich native agent TUI as part of the application, not as a disposable renderer. Before proposing ACP, RPC, or an editor-owned chat UI, inventory agent-specific control-plane features: autonomous modes, advisor/critic behavior, transcript rewinds, subagent hubs, peer messaging, background jobs, custom commands, status indicators, audio, and extension widgets.

Classify each feature as:

- engine behavior that survives without the TUI;
- behavior that survives but becomes opaque;
- behavior whose timing or autonomy changes under a client-owned request/response protocol;
- native UI/control functionality that disappears entirely.

When native behavior matters more than prompt integration, keep the ordinary agent process and make the editor an observability/review surface around filesystem and Git state.

## Trace terminal and multiplexer affinity from source

Do not interpret marketing text such as “each split keeps its own session” as a pane-management API. Trace the exact identity and resume path:

1. Find how the agent identifies a terminal: TTY path, multiplexer pane ID, terminal-emulator pane ID, or environment fallback.
2. Find what the breadcrumb stores: cwd, session file/ID, fresh-session marker, or only a timestamp.
3. Trace `continue` behavior when pane identity matches, cwd differs, the worktree moved, or the breadcrumb target disappeared.
4. Distinguish later session resume from concurrent same-session attachment.

In the OMP case (traced from source; recheck against the installed version), terminal identity prefers the stdin TTY and falls back to Zellij session+pane, tmux pane, CMUX surface, Kitty window, WezTerm pane, Terminal.app session, or Windows Terminal session. Its breadcrumb maps terminal identity to cwd and a session file. `omp -c` first considers that terminal-specific breadcrumb, then applies cwd and stale/moved-worktree handling. This is session affinity, not remote control or live multi-frontend attachment.

## Reuse terminal-title state before inventing an integration protocol

Many native TUIs publish useful state through terminal titles or notifications. Verify title generation and the multiplexer's pane-update events before adding a side channel.

OMP title-state semantics observed in source (recheck against the installed version):

- idle/user turn: `π > label`;
- working: animated spinner separator;
- blocked for user attention: `π ! label`.

A multiplexer rail can normalize these into stable states such as idle, working, attention, exited, and unknown. Do not redraw at animation frequency, and do not infer semantic completion from “idle.” Keep machine-observed run state separate from manual task priority.

## Session-rail architecture boundary

A small native multiplexer plugin can coordinate panes without controlling the agent protocol. A useful first production slice is:

- a selectable rail plugin pane;
- a stack of rail-launched native agent terminal panes;
- an existing independent right-hand pane (editor, shell, or other observer);
- manual priority buckets such as Now, Next, Later, and Parked;
- runtime state inferred only from pane lifecycle and normalized title state;
- focus/reveal, launch, reorder, park, and close actions.

Prefer the rail owning only panes it launches. Do not initially discover or adopt arbitrary processes, parse transcripts, submit prompts, inspect subagents, or infer priorities. Explicit ownership makes close/focus/relaunch behavior safe and testable.

For Zellij, verify the installed plugin API provides the needed primitives and permissions. Relevant API families include pane updates, command-pane opening, returned pane IDs, pane cwd/command queries, pane focus, and `stack_panes`. Keep permissions narrow: application-state read, application-state change, and command launch should suffice; avoid full filesystem, scrollback, and stdin-writing permissions unless a later requirement proves necessary.

## Cwd and anchor-pane discipline

A plugin process's own cwd is not necessarily the intended project root. Choose an explicit anchor terminal pane and query its cwd. A pragmatic first rule is the largest or rightmost terminal pane in the active tab, with a visible error when no candidate exists. Existing sessions keep their launch cwd; new sessions copy the anchor's current cwd.

Do not silently guess the multiplexer server cwd.

## Persistence boundaries

Separate:

- the agent's durable conversation;
- the terminal process and pane lifetime;
- the rail's manual metadata;
- multiplexer detach/reattach;
- multiplexer server restart/session resurrection.

An in-memory first slice can still be production-worthy if detach/reattach to the same live server preserves it and metadata loss cannot delete agent sessions or repository state. Durable reconstruction is a later feature because pane IDs are not durable identities and restored panes may not map cleanly to persisted agent conversations.

Never promise exact-session relaunch merely because `agent -c` exists. Replacing a pane can change its TTY/pane ID. Phrase the action as “run the agent's normal continuation logic in the original cwd” unless an explicit session ID or agent hook is captured.

## Review-oriented workflow boundary

Keep responsibilities clear:

- multiplexer: tabs, panes, focus, and process lifetime;
- native agent: conversations, subagents, and execution modes;
- Git/jj: change history and checkpoints;
- worktrees: isolation;
- editor: file reload, Git status, diffs, diagnostics, navigation, and code review;
- rail: correlation and prioritization only.

This prevents a useful launcher from growing into a second agent UI.

## Pitfalls

- Equating session resume with live same-session attachment.
- Equating a native terminal title with a stable session identifier.
- Coupling manual priority to inferred idle/working state.
- Parsing transcripts when pane IDs and titles satisfy the first requirement.
- Switching an existing editor process across worktrees without considering LSP, buffer, and Git-root state.
- Adding persistent registries before defining how restored panes are reconciled.
- Expanding the first slice to arbitrary agents, projects, worktrees, Git status, and prompt transport before validating the core rail interaction.

---
name: terminal-multiplexer-workflows
description: Use when answering, configuring, or troubleshooting terminal multiplexer workflows such as Zellij/tmux pane, tab, floating pane, grouping, keybinding, and CLI-action behavior.
---

# Terminal Multiplexer Workflows

Use this skill when the user asks how to operate or configure terminal multiplexers, especially Zellij pane/tab/floating-pane workflows.

## Core approach

1. **Ground behavioral claims in installed help or upstream docs.** Multiplexer terminology and behavior changes across versions; do not rely on memory when the question is about exact actions/keybindings.
2. **Check the installed version and action surface when possible.** For Zellij, useful probes are:
   - `zellij --version`
   - `zellij action --help`
   - `zellij setup --dump-config`
   - `zellij action <subcommand> --help`
3. **Distinguish UI keybindings, config action names, and CLI subcommands.** Zellij config actions are CamelCase (eg. `TogglePanePinned`) while CLI subcommands are kebab-case when exposed (eg. `toggle-pane-pinned`). Some config/plugin actions are not exposed as direct CLI subcommands.
4. **Use precise Zellij terminology.** A Zellij “window” in user language usually means a pane. Floating is a pane property; tabs are not themselves floating panes.
5. **When corrected by the user, re-check docs/source and explicitly repair the model.** Avoid doubling down on plausible-but-wrong analogies from tmux or from action names.

## Zellij pane/tab/floating-pane notes

- `Ctrl-p e` / `TogglePaneEmbedOrFloating` toggles the focused pane between tiled and floating.
- `Ctrl-p w` / `ToggleFloatingPanes` toggles visibility of floating panes in the current tab; if none exist, it can create one.
- `Ctrl-p i` / `TogglePanePinned` pins a floating pane, but **pinning is not cross-tab follow behavior**. In Zellij docs, pinning means the floating pane stays on top and/or remains visible when floating-pane visibility is toggled. Do not tell the user that a pinned pane follows them across tabs.
- Zellij does not expose ordinary “floating tabs”; floating applies to panes.
- `BreakPane`, `BreakPaneLeft`, and `BreakPaneRight` are keybinding/config actions for breaking a pane out of its tab; they may not appear as CLI `zellij action` subcommands in every installed version.

## Moving floating panes between tabs in Zellij

For current Zellij versions with multiple-pane selection:

1. Focus the pane to move. It can be floating or tiled.
2. Toggle it into the pane group with the default keybinding:
   - `Alt-p` → `TogglePaneInGroup`
3. The multiple-select helper appears. Use:
   - `r` to break/move selected pane(s) to the tab on the right; if there is no right tab, it creates a new tab.
   - `l` to break/move selected pane(s) to the tab on the left; if there is no left tab, it creates a new tab.
   - `b` to break selected pane(s) into a new tab.
   - `f` to float selected pane(s).
   - `e` to embed selected floating pane(s).
   - `s` to stack selected pane(s).
   - `c` to close selected pane(s).
   - `Esc` to cancel.
4. If the target tab is not adjacent, either move/reorder tabs until it is adjacent or move the pane stepwise. Default tab movement: `Alt-i` moves the current tab left, `Alt-o` moves it right.

Multiple-selection helper details:

- `Alt-p` toggles the focused pane in/out of the group.
- `Alt-Shift-p` toggles follow-focus marking, adding focused panes to the group as focus moves.
- Default config bindings live under `shared_except "normal" "locked"`:
  ```kdl
  bind "Alt p" { TogglePaneInGroup; }
  bind "Alt Shift p" { ToggleGroupMarking; }
  ```
- These group-selection actions may not be present as direct `zellij action` CLI subcommands even though they exist as config actions.

## Verification/pitfalls

- If `Alt-p` appears to do nothing, check whether Zellij is locked (`Ctrl-g` toggles lock mode) and whether custom keybindings removed `TogglePaneInGroup`.
- Avoid assuming a feature is a setting. Search the docs for exact terms (`pinned`, `TogglePanePinned`, `move_to_focused_tab`, `break_panes_to_tab_with_index`) and compare with installed `zellij action --help`.
- `move_to_focused_tab true` applies to `LaunchOrFocusPlugin` plugin panes, not arbitrary terminal panes.
- Zellij has plugin API functions such as `break_panes_to_tab_with_index` / `break_panes_to_tab_with_id` that can move panes to existing tabs, but they are plugin APIs, not necessarily end-user CLI subcommands.

## References

- `references/zellij-pane-tab-management.md` contains condensed docs/source excerpts from the session that established the pinning and multiple-select behavior.
# Zellij pane/tab/floating-pane management notes

Condensed from a session where the user asked how to merge/move Zellij panes/tabs and make panes floating. The important correction was that **pinned floating panes do not follow across tabs**.

## Version context

Observed installed version during the session:

```text
zellij 0.44.3
```

Installed CLI action list included `toggle-pane-pinned`, `toggle-pane-embed-or-floating`, `toggle-floating-panes`, `new-pane`, `list-panes`, `list-tabs`, `move-pane`, etc. It did **not** include direct CLI subcommands named `break-pane`, `toggle-pane-in-group`, or `toggle-group-marking`, even though the corresponding config/keybinding actions exist.

## Pinning behavior

Docs/source evidence:

- `TogglePanePinned`: “Toggle the pinned state of a floating pane. A pinned floating pane stays on top of other panes.”
- CLI `toggle-pane-pinned`: “If the current pane is a floating pane, toggle its pinned state (always on top).”
- Plugin API `set_floating_pane_pinned`: “Pinned floating panes remain visible when toggling floating pane visibility.”
- `FloatingPaneCoordinates.pinned`: “Whether the floating pane is pinned (stays visible when toggling floating panes).”

Conclusion: pinning is z-order / floating visibility behavior, not “global pane follows active tab.”

## Moving floating panes to another tab

The practical UI path is Zellij’s multiple-pane select/group helper:

1. Focus pane.
2. `Alt-p` (`TogglePaneInGroup`) to select/toggle the pane into the group.
3. In the multiple-select helper:
   - `r` calls `break_panes_to_tab_with_index` for the tab on the right when one exists, otherwise breaks to a new tab.
   - `l` calls `break_panes_to_tab_with_index` for the tab on the left when one exists, otherwise breaks to a new tab.
   - `b` breaks grouped pane(s) to a new tab.
   - `f` floats grouped pane(s).
   - `e` embeds grouped pane(s).
   - `s` stacks grouped pane(s).
   - `c` closes grouped pane(s).

Source details from `default-plugins/multiple-select/src/main.rs`:

```rust
BareKey::Char('b') => self.break_grouped_panes_to_new_tab(),
BareKey::Char('s') => self.stack_grouped_panes(),
BareKey::Char('f') => self.float_grouped_panes(),
BareKey::Char('e') => self.embed_grouped_panes(),
BareKey::Char('r') => self.break_grouped_panes_right(),
BareKey::Char('l') => self.break_grouped_panes_left(),
BareKey::Char('c') => self.close_grouped_panes(),
```

And for right/left moves:

```rust
if Some(own_tab_index + 1) < self.total_tabs_in_session {
    break_panes_to_tab_with_index(&pane_ids, own_tab_index + 1, true);
} else {
    break_panes_to_new_tab(&pane_ids, None, true);
}
```

```rust
if own_tab_index > 0 {
    break_panes_to_tab_with_index(&pane_ids, own_tab_index.saturating_sub(1), true);
} else {
    break_panes_to_new_tab(&pane_ids, None, true);
}
```

## Default keybindings involved

From dumped default config:

```kdl
pane {
    bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
    bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
    bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
}

tab {
    bind "b" { BreakPane; SwitchToMode "Normal"; }
    bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
    bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
}

shared_except "normal" "locked" {
    bind "Alt i" { MoveTab "Left"; }
    bind "Alt o" { MoveTab "Right"; }
    bind "Alt p" { TogglePaneInGroup; }
    bind "Alt Shift p" { ToggleGroupMarking; }
}
```

## Docs search terms that helped

Search these when re-validating future answers:

- `TogglePanePinned`
- `toggle-pane-pinned`
- `FloatingPaneCoordinates pinned`
- `set_floating_pane_pinned`
- `TogglePaneInGroup`
- `ToggleGroupMarking`
- `break_panes_to_tab_with_index`
- `move_to_focused_tab`

## Answering guidance

If asked “can pinned panes follow me everywhere?” say no for ordinary panes in current Zellij; it would be a nice feature, but pinning currently means staying on top / remaining visible during floating-pane visibility toggles. Do not present this as a config setting unless docs show a new one.
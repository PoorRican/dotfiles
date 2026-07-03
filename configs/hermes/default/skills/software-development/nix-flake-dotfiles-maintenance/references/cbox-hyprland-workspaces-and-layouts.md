# cbox Hyprland workspaces and layouts

Session-derived notes for evolving the user's cbox Hyprland setup in `~/dotfiles/configs/hypr/hyprland.lua` plus Waybar workspace display in `~/dotfiles/configs/waybar/config.jsonc`.

## Current distinction to preserve

- Hyprland config currently binds numeric workspaces 1-10 with `SUPER+[0-9]` and moves windows with `SUPER+SHIFT+[0-9]`.
- Semantic icons currently come from Waybar, not Hyprland workspace rules:
  - 1 `` terminal/general
  - 2 `` browser (user wants non-Chrome icon if revisited)
  - 3 `` email
  - 4 `` files
  - 5 `` chat
  - 6 `` music
  - 7 `󰊴` games
  - 8 `` debug/bug
- Waybar uses `hyprland/workspaces` with `persistent-workspaces` for 1-8 and `format-icons`; changing workspace meaning should update Waybar icons/labels as well as Hyprland bindings/rules.

## Hyprland terminology

- Desktop/work area: **workspace**.
- Per-workspace settings: **workspace rules** via `hl.workspace_rule({ workspace = "...", ... })`.
- Tiling algorithm: **layout** (`dwindle`, `master`, `scrolling`, `monocle`, or `lua:<name>`).
- Per-layout commands: **layout messages** via `hl.dsp.layout("...")`.
- App placement/matching: **window rules** via `hl.window_rule({ match = {...}, ... })`.
- Scratchpad overlay: **special workspace** (`special:name`).
- i3 tabbed/stacked-like containers: **groups**, not a separate layout.

## Per-workspace layouts

Hyprland supports per-workspace layouts through workspace rules:

```lua
hl.workspace_rule({ workspace = "1", layout = "dwindle" })
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
hl.workspace_rule({ workspace = "3", layout = "master" })
```

Named workspaces are possible and often clearer:

```lua
hl.workspace_rule({ workspace = "name:browser", layout = "scrolling" })
hl.workspace_rule({ workspace = "name:notes", layout = "monocle" })
hl.workspace_rule({ workspace = "name:engineering", layout = "master" })
```

Some layouts accept workspace-scoped `layout_opts`, for example scrolling direction:

```lua
hl.workspace_rule({
  workspace = "name:browser",
  layout = "scrolling",
  layout_opts = { direction = "right" },
})
```

## Layout mental models for this user

The user is exploring a reduced set of roles rather than a large fixed taxonomy:

- browser/research
- notes/Obsidian
- engineering

Important caveat: Hyprland workspaces are not normally shown side-by-side on one monitor. A visual model like `<browser> | <obsidian> | engineering` maps better to **windows/columns inside a scrolling workspace** than to three simultaneously visible workspaces.

Candidate mappings:

| Workspace | Purpose | Candidate layout |
| --- | --- | --- |
| `name:browser` / research | browser + optionally Obsidian | `scrolling` or `dwindle` |
| `name:notes` | Obsidian solo brainstorming | `monocle` or ordinary single-window tiling |
| `name:engineering` | IDE/terminals + optionally Obsidian | `master` or `dwindle` |

## Obsidian summon options

A single Wayland window can only be on one workspace at a time. Hyprland can move it, not clone it.

Options:

1. **Move/summon existing Obsidian window to current workspace** with a custom binding/script/Lua function that finds the Obsidian window, moves it to the active workspace, and focuses it.
2. **Use a special workspace** like `special:obsidian` for scratchpad-style summon/hide. This overlays or toggles notes but is not a true side-by-side tiling partner.
3. **Use multiple Obsidian windows** if Obsidian/vault workflow supports it cleanly; Hyprland can place separate windows on different workspaces.

## Scrolling layout notes

Scrolling layout is an infinite tape of windows/columns inside a workspace. Useful for a spatial research tape such as browser | notes | engineering-related docs.

A proven low-risk test setup is to make numeric workspace `4` a scrolling-layout playground while leaving the rest of the workspace model alone:

```lua
hl.workspace_rule({
  workspace = "4",
  layout = "scrolling",
  layout_opts = { direction = "right" },
})
```

Useful layout messages and bindings from the cbox experiment:

```lua
hl.bind(mainMod .. " + comma",          hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + period",         hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + CTRL + comma",   hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + CTRL + period",  hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + I",       hl.dsp.layout("consume"))
hl.bind(mainMod .. " + CTRL + O",       hl.dsp.layout("expel"))
```

Mental model to explain to the user: `SUPER+4` enters the tape, `SUPER+SHIFT+4` sends a window there, `SUPER+,` / `SUPER+.` scroll the viewport by column, `SUPER+CTRL+,` / `SUPER+CTRL+.` focus neighboring columns, `consume` pulls the current window into the previous column, and `expel` isolates it into its own column.

Other relevant layout messages:

```lua
hl.dsp.layout("promote") -- current window to its own new column
```

Fullscreen and group controls that are known to work with the Hyprland Lua parser:

```lua
hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + slash",          hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + G",              hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab",            hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + Tab",    hl.dsp.group.prev())
hl.bind(mainMod .. " + SHIFT + G",      hl.dsp.group.move_window())
hl.bind(mainMod .. " + CTRL + G",       hl.dsp.group.lock_active({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + SHIFT + G", hl.dsp.group.lock({ action = "toggle" }))
```

Mental model: a group is a tabbed/stacked container inside the current layout. In scrolling layout, it behaves well as one stable column in the tape. `lock_active` is the closest built-in way to preserve a few grouped windows together; it prevents accidental group-membership changes, but it does not hard-freeze arbitrary tiled geometry.

Verification after applying live or declaratively:

```bash
hyprctl -j activeworkspace | jq .tiledLayout
# expect "scrolling" while focused on workspace 4
```

## Master layout notes

Master layout is a main pane plus a visible stack of secondary windows. Good for one primary engineering/browser window plus references/logs/chat.

`master.new_status = "master"` means new windows become master. For a stable main pane with new windows in the side stack, prefer:

```lua
hl.config({
  master = {
    new_status = "slave",
    mfact = 0.60,
    orientation = "left",
  },
})
```

Useful layout messages:

```lua
hl.dsp.layout("swapwithmaster master")
hl.dsp.layout("focusmaster")
hl.dsp.layout("cyclenext")
hl.dsp.layout("cycleprev")
hl.dsp.layout("swapnext")
hl.dsp.layout("swapprev")
hl.dsp.layout("orientationnext")
hl.dsp.layout("mfact +0.05")
hl.dsp.layout("mfact -0.05")
```

## Keybinding implementation notes

Recent proven Lua dispatchers:

```lua
hl.dsp.window.move({ direction = "left" })
hl.dsp.window.resize({ x = 40, y = 0, relative = true })
hl.dsp.window.resize({ x = 0, y = -40, relative = true })
```

New Lua binds in the file may not appear after `hyprctl reload`; verify with `hyprctl -j binds`. If absent, either restart Hyprland or apply live with `hyprctl eval 'hl.bind(...)'` for immediate smoke testing.

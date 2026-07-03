# cbox Hyprland scratchpad launchers and live Lua bind debugging

Session-derived notes for building floating/sticky launchers on cbox Hyprland 0.55.x with Lua config, Ghostty, Rofi, and Zellij.

## What worked

- For persistent launcher scripts, install a Home Manager-managed helper under `~/.local/bin/` and expose it through a `.desktop` entry in `~/.local/share/applications/` so it is available from Rofi `drun`.
- For a Zellij workspace launcher, prefer a dedicated layout and session name:
  - script changes to the target working directory first
  - if session exists: `zellij attach --force-run-commands <session>`
  - otherwise: `zellij --session <session> --new-session-with-layout <layout>`
- Validate layers separately:
  - shell syntax: `bash -n bin/<script>`
  - Lua syntax: `luac -p configs/hypr/hyprland.lua`
  - Zellij layout: `zellij setup --dump-layout <layout>`
  - desktop entry: `desktop-file-validate ~/.local/share/applications/<entry>.desktop`
  - Home Manager: `home-manager build --flake .#cbox --no-write-lock-file` before `switch`

## Hyprland Lua dispatch pitfalls

Hyprland 0.55.x with Lua config may reject legacy CLI dispatch forms such as:

```bash
hyprctl dispatch togglespecialworkspace pk-wiki
hyprctl dispatch exec '...'
```

Use Lua dispatcher expressions instead:

```bash
hyprctl dispatch 'hl.dsp.workspace.toggle_special("pk-wiki")'
hyprctl dispatch 'hl.dsp.exec_cmd("/path/to/command --args")'
```

For shell scripts that must pass dynamic command strings, quote for Lua string syntax before embedding in `hl.dsp.exec_cmd(...)`.

## Reload vs live bind updates

`hyprctl reload` may reload the file but not reliably register newly added Lua keybinds in the running session. For immediate live testing, use `hyprctl eval`:

```bash
hyprctl eval 'local home=os.getenv("HOME") or "/home/swe"; local hmBin=home .. "/.local/state/nix/profiles/home-manager/home-path/bin"; local menu=hmBin .. "/rofi -show drun -show-icons"; hl.bind("SUPER + Space", hl.dsp.exec_cmd(menu))'
```

After applying Home Manager and reloading, verify live binds with:

```bash
hyprctl -j binds | jq -r '.[] | select(.key=="Space" or .key=="R" or .key=="K") | {key,modmask,dispatcher,arg} | @json'
```

## Rofi debugging

If the user reports Rofi stopped working after scratchpad experiments, check whether the problem is actually focus/workspace state rather than Rofi itself:

```bash
pgrep -a rofi || true
timeout 2 ~/.local/state/nix/profiles/home-manager/home-path/bin/rofi -show drun -show-icons >/tmp/rofi.out 2>/tmp/rofi.err || true
hyprctl layers -j | jq -r '.. | objects | select(.namespace? == "rofi") | @json'
```

Fontconfig warnings alone are not proof of failure. If Rofi appears as a layer, the launcher is alive.

## Do not hide the wrong window

When manipulating special workspaces, never assume the active window is the scratchpad window. In the observed failure, a browser window was accidentally moved to `special:pk-wiki`, making it disappear. Before any move/hide/close operation:

1. Inspect clients and identify the exact target by class/title/address.
2. If Ghostty does not expose the requested custom `--class`, fall back to matching a stable title prefix such as `pk-wiki`.
3. Do not call active-window movement commands unless the active window is verified to be the target.
4. If a user says a window disappeared, immediately inspect clients on special workspaces and move the user app back to a normal workspace.

Useful probes:

```bash
hyprctl -j clients | jq -r '.[] | select(.workspace.name | startswith("special")) | {address,class,title,workspace,pid} | @json'
hyprctl -j monitors | jq -r '.[] | {activeWorkspace,specialWorkspace} | @json'
```

To focus a known window by address through Lua dispatch:

```bash
hyprctl dispatch 'hl.dsp.focus({ window = hl.get_window("address:0x...") })'
```

## Sticky floating geometry

For pinned/sticky floating scratchpads, do not call `hl.dsp.window.center()` on every show/toggle. Re-centering makes the panel jump back to the middle after the user manually drags it elsewhere. Instead:

1. Read the target client's `.at` and `.size` from `hyprctl -j clients` and persist them in `$XDG_RUNTIME_DIR/<launcher>/geometry` before hiding or toggling focus away.
2. When the window is already visible on a normal workspace, save its current geometry before any focus/move/restore step so a stale saved value cannot snap it backward.
3. When showing from a special workspace, move/focus/pin the exact target window, then restore with exact Lua dispatchers:

```bash
hyprctl dispatch 'hl.dsp.window.resize({ x = WIDTH, y = HEIGHT, exact = true })'
hyprctl dispatch 'hl.dsp.window.move({ x = X, y = Y, exact = true })'
```

Keep the initial launch centered via inline rules if desired; only repeated show/toggle should preserve the user's chosen placement.

## Ghostty class/title note

On this setup, a Ghostty window launched with `--class=com.projectkairos.wiki --gtk-single-instance=false --title=pk-wiki` still appeared in Hyprland as class `com.mitchellh.ghostty`, while the title contained `pk-wiki`. Scratchpad detection should therefore support both the intended class and a title prefix fallback.

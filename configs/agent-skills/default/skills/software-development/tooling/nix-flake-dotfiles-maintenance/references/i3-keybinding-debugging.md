# Desktop integration

## Session and Home Manager

For a desktop migration, distinguish the system-owned compositor/session startup from Home Manager-owned user configuration. On a non-NixOS host, a display-manager wrapper can accidentally select a different compositor from PATH; check the launched binary and its environment. For a missing Nix command in new shells, check both PATH and the inherited `__ETC_PROFILE_NIX_SOURCED` guard: a reduced session PATH with the guard already set can prevent profile initialization from restoring the Nix bin directory.

For Hyprland Lua sessions, inspect registered bindings and workspace rules as well as the deployed configuration; a reload may not register a new Lua binding or every workspace rule. Legacy dispatcher syntax can fail under the Lua parser. If live testing is authorized, `hyprctl eval` can apply a Lua expression temporarily, but it is not proof of durable configuration. Do not restart a live compositor or close windows merely to test a change.

Identify a scratchpad window by its actual class, title or address before moving it; the active window may be unrelated, and a terminal may not expose the requested class. If a window disappears, inspect special workspaces. Preserve user-adjusted geometry rather than recentering on every toggle.

For native Wayland clipboard history, verify both clipboard operation and the running `wl-paste --watch` collector; installed `cliphist` alone collects nothing. X11 helpers may work in XWayland without working for native clients. Clipboard probes change user data: preserve and restore it, with approval when needed.

## i3 and Polybar

When a binding fails, separate the command executed through i3, the physical key/modifier events, i3 binding events and the deployed config link. A working shell command does not prove the shortcut fires. i3 command variables containing other variables may expand non-recursively; use a fully expanded command when indirect expansion leaves a literal variable. If a symbolic binding fails despite correct input, a verified physical keycode may be an appropriate `bindcode` fallback.

A long-running i3 helper can be configured but absent after reload; inspect its actual processes and pipeline. Polybar user services can have a restricted PATH, so a script with an `env` shebang may fail to find its interpreter. Home Manager may install a Polybar wrapper with an `include-file`; inspect the included config and logs too.

Polybar's XEmbed tray does not directly host StatusNotifier/AppIndicator items. If its tray is loaded but an app icon is absent, check for a bridge such as `snixembed` and restart the affected app after the bridge starts. A bridge can itself be incompatible; a separate launcher or another tray may be preferable to repeated restarts.

## cbox Hyprland: inspect the actual wiring

`nix/hosts/cbox.nix` imports both desktop profiles. Follow the profiles into
`nix/modules/hyprland-desktop.nix` and `nix/modules/i3-desktop.nix` before
deciding which packages and services are active. Removing an import changes the
next generation, not the running session; dormant repo files alone do not
prove a service is deployed.

The compositor and Waybar are system-owned on this non-NixOS host; Home
Manager owns user configuration and helper services. If a display-manager
session picks the Nix compositor instead of the system compositor, inspect the
session wrapper's PATH and the actual launched binary. Keep startup selection
separate from the PATH needed by child applications.

For a missing Nix command in a new session shell, inspect
`configs/hypr/hyprland.lua` and `configs/zsh/zshenv`. The session PATH includes
the default Nix profile bin and XDG data dirs include its share directory.
If `__ETC_PROFILE_NIX_SOURCED=1` survives a reduced PATH, the Nix profile
script can return without restoring its bin directory. Reproduce the inherited
environment without altering the live session:

```sh
env HOME="$HOME" USER="$USER" SHELL=/bin/zsh \
  PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/usr/local/bin:/usr/bin:/bin" \
  __ETC_PROFILE_NIX_SOURCED=1 zsh -c 'command -v nix && nix --version'
```

## Hyprland live-state diagnosis

1. Compare `configs/hypr/hyprland.lua` with
   `readlink -f ~/.config/hypr/hyprland.lua`; then inspect
   `hyprctl -j binds`, `hyprctl -j workspacerules` and
   `hyprctl -j workspaces`. Registered rules and the resulting layout are
   separate checks. New Lua binds or multiple workspace rules may not all
   register on reload.
2. In Lua-parser sessions, legacy `hyprctl dispatch` arguments may be parsed as
   Lua and fail. For an authorized temporary test use, for example,
   `hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'` or
   `hyprctl eval 'hl.bind("SUPER + K", hl.dsp.exec_cmd("/path/to/helper"))'`.
   Recheck binds; a live eval is not a persistent fix.
3. Waybar's built-in workspace click handling can send legacy dispatch syntax
   even when keyboard workspace bindings work. Inspect the configured Waybar
   modules and their helper commands before changing workspace rules; labels
   and icons are separate from Hyprland layout rules.
4. For a missing scratchpad or launcher, inspect `hyprctl -j clients` and
   `hyprctl -j monitors`; check special workspaces and `hyprctl -j layers` for
   the `rofi` namespace. Match the intended client by actual class, title or
   address before moving it. Ghostty may expose its default class even when a
   custom class was requested, so check the title too.

## Session services and clipboard

The Hyprland module defines user services for `hypr-blueman-applet`,
`hypr-lxqt-policykit-agent`, and text/image `hypr-cliphist-*` watchers; the
session starts these services. Check user-service status and journal in
addition to package installation. A manager window and system `polkitd` do not
prove a user authentication agent is present.

For Bluetooth, first inspect `rfkill list`, `bluetoothctl show`, scanning,
`bluetoothctl info <MAC>`, and the Bluetooth journal. If only one device fails
while others scan normally, investigate its pairing mode and RF conditions
before changing the adapter driver. A stale trusted-but-unpaired entry may need
removal and re-pairing; keep `bluetoothctl --agent KeyboardDisplay` interactive
through `pair`, `trust`, and `connect`, so its pairing agent remains alive.

For clipboard history inspect `hyprctl clients -j` for `xwayland`, then check
the `wl-paste --type text --watch cliphist store` and image watcher processes.
The picker uses `cliphist list`, `cliphist decode | wl-copy`, and Wayland
`wtype -M ctrl v -m ctrl` for optional paste. Preserve the user's clipboard
before a live round-trip probe. For symbols, the managed
`configs/rofi/symbols.tsv` is the picker input; confirm both the helper link
and its tools are deployed, not merely installed.

## i3 binding probes

1. Validate with `i3 -C -c configs/i3/config`, compare
   `readlink -f ~/.config/i3/config` with the intended source, and inspect
   `i3-msg -t get_config`.
2. Test the launcher through i3 itself:
   `i3-msg 'exec --no-startup-id /absolute/path/to/rofi -show combi -show-icons'`.
3. Observe the physical chord with `xinput test-xi2 --root`, key and modifier
   maps with `xmodmap -pke` and `xmodmap -pm`, and i3 binding events with
   `i3-msg -t subscribe -m '["binding"]'`. Synthetic key events are weaker
   evidence than the physical chord.
4. If the key symbol is correct but the binding still fails, verify the actual
   keycode before trying `bindcode`. `i3-msg -t get_bindings` is unavailable in
   some versions; an unknown message type does not prove bindings are absent.

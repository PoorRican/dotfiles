# Linux desktop install list

Working backlog for packages/services to install or enable while bringing up the Linux i3 desktop.

## Current discovery notes

- Bluetooth hardware is present as `hci0` and is not rfkill-blocked.
- `i3` and `i3bar` are present on the live system.
- `polybar`, `bluetoothctl`, `blueman-manager`, and `blueman-applet` are not currently in `PATH` on the live system.
- The dotfiles repo already has a Polybar config at `configs/polybar/config.ini` and enables Polybar from `nix/modules/i3-desktop.nix`.

## Install / enable backlog

### Bluetooth base stack

Needed so the existing Bluetooth adapter can actually be managed from userspace.

- Nix/Home Manager package candidates: `bluez`, `bluez-tools`, `blueman`
- Arch package candidates: `bluez`, `bluez-utils`, `blueman`
- System service needed on non-NixOS Arch-style installs: `bluetooth.service`
  - Example manual enablement: `sudo systemctl enable --now bluetooth.service`

Notes:

- Home Manager can put Bluetooth tools like `bluetoothctl`/Blueman on `PATH`, but the Bluetooth daemon/service is system-level.
- If this machine becomes NixOS later, the equivalent system setting is likely `hardware.bluetooth.enable = true;` plus any desktop/tray packages.

### Desktop background / wallpaper

Preferred first pass for X11+i3: **`feh`**.

Why:

- Very lightweight and common in i3 setups.
- Works well with a simple i3 autostart line.
- Can restore a background from a generated `~/.fehbg` script.
- Avoids a heavier GUI/background daemon unless we decide we want wallpaper browsing/rotation.

Backlog items:

- Install `feh`.
- Add a wallpaper directory, likely under the dotfiles repo or `~/Pictures/wallpapers`.
- Add an i3 startup line such as:
  - `exec_always --no-startup-id feh --bg-fill /path/to/wallpaper.jpg`
  - or `exec_always --no-startup-id ~/.fehbg` if using `feh` to save/restore the chosen wallpaper.

Alternatives:

- `nitrogen`: GUI wallpaper picker; nice if we want browse/select UX.
- `xwallpaper`: minimal modern X11 setter; good if we want no image viewer features.
- `hsetroot` / `xsetroot`: simple solid colors, gradients, or root pixmaps; less convenient for normal image wallpapers.
- `variety`: full wallpaper rotation/downloader daemon; probably too much for a first pass.

Live-system note: none of `feh`, `nitrogen`, `xwallpaper`, `hsetroot`, `xsetroot`, or `variety` are currently in `PATH`.

### Bluetooth widget for i3bar / Polybar

Preferred path for the current dotfiles setup: **Polybar + Blueman tray applet**.

Why:

- The existing Polybar config already has `tray-position = right`, so `blueman-applet` can provide a real clickable Bluetooth tray icon without writing a custom module first.
- Blueman gives pairing, connect/disconnect, trust, and device management UI.
- This is more practical than forcing everything through text status output.

Backlog items:

- Install `blueman`.
- Autostart `blueman-applet` from the i3 session or Home Manager once the Bluetooth daemon is enabled.
- Optionally add a tiny Polybar custom script module later for text status, e.g. ` on`, ` off`, or connected device count, backed by `bluetoothctl`.

Fallback if staying with plain `i3bar` instead of Polybar:

- Consider `i3status-rust` with a Bluetooth block.
- Do not install/configure `i3status-rust` by default if Polybar remains the chosen bar; it overlaps with Polybar's role.

## Open decisions

- Should Bluetooth daemon/service management live outside this repo as host setup, or should we add a NixOS/system-level host module when this machine becomes declarative?
- Should the first pass use only the Blueman tray icon, or also include a text Polybar Bluetooth status module?

## cbox Hyprland login and configuration reloads

`bin/cbox-switch-to-hyprland-os` installs the OS-owned LightDM session and
`/usr/local/bin/cbox-start-hyprland`. The launcher keeps the compositor on Arch's
`/usr/bin` PATH and sets `HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.lua"`.
Do not replace that environment setting with `--config`: Hyprland 0.56.2
canonicalizes the command-line path at startup, pinning the login-time Nix store
file instead of following Home Manager's updated symlink on reload.

Installing the corrected launcher does not change the running compositor.
**Log out and back in when convenient before relying on configuration reloads.**
In a session started with the old `--config` launcher, `hyprctl reload` reloads
the old generation and can undo live theme or keybind changes.

After logging in through the corrected launcher, switch desktop themes by setting
`my.desktop.theme = "solid-gold"` or `"sourcerer"` in the cbox Home Manager config:

```sh
home-manager switch --flake .#cbox &&
  hyprctl reload &&
  systemctl --user restart hypr-waybar &&
  pkill -USR2 -x ghostty
```

Waybar needs a restart to read its new palette even when its service definition
has not changed. Ghostty's signal reloads configuration without closing windows.
Dunst's generated configuration has a Home Manager service restart trigger;
hyprlock reads the selected palette the next time it starts.

The OS setup script also manages packages and LightDM configuration. Never pass
`--restart` during a live-update workflow: it ends the graphical session.

## cbox window controls and fullscreen Waybar

`Super+w` opens a window-control submap. A passive, accent-coloured Hyprland
notification stays visible throughout the sequence without taking keyboard focus.

| Key after `Super+w` | Action |
| --- | --- |
| `h` / `j` / `k` / `l` | Focus left / down / up / right |
| `m`, then `h` / `j` / `k` / `l` | Move the focused window |
| `r`, then `h` / `j` / `k` / `l` | Resize by 40 px per step |
| `f` | Toggle fullscreen |
| `t` | Toggle floating |
| `y` | Cycle the visible workspace through dwindle, master, and scrolling |
| `b` | Toggle that workspace's border, restoring its prior size |
| `g` | Enter that workspace's gap controls |
| `Shift+/` (`?`) | Show the full passive modal help |
| `/` | Open the searchable keybinding list |
| `s` | Run `sysadmin --toggle` |
| `Escape` or an unmapped key | Exit and clear the passive help |

Move, resize, and gap controls remain active for repeated adjustments. In gap
controls, `i` selects inner gaps, `o` selects outer gaps, `-` / `=` changes the
selected gaps by 1 px, and `0` toggles them off/on. Values clamp at zero; toggling
restores the last nonzero values. Adjusting disabled gaps edits their saved values
without turning them back on.

Layout, border, and gap overrides are workspace-local and temporary: reloading
the configuration or starting a new session resets them. With a scratchpad open,
these controls target the special workspace rather than its underlying desktop.
Existing direct `Super+f` and `Super+/` fullscreen bindings, scrolling/group
controls, and scratchpad bindings remain separate from the modal controls.

The `hypr-waybar-visibility` user service hides Waybar on `HDMI-A-1` only for true
fullscreen, not maximize-only mode. Moving the pointer to the top edge within
the centred bar's width reveals it above the fullscreen window. It stays visible
while the pointer is inside the bar, then hides when the pointer leaves.
Leaving fullscreen or stopping the watcher shows the bar again.

The watcher signals only `hypr-waybar.service`'s current `MainPID`; unrelated
Waybar instances are not signalled. Waybar's `SIGUSR1` means hide and `SIGUSR2`
means show, **not configuration reload**. Restart its service after JSONC edits:

```sh
systemctl --user restart hypr-waybar.service
```

The modal implementation is `configs/hypr/window-controls.lua`; searchable help
is `bin/hypr-keybindings-menu`, and the visibility watcher is
`bin/hypr-waybar-visibility`. The modal helper installs its bindings once per Lua
state and updates a shared action table on repeated setup. Do not remove and
reinstall live Lua bind handles on Hyprland 0.56.2; exercise structural modal
changes in a separate compositor before previewing them on the main desktop.


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

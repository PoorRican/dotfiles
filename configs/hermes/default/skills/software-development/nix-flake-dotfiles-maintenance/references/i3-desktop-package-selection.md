# i3/X11 desktop package selection for cbox-style Home Manager profiles

Use this as a compact research note when adding practical i3/i3-gaps quality-of-life tools to a Nix/Home Manager host profile.

## Bar / toolbar

Recommended default: `polybar`

Why:
- Strong fit for X11+i3/i3-gaps as a replacement for default i3bar.
- Popular in i3/BSPWM setups on `r/unixporn`, `r/linuxporn`, and `r/i3wm` searches.
- Official positioning: fast, easy-to-use, customizable status bars with built-in modules for common services.
- More of a real toolbar replacement than `i3status`, `i3blocks`, or `i3status-rust`, which are primarily status providers for i3bar/i3bar-protocol bars.

Fallback only: `i3status-rust`
- Use only if the user chooses to keep `i3bar`/i3bar-protocol instead of Polybar.
- Do not add it alongside Polybar by default; it adds conceptual overlap and undermines a minimal, usable setup.

Avoid as first pass for a practical user:
- `eww`: powerful but more custom/rice-heavy.
- `waybar`: popular, but mainly Wayland/Sway/Hyprland-oriented rather than X11 i3.
- `lemonbar`: too DIY for a returning Linux user.

## Launcher / Spotlight-like selector

Recommended default: `rofi`

Why:
- Strong i3 community fit; frequently appears alongside Polybar in i3 setups.
- Official positioning: window switcher, application launcher, and dmenu replacement.
- Practical keybinding: `rofi -show drun -show-icons`.
- Can later expand to window switching, SSH, scripts, and custom modes without changing launcher.

Alternatives:
- `dmenu`: very common and lightweight, but more primitive than a Spotlight-like app selector.
- `ulauncher` / `albert`: closer to macOS Spotlight UX but less i3-native and heavier; consider only if the user explicitly wants plugin-rich desktop search over WM-native simplicity.

## Desktop background / wallpaper

Recommended first pass for X11+i3: `feh`.

Why:
- Lightweight and common in i3 setups.
- Works well with an i3 autostart line such as `exec_always --no-startup-id feh --bg-fill /path/to/wallpaper.jpg`.
- Can save/restore the selected wallpaper through `~/.fehbg` when using `feh` interactively.
- Avoids a heavier background daemon until the user asks for wallpaper browsing, randomization, or downloads.

Alternatives:
- `nitrogen`: GUI wallpaper picker; useful if the user wants browse/select UX.
- `xwallpaper`: minimal modern X11 wallpaper setter; good when no image viewer features are wanted.
- `hsetroot` / `xsetroot`: solid colors, gradients, or root pixmaps; less convenient for normal image wallpapers.
- `variety`: wallpaper rotation/downloader daemon; avoid as a first pass unless explicitly requested.

## Bluetooth widget / tray pattern

Recommended first pass when the host has Bluetooth hardware and the profile already uses Polybar: install the Bluetooth userspace stack and use `blueman-applet` in Polybar's tray.

Why:
- Polybar can host tray applets via `tray-position = right`, giving a real clickable Bluetooth UI without a custom module.
- Blueman covers pairing, trust, connect/disconnect, and device management better than a text-only status block.
- Keep a custom `bluetoothctl`-backed Polybar module as a later optional enhancement for text status such as ` on/off` or connected device count.

Package/service split:
- Home Manager/package layer can add tools such as `blueman`, `bluez`, and `bluez-tools`/`bluez-utils` equivalents.
- The Bluetooth daemon is system-level on non-NixOS hosts; document or enable `bluetooth.service` separately unless the host is NixOS.
- On NixOS, prefer system configuration such as `hardware.bluetooth.enable = true;` plus desktop packages.

Avoid adding `i3status-rust` solely for Bluetooth if Polybar is already the chosen bar; it creates bar/status-provider overlap.

## i3 vs i3-gaps package naming

Modern upstream i3 includes gaps support in many distros. On Arch, the installed package may be `i3-wm` while package metadata says `Provides: i3-gaps` / `Replaces: i3-gaps`; treat this as regular upstream i3 with gaps support, not a separate legacy fork. If uncertain, verify with a syntax check such as:

```bash
tmp=$(mktemp)
printf 'font pango:monospace 8\ngaps inner 10\ngaps outer 5\n' > "$tmp"
i3 -C -c "$tmp"
rm -f "$tmp"
```

## Nix/Home Manager package set

Minimal practical committed set when choosing Polybar as the bar:

```nix
programs.rofi.enable = true;

home.packages = with pkgs; [
  polybar
  font-awesome
  nerd-fonts.jetbrains-mono
];
```

Do **not** install `i3status-rust` alongside Polybar by default. It overlaps conceptually: `i3status-rust` is a status provider for i3bar/i3bar-protocol bars, while Polybar is the replacement bar. Keep `i3status-rust` only if the user explicitly wants an i3bar fallback or chooses not to use Polybar.

Home Manager supports declarative configuration for these tools:
- `services.polybar.{enable,package,settings,config,extraConfig,script}`
- `programs.rofi.{enable,package,theme,extraConfig,modes,plugins,...}`
- `programs.i3status-rust.{enable,package,bars}` for the fallback/i3bar path

Polybar feature pitfall:
- Nixpkgs `pkgs.polybar` defaults may not include optional modules. Check `polybar --version`; missing workspaces show up as `Features: ... -i3 ...` and logs say `No built-in support for 'internal/i3'`.
- If staying fully Nix-managed, use an override such as `pkgs.polybar.override { i3Support = true; pulseSupport = true; }` and set both `services.polybar.package` and any `home.packages` reference to that override.
- If the user installed an Arch/AUR `/usr/bin/polybar` with `+i3`, make sure Home Manager/i3 startup is actually launching `/usr/bin/polybar`, not a Nix `pkgs.polybar` in `~/.local/state/nix/profiles/...`.

`font-awesome` and a Nerd Font are useful because many Polybar/Rofi themes expect icon glyphs.

## Workflow note

If creating a new host profile and importing it from a flake-managed host file, stage the new profile file before `nix eval`; Nix flakes do not see untracked imported files.

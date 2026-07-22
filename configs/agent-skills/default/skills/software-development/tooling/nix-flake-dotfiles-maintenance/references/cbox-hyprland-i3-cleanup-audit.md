# cbox Hyprland vs stale i3 cleanup audit

Use this reference when auditing whether cbox is really using the Hyprland/Wayland path or still deploying i3/X11 state.

## Key distinction

Separate three categories before recommending deletion:

1. **Active Home Manager imports** — these affect the current cbox generation and package/service surface.
2. **Applied symlinks / live user services** — these show what the current generation has actually installed under `~/.config`, `~/.local/bin`, or systemd user units.
3. **Dormant repo files** — old `configs/i3`, `configs/polybar`, or `bin/i3-*` files can remain in the repo harmlessly if no active profile imports them.

For this repo, the critical stale state is not the mere presence of `configs/i3/` or `bin/i3-*`; it is `nix/hosts/cbox.nix` importing `../profiles/i3-desktop.nix` alongside `../profiles/hyprland-desktop.nix`.

## What the i3 profile deploys

`nix/modules/i3-desktop.nix` deploys i3/X11-specific packages and files, including:

- packages: `i3`, `i3lock-color`, `betterlockscreen`, `xss-lock`, `clipmenu`, `snixembed`, `picom`, `xkill`, `xclip`, `xdotool`, `xinput`, `feh`, and Polybar with i3 support
- config: `xdg.configFile."i3/config"`, Polybar config via `services.polybar.config`
- scripts: `~/.local/bin/i3-*` and `~/.local/bin/polybar-bluetooth`
- service: `services.polybar.enable = true`

Overlap packages such as `rofi`, `dunst`, `libnotify`, `pavucontrol`, `networkmanagerapplet`, `bluez`, `blueman`, `jq`, and fonts are not stale by themselves because Hyprland also uses them.

## Audit commands

Repo/import state:

```bash
sed -n '1,80p' nix/hosts/cbox.nix
sed -n '1,140p' nix/modules/i3-desktop.nix
sed -n '1,140p' nix/modules/hyprland-desktop.nix
```

Evaluation state:

```bash
/nix/var/nix/profiles/default/bin/nix eval --no-write-lock-file --json '.#homeConfigurations.cbox.config.services.polybar.enable'
/nix/var/nix/profiles/default/bin/nix eval --no-write-lock-file --json '.#homeConfigurations.cbox.config.xdg.configFile."i3/config".target'
/nix/var/nix/profiles/default/bin/nix eval --no-write-lock-file --json '.#homeConfigurations.cbox.config.xdg.configFile."hypr/hyprland.lua".target'
```

Applied/runtime state:

```bash
printf 'XDG_CURRENT_DESKTOP=%s\nXDG_SESSION_TYPE=%s\n' "$XDG_CURRENT_DESKTOP" "$XDG_SESSION_TYPE"
pgrep -a 'i3|polybar|picom|xss-lock|snixembed|clipmenud|dunst|waybar|hyprland' || true
systemctl --user --no-pager --plain status polybar.service 2>&1 | sed -n '1,80p' || true

for p in \
  "$HOME/.config/i3/config" \
  "$HOME/.config/polybar/config.ini" \
  "$HOME/.local/bin/i3-vivaldi" \
  "$HOME/.local/bin/i3-lock" \
  "$HOME/.local/bin/polybar-bluetooth" \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/waybar/config.jsonc"; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf '%s -> ' "$p"; readlink -f "$p" || true
  else
    printf '%s MISSING\n' "$p"
  fi
done
```

## Cleanup recommendation pattern

If cbox is now intentionally Hyprland-only, make the smallest declarative cleanup:

1. Remove `../profiles/i3-desktop.nix` from `nix/hosts/cbox.nix`.
2. Do **not** delete old i3/polybar configs or helper scripts unless the user explicitly asks; keeping them as dormant repo artifacts preserves rollback/history.
3. Ensure the Hyprland profile provides Wayland replacements before removing i3:
   - Waybar instead of Polybar
   - Dunst as notification daemon
   - `wl-clipboard` + `cliphist` instead of `xclip` + `clipmenu`
   - `wtype` instead of `xdotool`
   - later, `hyprlock`/`swaylock` instead of `i3lock`/`xss-lock`
4. If new Hyprland helper scripts are added and referenced by Nix, `git add` those new scripts before `nix eval`; flakes do not see untracked imported paths.
5. Verify cbox evaluation, then report separately: repo state, evaluation state, applied generation, and runtime process state.

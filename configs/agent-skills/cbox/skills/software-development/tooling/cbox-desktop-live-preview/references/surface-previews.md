# Previewing each surface live

Scope: loading an uncommitted change into the running session without restarting it. Verify the technique against the installed program versions; none of the commands here were run against a locked or half-configured session.

## Hyprland option blocks

1. Verify that every option name exists before writing it: `hyprctl getoption <section:key>`. A missing option is reported as an error rather than applied.
2. Apply the edited Lua block with `hyprctl eval`, after stripping leading and whole-line `--` comments:
   ```sh
   code="$(sed -n 'START,ENDp' configs/hypr/hyprland.lua | grep -v '^[[:space:]]*--')"
   hyprctl eval "$code"
   ```
   A string that starts with `--` is parsed by `hyprctl` as a flag: it prints usage and exits 1.
3. Locals defined earlier in `hyprland.lua` (`palette`, `home`, the Home Manager bin paths) are not visible to an extracted chunk; define them at the top of the chunk, for example `local palette = dofile(os.getenv("HOME") .. "/.config/hypr/desktop-theme.lua")`.
4. Confirm with `hyprctl getoption ...` and require `hyprctl configerrors` to be empty.
5. Settings applied with `eval` last until the next reload. `hyprctl reload` returns Hyprland to the deployed configuration and re-starts the desktop services, so do it only when ending the preview (see [build-commit-and-deploy.md](build-commit-and-deploy.md)).

## Waybar

The managed bar is `hypr-waybar.service`; the fullscreen edge-reveal helper `hypr-waybar-visibility.service` signals that unit's `MainPID`. A transient preview unit is not that process, so judge fullscreen hide/reveal behavior only after deployment.

```sh
P=$(mktemp -d "${SCRATCH_DIR:-$PWD}/waybar-preview.XXXXXX")
cp ~/.config/waybar/theme.css "$P/"        # deployed, generated palette
cp configs/waybar/style.css "$P/"
systemctl --user stop hypr-waybar.service
systemd-run --user --unit=cbox-waybar-preview --collect /usr/bin/waybar \
  -c "$PWD/configs/waybar/config.jsonc" -s "$P/style.css"
journalctl --user -u cbox-waybar-preview --since -1min --no-pager -o cat
```

- `style.css` imports `theme.css` relative to itself, so the generated palette must sit beside the previewed stylesheet; alternatively point `-c` and `-s` at `$gen/home-files/.config/waybar/` in a built generation. Re-copy `style.css` into the scratch directory after each edit, because the watcher follows the scratch copy.
- With `reload_style_on_change` enabled, CSS changes in the watched file reload automatically. JSONC changes need a restart of the preview unit or `systemctl --user kill -s SIGUSR2 cbox-waybar-preview`.
- Gate a new module with a short throwaway run (`waybar -c <tmp config> -s /dev/null -l info` for about three seconds) and grep the output or the unit journal for `Unknown module|Disabling`.
- Stop the preview unit before any `hyprctl reload` and when the preview ends.

## rofi

Background launches from an agent shell never map. Use a transient unit, wait briefly, then capture:

```sh
systemd-run --user --unit=rofi-preview --collect --working-directory=configs/rofi \
  rofi -show drun -config ./config.rasi -theme ./themes/<theme>.rasi
sleep 2.5; grim ...; systemctl --user stop rofi-preview
```

`config.rasi` selects the generated `desktop` theme; preview a repo theme file explicitly with `-theme` or use the built generation's `themes/desktop.rasi`.

## dunst

Build the Home Manager generation, then load its rendered config and send samples:

```sh
dunstctl reload "$(readlink -f "$gen/home-files/.config/dunst/dunstrc")"
notify-send -u low "preview" "low"; notify-send "preview" "normal"; notify-send -u critical "preview" "critical"
dunstctl close-all    # afterwards
```

## Ghostty

Copy the config and theme into `~/.config/ghostty/` (back up any unmanaged original first; if the target is a Home Manager link, record what you replaced), run `ghostty +validate-config`, then `pkill -USR2 -x ghostty` reloads every window. Remove the preview copies and restore backups before the Home Manager switch, otherwise activation reports file collisions.

## hyprlock

Do not trigger it yourself. Give the user the command: `hyprlock -c ~/dotfiles/configs/hypr/hyprlock.conf`. Lock/idle wiring changes follow [hyprlock-and-hypridle-deployment.md](hyprlock-and-hypridle-deployment.md).

## Screenshots

- Capture the bar strip with `grim -g "x,y wxh"`; read the bar's geometry from `hyprctl layers -j` instead of hard-coding it (the bar size changes with the design).
- Capture the full screen at half scale with `grim -s 0.5`.
- Show the images to the user and ask for feedback before moving to the next surface.

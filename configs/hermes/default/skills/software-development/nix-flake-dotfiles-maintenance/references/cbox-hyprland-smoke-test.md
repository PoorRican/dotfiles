# cbox Hyprland Smoke-Test Before Dotfiles

Use this note when the user is exploring a cbox desktop migration from i3/X11 to Hyprland/Wayland and wants practical manual validation before declarative Home Manager work.

## Workflow correction from session

Do **not** default to designing the whole Home Manager/dotfiles module first. For this class of desktop migration, the user prefers a fast local smoke test first:

1. Install the compositor and core tools through Arch/yay/pacman when requested.
   - Example: `yay -S --needed hyprland waybar xdg-desktop-portal-hyprland`
   - If the package is in official repos, `yay` delegating to `pacman` is fine.
2. Launch Hyprland from a TTY to prove it can start on the hardware:
   - `dbus-run-session Hyprland`
3. Configure local files under `~/.config/` for iteration:
   - `~/.config/hypr/hyprland.lua` or `hyprland.conf`
   - `~/.config/waybar/config.jsonc`
   - `~/.config/waybar/style.css`
4. Only after the setup feels usable should we translate it into a `cbox-hyprland` dotfiles/Home Manager profile.

## Useful local config moves

Hyprland Lua config can be verified without starting a session:

```bash
Hyprland --config ~/.config/hypr/hyprland.lua --verify-config
```

Waybar cannot fully run from X11/i3; validate pieces instead:

```bash
python -m json.tool <(python - <<'PY'
# Or use a tiny JSONC comment-stripper if config contains comments.
PY
)
```

Better practical validation is from inside Hyprland:

```bash
pkill waybar
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &
```

For local TTY autostart with zsh, use a guarded `~/.zprofile` block rather than display-manager work during the smoke test:

```zsh
_current_tty="$(tty 2>/dev/null || true)"
if [[ -z "${HYPRLAND_AUTO_START_DISABLE:-}" ]] &&
   [[ -z "${DISPLAY:-}" ]] &&
   [[ -z "${WAYLAND_DISPLAY:-}" ]] &&
   [[ -z "${SSH_CONNECTION:-}" ]] &&
   [[ "${XDG_VTNR:-}" = "1" || "$_current_tty" = "/dev/tty1" ]] &&
   [[ -x /usr/bin/Hyprland ]]; then
  export XDG_SESSION_TYPE=wayland
  export XDG_CURRENT_DESKTOP=Hyprland
  export XDG_SESSION_DESKTOP=Hyprland
  export BROWSER=vivaldi-stable
  exec dbus-run-session Hyprland
fi
unset _current_tty
```

Escape hatch:

```bash
HYPRLAND_AUTO_START_DISABLE=1 zsh -l
```

## cbox Hyprland preference defaults

When making the first local config, preserve the user's early preferences:

- Use `ghostty` as terminal.
- Use `vivaldi-stable` as browser and set `BROWSER=vivaldi-stable`.
- Prefer `rofi -show drun -show-icons` over `hyprlauncher`.
- Bind `Super+Return` to terminal.
- Bind `Super+Space` to launcher.
- Bind `Super+B` to Vivaldi.
- Bind `Super+Shift+C` and/or `Super+Shift+Q` to close active window.
- Enable natural/inverted scrolling in Hyprland input config.
- Build a richer Waybar theme rather than accepting the stock Waybar look.

## Real switch pattern after smoke test

Once the local Hyprland session is validated and the user is ready for the real switch on Arch/cbox:

1. Treat startup as OS-owned, not Home Manager-owned.
   - If LightDM is already enabled, keep it and configure `/etc/lightdm/lightdm.conf.d/50-cbox-hyprland.conf` rather than relying on `~/.zprofile` autostart.
   - Ensure `/usr/share/wayland-sessions/hyprland.desktop` exists from the Arch `hyprland` package.
   - Do not enable LightDM autologin unless the user explicitly wants it; leaving out `autologin-user`, `autologin-user-timeout`, and `autologin-session` presents the normal greeter/login screen while still defaulting the selected session with `user-session=cbox-hyprland`.
   - For passwordless LightDM autologin, ensure group `autologin` exists and the user is a member; Arch's `/etc/pam.d/lightdm-autologin` checks `user ingroup autologin`.
2. Home Manager should then own user config and helper apps only:
   - link `~/.config/hypr/hyprland.lua`
   - link `~/.config/waybar/config.jsonc` and `style.css`
   - provide rofi/nm-applet/pavucontrol/fonts in `home.packages`
   - do **not** install the compositor itself (`hyprland`) through Home Manager on this non-NixOS Arch host; keep Hyprland and Waybar OS-owned through pacman so Arch's graphics/session wrapper sees the matching system libraries
   - replace the smoke-test `~/.zprofile` with a neutral profile so tty login no longer starts the compositor
3. Keep compositor startup independent of display-manager shell startup:
   - LightDM's session wrapper may run the user's login shell/profile before execing the selected `.desktop` session; if Home Manager's Nix profile comes first in `PATH`, Arch's `/usr/bin/start-hyprland` can pick a Nix-built `Hyprland` and fail with `Nix environment check failed: Hyprland was installed using Nix, but you're not on NixOS. This requires nixGL`.
   - Use a small OS-owned session wrapper such as `/usr/local/bin/cbox-start-hyprland` that sets `PATH=/usr/local/bin:/usr/bin:/bin` and then runs `/usr/bin/start-hyprland -- --config "$HOME/.config/hypr/hyprland.lua"`; point a custom `/usr/share/wayland-sessions/cbox-hyprland.desktop` at that wrapper and set LightDM `user-session`/`autologin-session` to `cbox-hyprland`.
   - set `PATH` inside Hyprland config to include the Home Manager profile bin for child apps after the compositor is already running
   - use absolute paths for key commands when possible, e.g. `/usr/bin/ghostty`, `/usr/bin/vivaldi-stable`, `/usr/bin/waybar`, and `$hmBin/rofi`
4. Verify in layers:
   - `Hyprland --config <repo>/configs/hypr/hyprland.lua --verify-config`
   - JSONC/CSS parse checks for Waybar
   - stage new files before `nix eval` because flakes ignore untracked imports
   - `nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file`
   - `home-manager switch --flake .#cbox`
   - OS-level LightDM changes require sudo and may need a reboot/restart; do not claim they are active until `/etc/lightdm/lightdm.conf.d/50-cbox-hyprland.conf` exists and LightDM has restarted.

## Pitfalls

- Do not assume Hyprland defaults are a complete desktop. They are enough to launch and test basics, but the defaults may depend on helper apps such as `kitty`, `dolphin`, or `hyprlauncher`.
- Do not over-index on Home Manager before the user has validated the compositor experience. The correct first deliverable is a working local session, not a polished declarative module.
- Waybar style is visual; CLI validation only proves parseability. Ask for live feedback after the user sees it inside Hyprland.
- Do not leave the smoke-test `~/.zprofile` compositor autostart in place after switching to an OS-level display-manager session; it becomes a confusing second startup path.
- For Hyprland Lua scratchpad/reference windows that must stay visible while unfocused, prefer a pinned floating client over a special-workspace overlay. Focusing a normal workspace window can hide the active special workspace, making an empty or unfocused-looking overlay confusing. A robust pattern is: show = move the client from `special:<name>` to the current workspace, `pin`, `center`, and `bring_to_top`; unfocus = focus a non-scratchpad window on the active workspace while leaving the pinned client visible; hide = unpin and move the client back to `special:<name>`. If Ghostty `--class` is unreliable in an already-running GTK instance, match/detect by a forced title prefix as a fallback.
- For sticky/floating scratchpads on scrolling-layout workspaces, do not use Hyprland focus history alone to return focus after toggling away: it can jump to the first/oldest column. Persist the previously-focused non-scratchpad window address plus workspace in `$XDG_RUNTIME_DIR` before showing the scratchpad, validate that client still exists, and focus it on toggle-away/hide; only then fall back to recent focus history.
- Hyprland 0.55.3 Lua config can accept `hl.bind("SUPER + grave", ...)` via `hyprctl eval` while silently dropping the same grave/backtick bind when registered inline during config load/reload. For cbox backtick hotkeys, install/refresh the bind with a small runtime helper or watcher that calls `hyprctl eval`, and verify with `hyprctl -j binds | jq '.[] | select(.key == "grave")'`.
- On cbox with Hyprland 0.55.3, monitor disconnect/DPMS wake can crash in the upstream `enterUnsafeState -> CHeadlessOutput::commit -> getViewsForWorkspace` path. `start-hyprland` then restarts Hyprland with `--safe-mode`, so user config/autostart, including Waybar, is skipped. Confirm via `pgrep -a Hyprland`, `~/.cache/cbox-hyprland-session.log`, and `~/.cache/hyprland/hyprlandCrashReport*.txt`. The real fix is a Hyprland build containing upstream PR #14547 (`state/monitor: refactor monitor state, init fallback state`, merged after 0.55.3), e.g. `hyprland-git` or a later stable release. If sudo is unavailable in the agent shell, start Waybar live separately and give the user exact `yay -S hyprland-git` / restart instructions. Do not install `hyprland-git` with `--noconfirm`: pacman conflict questions such as `hyprutils-git ... and hyprutils ... are in conflict. Remove hyprutils? [y/N]` default to **No**, so `--noconfirm` makes the transaction fail. Run `yay -S --needed hyprland-git --answerclean None --answerdiff None --answeredit None` interactively and answer `y` to replacing/removing the stable `hypr*` packages.

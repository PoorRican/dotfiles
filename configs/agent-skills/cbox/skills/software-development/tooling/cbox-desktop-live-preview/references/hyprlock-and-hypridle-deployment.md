# hyprlock and hypridle on cbox

Scope: the lock screen, idle lock and display power-off on the cbox Hyprland desktop (LightDM autologin, Home Manager-managed): repository wiring, the failure modes already seen here, and the deploy and verification stages.

## Wiring in the repository

- `configs/hypr/hyprlock.conf`, `configs/hypr/hypridle.conf`: tracked, linked into `~/.config/hypr/` by `nix/modules/hyprland-desktop.nix`.
- `bin/hypr-idle`: wrapper that resolves `XDG_RUNTIME_DIR` from the Hyprland process's `/proc/<pid>/environ` and `WAYLAND_DISPLAY` from the `wayland-N` socket (the Hyprland server does not export `WAYLAND_DISPLAY`; only its clients get it), then `exec`s `/usr/bin/hypridle`. It refuses to start without a Hyprland process or IPC socket directory.
- `hypr-idle.service`: Home Manager user service (`Restart=always`), listed in `desktopServices` in `configs/hypr/hyprland.lua` so it is re-asserted on start and reload.
- `bin/cbox-setup-hyprlock-pam`: idempotent root installer of `/etc/pam.d/hyprlock`.
- `bin/cbox-deploy-hyprlock`: one-shot stage runner (targeted pacman install, Home Manager switch, PAM file, start `hypr-idle`, verify) with the escape hatch printed.
- `configs/hypr/hyprland.lua` runs `/usr/bin/hyprlock` at `hyprland.start` (not on `config.reloaded`, so routine reloads never lock the desktop) and binds Super+L to it.

## Failure modes already seen

The host-neutral mechanics (PAM fallback, Nix-store EGL abort, the `dpms` crash and safe mode, agent idle inhibitors, the `hyprctl locked -j` oracle) are in the `workstation-and-agent-tooling` skill, `references/hyprland-lock-and-idle.md`. On cbox they are encoded as follows; check them before changing the wiring or debugging "the lock does not work":

1. **PAM**: `bin/cbox-setup-hyprlock-pam` installs `/etc/pam.d/hyprlock` with `pam_unix` for `auth` and `account` only. Without it every non-root password was rejected (2026-08); `pam_faillock` stays out because failed unlocks must never count toward account lockout.
2. **Binary**: the lock command is `/usr/bin/hyprlock` in `hyprland.lua` and `hypridle.conf`; never point it at a Nix-store hyprlock (it aborted on EGL on this host).
3. **DPMS**: never bind `dispatch dpms` to a key (it crashed Hyprland 0.55.3 and earlier into safe mode, which ignores the full `hyprland.lua`). DPMS is driven by hypridle listeners with `hl.dsp.dpms({action = "off"})`/`"on"`; detect safe mode with `ps -eo args | grep -E 'Hyprland.*--safe-mode'`.
4. **Inhibitors**: `hypridle.conf` sets `general { ignore_systemd_inhibit = true }` because agents hold logind `idle` inhibitors while working; without it the timers fire, log `Ignoring from onIdled(), inhibit locks: 1` and skip both actions.
5. **Config syntax**: hypridle takes `general` and `listener` blocks of `key = value` entries; a top-level `on-timeout`/`exec-once` form registers zero rules ("found 0 rules") and the daemon idles forever.

Use `hyprctl locked -j`, not appearance or process existence, as the lock oracle; a physical monitor-off can leave only the `FALLBACK` output without implying a locker failure.

## Deploy and verify

1. `git add` new `bin/` and `configs/` files before building; Nix fails with "Path ... is not tracked by Git" otherwise. Do not put zero-width or non-ASCII artifacts into `.nix` attribute keys.
2. Targeted package install only when needed (hyprland, hyprlock, hypridle); prefer it to a full upgrade on a live workstation unless asked.
3. `home-manager switch --flake .#cbox`, then `~/.local/bin/cbox-setup-hyprlock-pam` (needs root), then `systemctl --user daemon-reload && systemctl --user restart hypr-idle.service`. Changing the symlinked config alone does not prove the daemon loaded its new settings; confirm the active PID and start time.
4. Restart the Hyprland session through LightDM (`hyprshutdown`) so it leaves safe mode and loads the full config. Because the session locks at start, expect the lock screen on the fresh session.
5. Arm an escape path before testing: from a TTY or SSH, `pkill -u $(id -u) hyprlock` kills a wedged lock; `chvt` to the session or restart LightDM if Hyprland is in safe mode; a reboot restores the autologin desktop as the last resort.
6. Verify: Super+L brings up the lock and the right password unlocks it; the idle lock fires at 10 minutes and the display goes off at 15 with input waking it; `systemctl --user status hypr-idle` is active; `bash -n bin/cbox-setup-hyprlock-pam bin/hypr-idle` and `luac -p configs/hypr/hyprland.lua` pass; `home-manager build --flake .#cbox` succeeds; `hyprland --version` is newer than 0.55.3 and no `--safe-mode` process runs.

## Verifying an inhibitor regression without touching production timers

Run a bounded second hypridle with an isolated scratch config, a short listener that only touches a marker file, and a real `systemd-inhibit --what=idle --mode=block` wrapper. In the probe only, set `ignore_dbus_inhibit = true` (to avoid taking the live ScreenSaver bus name), `ignore_wayland_inhibit = true` (to isolate the systemd variable) and `inhibit_sleep = 0`; copy the production `ignore_systemd_inhibit` value. Show the marker is skipped with the old false value and created with true, and require an actual Idled event or call the result inconclusive. Bound and clean up the probe, and never alter production timeouts or execute the real lock, DPMS or suspend commands just to validate parsing.

## Pitfalls

- hypridle's listener commands inherit its environment; the wrapper must export `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR` or hyprlock and hyprctl cannot find the compositor.
- Never `require()` an abandoned experiment directory (the old repo-root `hyprland/` Lua experiment used APIs that do not exist); it was moved out of the repository.

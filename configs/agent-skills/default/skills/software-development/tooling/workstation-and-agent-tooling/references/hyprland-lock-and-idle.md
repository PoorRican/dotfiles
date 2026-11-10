# Hyprland lock and idle

Scope: host-neutral pitfalls when deploying hyprlock and hypridle on a Hyprland desktop managed through dotfiles. Version numbers are dated observations (Hyprland 0.55-0.56, hyprlock 0.9.6, August 2026). Host-specific wiring and activation stages belong with the host's own overlay and repo comments.

## Authentication

- Without `/etc/pam.d/hyprlock`, hyprlock falls back to `/etc/pam.d/su` (`pam_rootok`), which accepts only root, so every ordinary password is rejected. Install a `pam_unix`-only stack with `auth` and `account` lines and no `pam_faillock` or `pam_deny`: failed unlocks must not count toward an account lockout. The PAM file is root-owned and installed with a sudo step. (src: hyprland-lock-idle; 2026-08)

## Binaries and DPMS

- A Nix-store hyprlock can abort in its constructor on a non-NixOS desktop (`EGL_EXT_platform_base not supported`, SIGABRT) because its libEGL cannot open the Wayland display. Keep the distribution's hyprlock on the lock path; let the Nix module manage only configuration files and the hypridle service. (src: hyprland-lock-idle; 2026-08)
- Hyprland up to 0.55.3 segfaults on a hand-bound `dispatch dpms` (monitor-disconnect path), and the session respawns in safe mode, which runs a minimal generated configuration and ignores your full one, so custom binds stop working. Drive DPMS through hypridle listeners, never a key bind; fixed upstream in 0.55.4. Detect safe mode with `ps -eo args | grep -E 'Hyprland.*--safe-mode'`. On 0.56 the dispatcher takes Lua expressions (`hyprctl dispatch 'hl.dsp.dpms({action = "off"})'`); legacy `dpms off` does not parse. (src: hyprland-lock-idle; 2026-08)
- Physical monitor-off can disconnect HDMI and leave only the compositor's `FALLBACK` output. That alone does not prove a locker failure: use `hyprctl locked -j`, not appearance or process existence, as the lock oracle. (src: hyprland-lock-idle; 2026-08)

## Idle behavior

- Agent logind idle inhibitors suppress hypridle timers: with the default `ignore_systemd_inhibit = false` the 600 s/900 s timers fire but log `Ignoring from onIdled(), inhibit locks: 1` and skip both actions. Inspect `systemd-inhibit --list` and the idle service journal before blaming monitor power state. Set `general { ignore_systemd_inhibit = true }` when agent jobs must continue while the desktop locks; it still honors screensaver D-Bus and Wayland inhibitors, does not suspend the machine, and does not remove the original logind inhibitor. Do not replace it with listener-level `ignore_inhibit = true` without an explicit policy decision. (src: hyprland-lock-idle; 2026-08)
- Restart the idle daemon after Home Manager activation: a changed symlinked config alone does not prove the running daemon loaded it. Check the active PID and start time. (src: hyprland-lock-idle; 2026-08)
- hypridle and hyprlock need `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` from the Hyprland session; the Hyprland server process does not carry `WAYLAND_DISPLAY` (only its clients do). A wrapper should export `XDG_RUNTIME_DIR` from the compositor process's environment, resolve the `wayland-N` socket in that directory, and refuse to start without a compositor. (src: hyprland-lock-idle; 2026-08)
- Flake builds evaluate the Git index: `git add` new wrapper and config files before building, or evaluation fails with "not tracked by Git". (src: hyprland-lock-idle; 2026-08)

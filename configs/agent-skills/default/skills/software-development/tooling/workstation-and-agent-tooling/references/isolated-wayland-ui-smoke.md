# Isolated Wayland UI smoke

Scope: verifying native prompts, actionable notifications, and input-gated behavior of a desktop app in a private compositor session, without touching the user's desktop. It does not replace a required human-click test: synthetic pointer proof is not a person clicking.

## Isolation

- Use a temporary data directory, synthetic content, a short private `XDG_RUNTIME_DIR`, a private session D-Bus, and a headless compositor (`WLR_BACKENDS=headless`, `WLR_RENDERER=pixman`, `WLR_LIBINPUT_NO_DEVICES=1`) with a notification daemon on the private bus. Keep every smoke process on these private endpoints and discover executable locations rather than copying old store paths. (src: isolated-ui-smoke; 2026-10-25)
- Never change the user's notification daemon configuration for a smoke. Use a fixed output size, float and resize the app window, and inspect the actual client rectangle before clicking controls. A stable notification position and no timeout make clicks deterministic.
- Set `DISPLAY` to an invalid value rather than leaving it unset: unset made egui/arboard try X11 and stalled each surface creation by several seconds, while an invalid value fails fast. (src: isolated-ui-smoke; 2026-10-25)
- A sandboxed GUI smoke (a bubblewrap container around a nested compositor) has its own traps; with a render-node-only `/dev` a libseat session stays inactive and no frames render. In the sandbox only: make the libseat backend unavailable (`LIBSEAT_BACKEND`), use a short runtime directory, mount `--tmpfs /tmp` for `wtype`, resolve binds by symlink target, disable the outer `wl_keyboard`, and run `wtype`/`grim` through the compositor's `exec_cmd`. These were observed on Hyprland 0.56.2 and not re-run here; never apply sandbox-only libseat changes to the production session. (src: isolated-ui-smoke; 2026-10)

## Drive input

- Drive pointer input through one long-lived `zwlr_virtual_pointer_manager_v1` connection: absolute motion using the output's real width and height, frame and roundtrip, about 150 ms for pointer entry, press (`BTN_LEFT`=272, `BTN_MIDDLE`=274), about 100 ms, release. One-shot `wlrctl` processes add and drop the seat capability too fast for a notification daemon to react, so clicks vanish. Keep the connection until verification finishes. (src: isolated-ui-smoke; 2026-10-25)
- Before clicking a notification, confirm it is displayed and belongs to the intended scenario; clear stale notifications only on the private bus. `dunstctl action`-style calls diagnose D-Bus routing but do not prove pointer dispatch.
- Hold Ctrl around Return with small delays rather than a zero-duration modifier sequence, and verify persisted exact content, not merely that a window closed.

## Timing

- Use an accelerated timer around 20 s for reminder tests rather than 4 s: a too-short interval plus slow surface creation can queue repeated empty-prompt refocusing and invalidate UI timing. Use a long timer for deterministic shortcut and layout scenarios, and state explicitly that accelerated timing is not wall-clock proof of the real interval. (src: isolated-ui-smoke; 2026-10-25)

## Input privacy and production touch

- Test input privacy against a fake authorized socket bound before the app starts, with the real handshake. Never connect an extra client to the production input socket when the daemon is newest-client-wins, and prove capture commands never ran with failing recording wrappers around them. (src: isolated-ui-smoke; 2026-10-25)
- Before restarting a production install, re-read the current recording or mode state, check for unsaved drafts, and restore the current mode, not an earlier snapshot. Do not launch unsolicited prompts on the user's desktop. (src: isolated-ui-smoke; 2026-10-25)

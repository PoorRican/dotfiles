# Zellij WASM plugin cache and border-flash troubleshooting

Use when a Home Manager-managed Zellij config starts flashing pane borders or misbehaving after a Zellij upgrade, especially when custom remote WASM plugins are used in `configs/zellij/`.

## What happened

A Zellij 0.44.x session used a custom default layout with `zjstatus` as a bottom `size=1 borderless=true` plugin pane and `zjstatus-hints` loaded in the background. The config originally used GitHub `releases/latest/download/*.wasm` URLs.

Symptoms:
- Zellij started and plugins loaded, but dual-pane layouts still caused visible border/frame flashing.
- Changing tabs or closing normal panes did not clear it.
- The plugin approval prompts were confusing because pinned URLs are distinct permission identities from old `latest` URLs.

## Diagnosis pattern

1. Check the live package and active config:

   ```sh
   zellij --version
   zellij setup --check
   readlink -f ~/.config/zellij/config.kdl
   readlink -f ~/.config/zellij/layouts/sourcerer-layout.kdl
   ```

2. Inspect active sessions/panes and metadata:

   ```sh
   zellij list-sessions
   zellij action list-panes
   zellij action list-tabs
   sed -n '1,240p' ~/.cache/zellij/contract_version_1/session_info/<session>/session-metadata.kdl
   sed -n '1,240p' ~/.cache/zellij/contract_version_1/session_info/<session>/session-layout.kdl
   ```

3. Compare configured remote plugin URLs with local cache files. Zellij caches remote WASM downloads under opaque numeric names in `~/.cache/zellij/`; `releases/latest/...` can remain stale because the URL string is the cache key.

   Latest release asset sizes/checksums can be compared against the numeric files. In this session, `zjstatus` was stale until the URL was pinned to `v0.23.0`; `zjstatus-hints` and `zellij-forgot` already matched their latest assets.

4. Tail logs for plugin/layout symptoms:

   ```sh
   tail -n 200 /tmp/zellij-$(id -u)/zellij-log/zellij.log
   ```

   Useful clues included `PluginId '0' not found - caching request`, repeated pty resize errors during startup, and plugin shutdown messages.

## Durable fixes

### Pin plugin URLs instead of using `latest`

Use release URLs in `configs/zellij/*.kdl`, for example:

```kdl
plugin location="https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm" {
    // config
}
```

For keybound plugins/aliases, similarly pin:

```kdl
LaunchOrFocusPlugin "https://github.com/dam4rus/zj-git-branch/releases/download/v0.6.0/zellij-git-branch.wasm" { ... }
LaunchOrFocusPlugin "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm" { ... }
zjstatus-hints location="https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm" { ... }
```

Why: Zellij does not provide a `plugin update` workflow. A changed pinned URL forces a fresh cache identity; `latest` can leave the old WASM cached indefinitely.

### Preserve the custom layout; disable `hide_frame_for_single_pane` first

If the custom layout previously worked and broke after a Zellij 0.44.x upgrade, do not jump straight to replacing the layout with Zellij's built-in `compact` layout. Treat `compact` as an isolation test only. The narrower fix is usually to keep the user's `default_layout` and status plugin, then disable zjstatus' frame-toggle option:

```kdl
// In layouts/<custom>.kdl, inside the zjstatus plugin block
// hide_frame_for_single_pane "true"
```

Why: upstream reports match this regression:

- `dj95/zjstatus#255` — `0.44.2 hide_frame_for_single_pane broken`; users report reverting to Zellij `0.44.1` works and `0.44.3` still needs a workaround.
- `zellij-org/zellij#5228` — `toggle_pane_frames` from plugins is reverted by Zellij within split seconds, breaking zjstatus frame-hiding behavior.

If the config already has global `pane_frames false`, `hide_frame_for_single_pane "true"` is redundant for the no-frame look and can be safely commented while preserving the custom status bar.

### Disable frame/mouse hover effects only if the narrow fix fails

If plugin versions are current and `hide_frame_for_single_pane` is disabled but dual-pane borders still flash, then test Zellij's frame-hover behavior:

```kdl
pane_frames false
advanced_mouse_actions false
mouse_hover_effects false
```

`mouse_hover_effects false` disables frame highlight/help-text hover effects. `advanced_mouse_actions false` also disables pane grouping/advanced mouse hover behavior. Keep these as a second-stage hypothesis, not the first fix when the evidence points to zjstatus frame toggling.

These config changes require applying Home Manager and starting a fresh Zellij session if `~/.config/zellij` is Home Manager-managed:

```sh
cd /home/swe/dotfiles
home-manager switch --flake .#cbox
zellij kill-all-sessions
zellij
```

### Pre-approve pinned plugin permission identities

Pinned plugin URLs are distinct from old `latest` URLs in `~/.cache/zellij/permissions.kdl`. If approval prompts are hard to complete, add clean entries for the pinned URLs:

```kdl
"https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm" {
    RunCommands
    ChangeApplicationState
    ReadApplicationState
}
"https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm" {
    ReadApplicationState
    MessageAndLaunchOtherPlugins
}
"https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm" {
    ReadApplicationState
    ChangeApplicationState
}
```

Be careful editing this file while Zellij is running; Zellij may rewrite it. If patching collides with a rewrite, rewrite the small file cleanly and verify braces with `read_file`.

## Pitfalls

- `zellij setup --check` only validates syntax; it does not prove a running session is using the newest Home Manager generation.
- `zellij setup --dump-layout <name>` may read from the active config dir rather than an overridden dotfiles path in some invocations. Verify the source file directly and/or copy config+layout into a temp config dir for validation.
- `zellij action list-panes` can omit plugin panes in a concise view; session metadata shows plugin panes and suppressed/floating panes more completely.
- If `git show HEAD` already contains the pinned URLs, do not report them as staged changes; check `git diff HEAD -- configs/zellij` before summarizing.

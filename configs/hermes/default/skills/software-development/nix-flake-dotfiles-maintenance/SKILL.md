---
name: nix-flake-dotfiles-maintenance
description: "Use when modifying a multi-host Nix flake or dotfiles repo, especially host-specific inputs, overlays, lockfile scope, and evaluation checks."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [nix, flakes, dotfiles, home-manager, overlays, multi-host]
    related_skills: [requesting-code-review, writing-plans]
---

# Nix Flake Dotfiles Maintenance

## Overview

Use this skill for user-local or repo-local Nix flake maintenance in a dotfiles repository that serves multiple machines. The main risk is accidentally coupling all hosts to one host's local path, overlay, platform-specific package, or broad lockfile change.

Core principle: treat a shared flake as multi-system-impacting by default. Keep changes minimal, host-scoped, and evaluation-verified on the affected platforms.

## When to Use

Use this skill when:
- editing `flake.nix` or `flake.lock`
- adding or removing overlays for one host
- introducing local `path:` inputs or private repos
- fixing Linux evaluation failures caused by macOS-only dependencies
- changing Home Manager configurations in a shared dotfiles repo

Prefer another skill when:
- the task is general Nix package authoring rather than flake maintenance
- the task is a broad implementation plan rather than direct config work
- the user asked specifically for Hermes Agent configuration; load `hermes-agent` first in that case

## Default Workflow

1. **Inspect the flake shape first**
   - Read `flake.nix`
   - Search for the input, overlay, or package name across the repo
   - Identify which hosts consume it

2. **Assume cross-host blast radius until proven otherwise**
   - If an input appears in the top-level `inputs` set, every evaluation may need to resolve it
   - A local `path:` input in global `inputs` is a common cause of breakage on other machines

3. **Scope platform-specific dependencies to the narrowest host**
   - For macOS-only packages or overlays, load them only inside the Darwin host path
   - Avoid forcing Linux hosts to resolve a macOS-only local path

4. **Prefer the smallest possible edit**
   - Do not restructure the flake unless necessary
   - Do not update unrelated inputs
   - Do not touch `flake.nix` input wiring beyond the exact dependency unless the user asked for it

5. **Stage newly-created Nix files before flake evaluation**
   - Nix flakes evaluate the Git index/tree, not arbitrary untracked files in the working directory.
   - If you add a new module/profile file and import it, run `git add <new-file> <importing-file>` before `nix eval`; otherwise evaluation can fail with `Path ... is not tracked by Git`.
   - Stage only the intended files, especially in repos with unrelated untracked generated state.

6. **Verify by evaluating the unaffected hosts**
   - If the change is meant to stop Linux breakage, evaluate the Linux home configurations
   - If the change is host-specific, also check the target host configuration if the dependency is available in the current environment

7. **Report exactly what changed**
   - Note whether `flake.lock` changed and why
   - Call out any remaining caveat, such as a Darwin-only path that still requires local availability on macOS

8. **For desktop/Home Manager status questions, separate committed from applied from running**
   - Repo state: committed/staged/unstaged, ahead/behind origin
   - Evaluation state: whether the affected `homeConfigurations.<host>` still evaluates
   - Applied state: whether the current Home Manager generation/config symlink contains the change
   - Runtime state: whether the relevant service/process is actually running and the app has re-registered
   - Avoid saying a change is "active" just because it exists in the dotfiles commit; say "implemented/committed but not applied" when `home-manager switch` has not made it live
   - For Git config under Home Manager, distinguish managed XDG config (`~/.config/git/config`, often an HM symlink) from unmanaged legacy config (`~/.gitconfig`). Git reads both, and `~/.gitconfig` can contain stale `url.*.insteadOf` or credential-helper settings that make `git remote -v` look wrong even when the Home Manager-managed file is clean.

9. **When committing accumulated dotfiles work, split exactly by the user's requested granularity**
   - If the user asks for file-by-file commits, first inspect staged vs unstaged with `git status --short --branch`, `git diff --cached --name-status`, and `git diff --name-status`.
   - Run lightweight verification before and after the split when practical: shell syntax checks for scripts, app config validation such as `i3 -C`, and `nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file` for Home Manager.
   - If many intended files are already staged, `git restore --staged -- <files...>` for just that set, then `git add -- <one-file-or-tight-pair>` before each commit. Do not disturb unrelated dirty files or generated/untracked trees.
   - Use conventional commit subjects and concise bullet bodies that describe the file's concrete behavior, runtime effect, and preserved scope.
   - Finish by reporting the new commit range plus any unrelated remaining working-tree changes.

## Host-Specific Overlay Pattern

### Problem pattern

This pattern is dangerous in a multi-host repo:

```nix
inputs = {
  some-overlay = {
    url = "path:/Users/name/repos/some-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = { nixpkgs, some-overlay, ... }:
{
  homeConfigurations.host = ...
}
```

Even if only one host uses the overlay, all hosts may need to resolve that top-level input during evaluation.

### Safer pattern

Keep the overlay out of global `inputs` when it is host-local and platform-specific. Resolve it only where needed:

```nix
outputs = { nixpkgs, ... }@inputs:
let
  someOverlay = (builtins.getFlake "path:/Users/name/repos/some-overlay").overlays.default;
in {
  homeConfigurations.mbp = mkHome {
    system = "aarch64-darwin";
    overlays = [ someOverlay ];
  };
}
```

This keeps Linux evaluations from depending on that path input being present in `flake.lock` or resolvable globally.

## Lockfile Rules

- If you remove a global input from `flake.nix`, remove the corresponding entry from `flake.lock` if it is no longer referenced.
- Do not refresh unrelated lock entries unless the user asked for a broader flake update.
- After editing `flake.lock`, diff only the targeted sections and confirm there was no incidental churn.

## Verification Commands

Use evaluation before any rebuild:

```bash
nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file
```

Useful sequence:

```bash
# Check the hosts that should no longer be affected
nix eval '.#homeConfigurations.emc.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.dgx.activationPackage.drvPath' --no-write-lock-file
```

If you're on the target platform and the local path exists, also evaluate the target host:

```bash
nix eval '.#homeConfigurations.mbp.activationPackage.drvPath' --no-write-lock-file
```

## Repo-Specific Guardrails

For this user's dotfiles repo:
- treat the repo as multi-system-impacting by default
- when updating a flake input, update only the named input unless explicitly told otherwise
- do not edit `flake.nix` just to change lock revisions unless the user asked for structure changes
- after an input change, report where the input is consumed
- this repo usually uses Home Manager evaluation as the lightweight correctness check
- for exploratory cbox desktop migrations such as i3 → Hyprland, prefer a manual Arch/yay smoke test before designing a full Home Manager replacement: install the compositor, launch defaults from a TTY, verify Super key/terminal/workspaces, then codify a `cbox-hyprland` profile only after the basics work
- when continuing cbox/i3 comfort work, preserve user-owned Ghostty config unless explicitly asked to manage it; launch the existing `ghostty` binary rather than importing the Ghostty module into i3 desktop wiring
- for macOS-to-i3 transition tweaks, prefer discoverability and reversible comfort layers: Rofi combi launcher, searchable keybinding cheat sheet, clipboard and symbol pickers, natural scrolling, and focused app launchers
- when changing cbox/i3 lockscreen wiring, use a central wrapper script deployed by Home Manager (for example `~/.local/bin/i3-lock`) and point both manual bindings and `xss-lock` idle/suspend hooks at it; stop stale live `xss-lock -- ... i3lock` processes before testing replacements
- for cbox/i3 keybinding failures, debug in layers before changing the keyboard: command via `i3-msg exec`, physical key events via `xinput test-xi2 --root`, i3 binding events via `i3-msg -t subscribe -m '["binding"]'`, then Home Manager symlink/config identity. The user's Kinesis Command key should arrive as Super/Mod4, so do not assume a firmware/layout problem until XInput contradicts that.
- avoid nested i3 command variables such as `set $launcher $hm_bin/rofi ...`; i3 variable expansion is not recursive in the way shell authors expect. Use fully-expanded absolute command variables for launchers and lock wrappers, while `$hm_bin/foo` is fine directly in a binding line.
- when debugging i3 shortcut failures, separate command failure from binding failure: confirm the active Home Manager symlink matches the repo config, verify the target command through `i3-msg exec`, then inspect XKB/modifier/keycode state before changing bindings
- for cbox/i3 muscle memory, preserve `Super+Shift+r` as the reload binding when requested; if a full i3 process restart is still needed, move it to a less accidental chord such as `Super+Ctrl+Shift+r`
- if `bindsym $mod+space` does not fire despite a valid `space` keysym and a working launcher command, verify keycode 65 with `xmodmap -pke` and use `bindcode $mod+65 ...` for the physical Space key rather than repeatedly reloading/restarting
- for JetBrains Toolbox on cbox/i3, closing the Toolbox widget can leave the background Toolbox process/daemon alive; a reliable reopen binding can run `/usr/bin/jetbrains-toolbox` as a secondary instance, and an autohide helper can dismiss the widget with `i3-msg '[class="jetbrains-toolbox"] kill'` on focus loss. Prefer this explicit binding over depending solely on the Polybar tray bridge when StatusNotifier/AppIndicator bridging is flaky.
- for cbox Bluetooth BLE HID trouble (i3 or Hyprland), do not assume Blueman is the right interface. If a keyboard/mouse causes rapid connect/disconnect, many Blueman popup windows, or the manager cannot connect, first separate layers: adapter health (`rfkill`, `bluetoothctl show`, `btmgmt info`, `journalctl -u bluetooth`), RF health (`bluetoothctl scan on` and RSSI of nearby devices), UI/session state (`blueman-applet.service`, Waybar on-click target, polkit agent), and device bonding state (`bluetoothctl info`). Remove stale entries that are `Trusted: yes` but not paired/bonded and re-pair through a *live* interactive `bluetoothctl --agent KeyboardDisplay` session. Treat very weak RSSI (roughly below `-90 dBm`) as a device/antenna/distance/battery/interference factor, but if the adapter discovers many nearby devices at normal RSSI, the controller/driver/radio path is probably functional. See `references/i3-bluetooth-ble-hid.md` for the expanded direct-BlueZ workflow.
- for cbox Hyprland exploration, do not overthink the Home Manager/dotfiles path first when the user is still smoke-testing. If they ask to install/run Hyprland manually, use the Arch/yay local-config path first, validate launch from a TTY, tune `~/.config/hypr` and `~/.config/waybar`, and only later promote the result into a `cbox-hyprland` declarative profile. See `references/cbox-hyprland-smoke-test.md`.
- for cbox Hyprland Lua keybinding changes, edit the repo config (`configs/hypr/hyprland.lua`) and run the usual Lua/Nix checks, but do not assume `hyprctl reload` will immediately register newly-added Lua binds in the current session; it can also clear binds added earlier with `hyprctl eval`. After `home-manager switch`, verify live bindings with `hyprctl -j binds`; if new bindings are absent but the config is correct, apply them live with `hyprctl eval 'hl.bind(...)'` or tell the user a Hyprland restart will pick up the file. For window movement by keyboard, Hyprland Lua supports `hl.dsp.window.move({ direction = "left"|"right"|"up"|"down" })`; for keyboard resizing it supports `hl.dsp.window.resize({ x = +/-40, y = 0, relative = true })` and `hl.dsp.window.resize({ x = 0, y = +/-40, relative = true })`.
- for cbox Hyprland notification issues (browser notifications showing as tiled/full windows, no `notify-send` output, or missing top-right bubbles), first check the current session bus with `gdbus`/`notify-send`, `pgrep -a dunst`, and `hyprctl -j layers`. A stale `dunst` on another `DBUS_SESSION_BUS_ADDRESS` does not help the active Wayland session. The durable pattern is to install `dunst`/`libnotify`, autostart `hmBin .. "/dunst"` from `configs/hypr/hyprland.lua`, and include the Home Manager profile share path in `XDG_DATA_DIRS` so D-Bus activation can find `org.freedesktop.Notifications`. Dunst's Wayland layer-shell surface should appear in Hyprland layers as namespace `notifications` at overlay level/top-right; this is what lets notifications appear above fullscreen windows. If the issue recurs even though the repo config contains this fix, check whether Hyprland is running in `--safe-mode` after a crash/restart: safe-mode can leave configured Lua autostarts/environment unapplied, while Vivaldi is already running and has fallen back to app-owned notification windows. In that case, live repair is: export `XDG_DATA_DIRS=$HOME/.local/state/nix/profiles/home-manager/home-path/share:/usr/local/share:/usr/share`, run `dbus-update-activation-environment --systemd ...`, start `dunst` on the active bus, verify `org.freedesktop.Notifications` has an owner and `hyprctl -j layers` shows namespace `notifications`, then restart Vivaldi. For a more crash-resistant fix, consider moving dunst into a Home Manager/systemd user service or pre-Hyprland startup helper so notifications do not depend solely on Hyprland Lua autostart.
- for cbox Hyprland PATH/Nix disappearance issues, check `configs/hypr/hyprland.lua` for `hl.env("PATH", ...)` before blaming the Nix install. A common failure mode is Hyprland intentionally setting a minimal PATH while inheriting Nix's exported `__ETC_PROFILE_NIX_SOURCED=1`; new zsh shells then skip `nix-daemon.sh` and `nix` is absent. Durable fix: include `/nix/var/nix/profiles/default/bin` in Hyprland's PATH and `/nix/var/nix/profiles/default/share` in `XDG_DATA_DIRS`, and harden `configs/zsh/zshenv` to unset `__ETC_PROFILE_NIX_SOURCED` when the default Nix binary exists but the default profile bin is missing from PATH. Verify with a hostile-env shell (`env PATH=$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/usr/local/bin:/usr/bin:/bin __ETC_PROFILE_NIX_SOURCED=1 zsh -c 'command -v nix && nix --version'`) and, in Hyprland 0.55+ Lua-parser sessions, a child-process test via `hyprctl dispatch 'hl.dsp.exec_cmd("/tmp/test-script")'`; legacy `hyprctl dispatch exec ...` can fail with Lua parse errors.
- for cbox Hyprland Bluetooth/Blueman failures, separate adapter health from desktop session integration before blaming antennas or drivers. If `bluetoothctl scan on` discovers nearby devices with reasonable RSSI and kernel logs lack firmware/reset loops, inspect the Hyprland session stack: `blueman-applet` should be running, and a user Polkit auth agent should be running in addition to system `polkitd`. The durable pattern is to install `blueman`, `bluez`, and `lxqt.lxqt-policykit`, autostart `hmBin .. "/blueman-applet"` and `hmBin .. "/lxqt-policykit-agent"` from `configs/hypr/hyprland.lua`, and have Waybar launch the Home Manager `blueman-manager` path rather than `/usr/bin` when the GUI is HM-managed. See `references/cbox-hyprland-bluetooth-session-agents.md`.
- when auditing stale cbox i3 state after moving to Hyprland, distinguish active Home Manager imports from harmless dormant repo files. The important stale wiring is `nix/hosts/cbox.nix` importing `../profiles/i3-desktop.nix`, which still deploys i3/X11 packages, `~/.config/i3`, Polybar service/config, and `~/.local/bin/i3-*` helpers. Prefer removing only the cbox import first and keeping the old config files as rollback/history unless the user explicitly asks to delete them. See `references/cbox-hyprland-i3-cleanup-audit.md`.
- for cbox Hyprland workspace/layout design, distinguish Waybar's semantic icons from Hyprland workspace rules. Hyprland supports per-workspace layouts through `hl.workspace_rule({ workspace = "...", layout = "dwindle|master|scrolling|monocle", layout_opts = {...} })`; named workspaces plus Waybar icon updates are preferable to silently repurposing numeric icons. For this user's emerging model, consider a small set of roles (browser/research, notes/Obsidian, engineering), using scrolling as a window/column tape, master as primary-pane-plus-stack, monocle for solo notes, and special workspaces or custom summon bindings for Obsidian. A low-risk scrolling experiment is numeric workspace 4 with `layout = "scrolling"`, comma/period column movement, ctrl-comma/period focus, shift-comma/period swap column, and ctrl-I/ctrl-O consume/expel. See `references/cbox-hyprland-workspaces-and-layouts.md`.
- for cbox Hyprland/Ghostty clipboard fixes, use a Wayland-native path rather than porting i3 helpers: `wl-clipboard` + `cliphist` + an idempotent `wl-paste --type text --watch cliphist store` startup helper, with `wtype` for paste injection into native Wayland clients. Confirm Ghostty is not XWayland via `hyprctl clients -j`, verify `wl-copy`/`wl-paste` round-trip before editing, and remember that installing `cliphist` is not sufficient without a live watcher. See `references/cbox-hyprland-wayland-clipboard.md`.
- for cbox Hyprland symbol/character pickers, port the old i3 Rofi pattern to a Wayland-native script rather than using X11 tools or relying on notifications: use `rofi -dmenu` over the managed `configs/rofi/symbols.tsv`, copy the selected glyph with `wl-copy --type text/plain`, and optionally paste with `wtype -M ctrl v -m ctrl` after a short delay. If the user asks specifically for mathematical symbols, keep the picker math-focused instead of mixing the full emoji database into the primary list. Install/deploy `wtype`, `wl-clipboard`, `rofi`, and the script through the Hyprland Home Manager module, then verify both Nix evaluation and the installed symlinks. See `references/cbox-hyprland-rofi-symbol-picker.md`.
- for cbox Hyprland scratchpad launchers (floating terminals, sticky wiki sessions, Rofi drun entries), keep window manipulation target-specific and verify live state before moving/hiding windows. Hyprland 0.55.x Lua config may reject legacy `hyprctl dispatch togglespecialworkspace ...` / `dispatch exec ...` syntax; use Lua dispatch expressions such as `hl.dsp.workspace.toggle_special("name")` and `hl.dsp.exec_cmd("...")`. `hyprctl reload` may not register newly-added Lua keybinds; use `hyprctl eval 'hl.bind(...)'` for live testing and verify with `hyprctl -j binds`. If Rofi appears broken after scratchpad work, first check `hyprctl layers -j` for namespace `rofi` and inspect windows on special workspaces; a browser can appear to disappear if it was accidentally moved to a special workspace. Ghostty may still report class `com.mitchellh.ghostty` despite `--class=...`, so match a stable title prefix as a fallback. See `references/cbox-hyprland-scratchpad-launchers.md`. 
- for cbox Hyprland scratchpad/special-workspace launchers, prefer a repo script deployed to `~/.local/bin`, a drun desktop entry via `xdg.dataFile."applications/..."`, a unique Ghostty `--class`/`--title` with `--gtk-single-instance=false`, and a named special workspace toggled by hotkey. In Hyprland 0.55+ Lua-parser sessions, shell scripts should call Lua dispatcher forms such as `hyprctl dispatch 'hl.dsp.workspace.toggle_special("name")'` and `hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:name; float; size 85% 85%; center] ...")'`; legacy `hyprctl dispatch togglespecialworkspace name` / `dispatch exec ...` can fail with Lua parse errors. For Zellij create-or-attach launchers, use `zellij attach --force-run-commands <session>` when present and `zellij --session <session> --new-session-with-layout <layout>` for first creation. See `references/cbox-hyprland-special-workspace-launchers.md`.
- for Zellij layout/status glitches after upgrades in the dotfiles-managed setup, distinguish valid KDL from live plugin behavior. Inspect `nix/modules/zellij.nix`, `configs/zellij/config.kdl`, and `configs/zellij/layouts/*.kdl`; then check `zellij setup --check`, `zellij action list-panes`, active `~/.cache/zellij/*/session_info/*.kdl`, and `/tmp/zellij-$(id -u)/zellij-log/zellij.log`. Treat `default_tab_template` status panes and `load_plugins` background WASM plugins as first suspects when switching tabs or closing normal panes does not clear the symptom. Prefer pinning remote plugin URLs instead of using `latest`, or isolate with `zellij --new-session-with-layout default --session zj-default-layout-test`. See `references/zellij-layout-plugin-debugging.md`.
- when adding long-running i3 helpers that subscribe to events or contain shell pipelines, verify they are truly running after `i3-msg reload` with `ps`/`pgrep`; if a direct `exec_always --no-startup-id $local_bin/helper` line does not persist, wrap it as `exec_always --no-startup-id /bin/sh -lc 'exec /absolute/path/to/helper'` in the i3 config.
- for Home Manager-managed Zellij configs using remote WASM plugins, avoid GitHub `releases/latest/download/*.wasm` URLs: Zellij caches remote plugins under opaque files in `~/.cache/zellij`, and `latest` can remain stale because the URL string is the cache key. Pin release URLs, compare cache file hashes/sizes with release assets when debugging, and remember pinned URLs need separate entries in `~/.cache/zellij/permissions.kdl`. If a custom zjstatus layout starts flashing after Zellij 0.44.x, preserve the custom layout and isolate frame toggles before replacing it: both tested rows with zjstatus `hide_frame_for_single_pane "true"` flickered, including with global `pane_frames false` removed. The stable fallback is global `pane_frames false` with `hide_frame_for_single_pane` commented. Only after that test border/hover toggles such as `advanced_mouse_actions false` and `mouse_hover_effects false`. See `references/zellij-wasm-plugin-cache-and-border-flash.md` and `references/zellij-zjstatus-frame-toggle-matrix.md`.

- on cbox/i3, Home Manager's `polybar.service` can run with a very restricted `PATH` (often just the Polybar package and `/run/wrappers/bin`).

- on cbox/i3, Home Manager's `polybar.service` can run with a very restricted `PATH` (often just the Polybar package and `/run/wrappers/bin`). Polybar `custom/script` modules and click handlers that execute `~/.local/bin/*` scripts will fail with `env: 'bash': No such file or directory` if the script shebang is `#!/usr/bin/env bash`. For Polybar-invoked repo scripts on this Arch host, use an absolute shebang such as `#!/usr/bin/bash` or invoke them through an absolute shell path, then test with `env -i PATH=<polybar-service-path> script` before applying.
- when the user reports "many keys stopped" after i3 edits, first stabilize the session without a full reboot: run `i3-msg 'mode default'`, then `i3-msg restart` or reload only after `i3 -C` passes; verify `i3-msg -t get_binding_state`, `setxkbmap -query`, `xmodmap -pm`, and `xmodmap -pke` for affected keysyms before making more config edits
- for i3 keybinding regressions on cbox/Kinesis, separate three cases explicitly: normal typing broken implies keyboard firmware/layer or XKB layout; typing fine but shortcuts dead implies i3 binding/config; commands bound but not launching implies PATH/executable issue

- for Neovim lazy.nvim deprecation reports in this dotfiles repo, do not assume lazy itself is outdated just because lazy appears in stack traces. First confirm the live `~/.config/nvim` symlink and lazy.nvim git revision, then run headless startup, `:checkhealth vim.deprecated`, and lazy spec-notice probes. In a Neovim 0.12+ session, common fixes are replacing `vim.lsp.set_log_level` with `vim.lsp.log.set_level`, replacing deprecated `vim.lsp.with` wrappers with explicit handler-config merging, and wrapping signature help with `vim.lsp.handlers.signature_help` rather than hover. Stage only intended Neovim config files; leave unrelated `pkglock.json` updates alone unless requested. See `references/neovim-lazy-deprecation-triage.md`.

- for Neovim lazy/plugin update fallout in this dotfiles repo, inspect `~/.local/state/nvim/lsp.log` and current attached clients before assuming lazy.nvim itself is broken. Newer `mason-lspconfig.nvim` can auto-enable every installed Mason LSP by default; in markdown/wiki files this can silently attach `markdown_oxide`/`marksman` and spam `"VAULT Lock is good"` / `"FILES Lock is good"`. Constrain `mason_lspconfig.setup({ automatic_enable = mason_server_names })` so only explicitly configured servers attach. See `references/neovim-mason-lspconfig-auto-enable.md`.
- for Obsidian/wiki Markdown editing in this dotfiles-managed Neovim setup, treat `obsidian.nvim`, `markdown-oxide`, and `render-markdown.nvim` as the preferred stack when the user asks for native Obsidian Markdown/linking features. Wire both editor-managed and declarative dependencies: lazy.nvim plugin specs, Mason package entries, Home Manager packages for `markdown-oxide` and `tree-sitter`, explicit `render-markdown.nvim` dependencies on Tree-sitter and web-devicons, and headless Markdown-buffer checks that confirm plugin load, `markdown_oxide` LSP attachment, and active Tree-sitter parsing. See `references/neovim-obsidian-markdown-wiki-stack.md`.

## Common Pitfalls

1. **Leaving a local path input in top-level `inputs`.**
   This can break evaluation on machines that do not have the path.

2. **Removing a flake input from `flake.nix` but leaving stale lockfile entries.**
   The lockfile then suggests a dependency still exists.

3. **Verifying only the edited host.**
   The whole point of the change may be to unblock other hosts.

4. **Performing a rebuild when a cheap eval would suffice.**
   Start with `nix eval` for a low-cost syntax and dependency check.

5. **Over-broad cleanup.**
   Do not opportunistically refactor the flake or update unrelated inputs during a focused fix.

7. **New files invisible to flake evaluation until staged.**
   If an imported module/profile is newly created, `nix eval` may fail with `Path ... is not tracked by Git`. Stage only the intended new file and importing file, then rerun evaluation.

8. **Assuming platform-specific package usage implies platform-specific flake resolution.**
   Usage can be host-scoped while the input remains globally resolved. Scope both.

9. **Combining a full Neovim config-tree symlink with `programs.neovim`.**
   If `xdg.configFile."nvim".source` manages the whole `~/.config/nvim` tree, `programs.neovim.enable = true` can also generate `xdg.configFile."nvim/init.lua"` for provider/plugin wrapper config. Home Manager then fails with `Error installing file '.config/nvim/init.lua' outside $HOME` because the `nvim` target is already a symlinked directory. For lazy.nvim-managed dotfiles, prefer package-only Neovim (`home.packages = [ pkgs.neovim ];`) or restructure the config so Home Manager owns `init.lua` and individual runtime files, but do not declare both the whole tree and HM-generated `init.lua`.

10. **Conflating committed declarative config with live desktop state.**
   For Home Manager/i3/Polybar work, a dotfiles commit may be correct but not applied to the current generation, and a configured autostart may still not be running until the session reloads or the app restarts. For status reports, explicitly distinguish repo state, evaluation state, applied generation, and live process state.

11. **Leaving duplicate package providers after moving from `programs.neovim` to package-only Neovim.**
   In the user's dotfiles, `nix/modules/neovim.nix` now installs an overridden Neovim package and manages the whole `~/.config/nvim` symlink. Host-specific compatibility shims such as `home.packages = [ pkgs.neovim ];` in `nix/hosts/cbox.nix` can create two different `bin/nvim` providers in `home-manager-path`, failing with `pkgs.buildEnv error: two given paths contain a conflicting subpath ... /bin/nvim`. Remove the host-level plain `pkgs.neovim` when the shared module already provides Neovim; keep only `programs.neovim.enable = lib.mkForce false` if needed to suppress Home Manager's program module.

11. **Nested i3 variables are not shell variables.**
   i3 may not recursively expand variable values that contain other variables. If `set $launcher $hm_bin/rofi ...` is later used in `exec $launcher`, i3 binding events can show the literal `$hm_bin/rofi` command. For command variables that are invoked indirectly, use fully-expanded absolute paths. When a binding does nothing, verify with `i3-msg -t subscribe -m '["binding"]'` before assuming the keyboard is wrong.

11. **Treating a working command as proof that a shortcut works.**
   For i3, a launcher can work from the shell or through `i3-msg exec` while the key chord still does not fire. After verifying the command, inspect the live config, Home Manager symlink target, XKB modifier map, and physical keycode. For stubborn Space-key chords, prefer a verified `bindcode $mod+65 ...` binding over repeated reloads or guessing.

12. **Assuming a Home Manager/i3 autostart line means a helper is alive.**
   Long-running helper scripts that subscribe to i3 events or use shell pipelines can fail to persist even when `i3-msg -t get_config` shows the intended `exec_always` line. After reload, verify the actual script and child `i3-msg -t subscribe`/`jq` processes. If direct invocation does not persist, wrap the absolute helper path with `/bin/sh -lc 'exec ...'` in the i3 config.

13. **Only grepping `~/.config/polybar/config.ini` for module verification.**
   Home Manager can install a tiny Polybar config wrapper that points to an `include-file` in `/nix/store`. Inspect the include target or the Polybar journal before concluding a configured module is missing.

## Reference Files

- `references/host-specific-overlays.md` — concrete example of converting a macOS-only overlay from a global flake input to a host-local `builtins.getFlake` binding.
- `references/i3-desktop-package-selection.md` — compact research note for practical X11+i3 Home Manager package choices: Polybar/Rofi/i3status-rust and companion fonts.
- `references/i3-legacy-config-integration.md` — local dotfiles Git-history discovery and Home Manager wiring pattern for porting the repo's legacy `.old/i3config` into cbox/i3 with Polybar/Rofi.
- `references/polybar-statusnotifier-tray-bridge.md` — Polybar `internal/tray` only hosts XEmbed; use `snixembed` to bridge StatusNotifier/AppIndicator tray icons such as JetBrains Toolbox into the tray.
- `references/i3-comfort-tweaks.md` — cbox/i3 comfort-layer patterns: macOS-style natural scrolling, Rofi combi/SSH, clipboard and symbol pickers, keybinding cheat sheet, Vivaldi focus-or-launch, and Ghostty Quake terminal.
- `references/polybar-tray-statusnotifier-bridge.md` — diagnostic and fix pattern for apps whose Linux tray icons use StatusNotifier/AppIndicator and therefore need a bridge such as `snixembed` before they appear in Polybar's XEmbed tray.
- `references/declarative-desktop-change-status.md` — status-reporting checklist for Home Manager/i3/Polybar changes: distinguish committed config, evaluation, applied generation, and live runtime state.
- `references/i3-keybinding-debugging.md` — layered i3 keybinding diagnostics: command smoke tests, XInput key capture, i3 binding-event subscription, Home Manager symlink checks, and the non-recursive i3 variable pitfall.
- `references/i3-keybinding-runtime-debugging.md` — runtime troubleshooting sequence for i3 shortcuts that do not fire despite active Home Manager config: command-vs-binding isolation, symlink verification, XKB/modifier checks, and `bindcode` fallback for physical Space.
- `references/i3-toolbox-widget-and-long-running-helpers.md` — cbox/i3 JetBrains Toolbox widget reopen/autohide pattern, long-running `exec_always` helper verification, and Home Manager Polybar include-file verification.
- `references/i3-bluetooth-ble-hid.md` — cbox/i3 BLE HID troubleshooting: Blueman popup storms, stale BlueZ paired/bonded state, `bluetoothctl --agent KeyboardDisplay` pairing, and RSSI/antenna checks.
- `references/cbox-hyprland-smoke-test.md` — cbox Hyprland migration smoke-test workflow: install/run manually via Arch/yay first, local `~/.config/hypr`/Waybar tuning, TTY autostart guard, then later promote to dotfiles/Home Manager.
- `references/cbox-hyprland-i3-cleanup-audit.md` — audit and cleanup pattern for cbox after the i3 → Hyprland switch: separate active imports, applied symlinks/services, runtime processes, and dormant repo files; remove the i3 profile import before deleting old files.
- `references/cbox-hyprland-smoke-test.md` — start an i3 → Hyprland migration with a manual Arch/yay install and default-session smoke test before codifying a Home Manager profile.
- `references/cbox-hyprland-workspaces-and-layouts.md` — cbox Hyprland workspace/layout design notes: Waybar icons vs workspace rules, per-workspace layouts, scrolling/master/monocle tradeoffs, Obsidian summon options, and proven Lua bind dispatchers.
- `references/cbox-hyprland-wayland-clipboard.md` — cbox Hyprland/Ghostty clipboard pattern: diagnose native Wayland clients, start `cliphist` watchers, replace i3/X11 `xclip`/`xdotool` helpers with `wl-copy`/`cliphist`/`wtype`, and verify live clipboard collection safely.
- `references/cbox-hyprland-rofi-symbol-picker.md` — cbox Hyprland Rofi symbol picker pattern: math-focused TSV, Wayland-native `wl-copy` + `wtype`, Home Manager wiring, and verification/pitfalls.
- `references/cbox-hyprland-bluetooth-session-agents.md` — cbox Hyprland Bluetooth GUI troubleshooting: distinguish adapter/RF health from missing Blueman applet/Polkit session agents, Home Manager wiring, live-start verification, and BLE HID cleanup.
- `references/zellij-wasm-plugin-pinning.md` — Zellij remote WASM plugin cache behavior: why `releases/latest` can stay stale, how to pin release asset URLs, validate config, and apply through Home Manager safely.
- `references/neovim-mason-lspconfig-auto-enable.md` — Neovim lazy/plugin update diagnostic note: Mason auto-enabling installed markdown LSPs, log spam symptoms, constrained `automatic_enable` fix, and verification commands.
- `references/neovim-obsidian-markdown-wiki-stack.md` — Obsidian/wiki Markdown stack for this dotfiles Neovim setup: `obsidian.nvim`, `markdown-oxide`, `render-markdown.nvim`, declarative dependencies, Tree-sitter main-branch API pitfall, and headless verification checks.
- `references/neovim-lazy-deprecation-triage.md` — Neovim/lazy.nvim deprecation triage: distinguish lazy loader stack traces from real deprecated APIs, use `checkhealth vim.deprecated`, probe lazy spec notices, and apply known Neovim 0.12+ LSP API replacements.

## Verification Checklist

- [ ] Read `flake.nix` and identified every consumer of the changed input or overlay
- [ ] Kept the change scoped to the requested host/platform behavior
- [ ] Avoided unrelated flake input or lockfile churn
- [ ] Verified the unaffected hosts with `nix eval ...activationPackage.drvPath --no-write-lock-file`
- [ ] Confirmed `git diff` only shows the intended `flake.nix`/`flake.lock` edits
- [ ] Reported any platform-specific assumptions that still remain

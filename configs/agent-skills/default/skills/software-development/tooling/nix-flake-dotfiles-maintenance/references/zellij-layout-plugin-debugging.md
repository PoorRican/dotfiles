# Zellij layout/plugin glitch debugging in Home Manager dotfiles

Use this when Zellij panes, borders, status lines, or layouts behave oddly after an upgrade in the user's dotfiles-managed setup.

## Pattern observed

Zellij can validate the config with `zellij setup --check` while the live UI is still broken by a layout-level or background WASM plugin. In this repo the Zellij module deploys:

- `configs/zellij/config.kdl`
- `configs/zellij/layouts/*.kdl`

A custom `default_tab_template` can inject a `pane size=1 borderless=true { plugin ... }` into every tab. A `load_plugins { ... }` block can also keep background/floating plugins alive. These are not normal user panes, so changing tabs or closing normal panes may not clear the symptom.

## Investigation sequence

1. Inspect the active version and config source:

   ```bash
   command -v zellij
   zellij --version
   zellij setup --check
   readlink -f ~/.config/zellij/config.kdl
   find ~/.config/zellij -maxdepth 3 -printf '%y %p -> %l\n'
   ```

2. Inspect dotfiles-managed Zellij files:

   - `nix/modules/zellij.nix`
   - `configs/zellij/config.kdl`
   - `configs/zellij/layouts/*.kdl`

   Look specifically for:

   - `default_layout`
   - `default_tab_template`
   - `children`
   - `pane size=1 borderless=true`
   - `plugin location="https://.../latest/...wasm"`
   - `load_plugins`
   - `pane_frames`, `auto_layout`, `session_serialization`

3. Inspect live session state and serialized layouts:

   ```bash
   zellij list-sessions
   zellij list-aliases
   zellij action list-tabs
   zellij action list-panes
   find ~/.cache/zellij -maxdepth 4 -type f -path '*session_info*' -printf '%TY-%Tm-%Td %TH:%TM:%TS %s %p\n' | sort -r | head -80
   ```

   Read the current session's `session-layout.kdl` and `session-metadata.kdl`. Plugin panes are marked with `is_plugin true`; background/floating plugin panes may be `is_suppressed true`.

4. Check logs after reproducing:

   ```bash
   tail -n 160 /tmp/zellij-$(id -u)/zellij-log/zellij.log
   ```

   Startup PTY warnings may be noise. Prefer correlating fresh errors/warnings with the exact reproduction.

## Isolation tests

- Start a session with the built-in layout to separate config-level plugins from layout-level plugins:

  ```bash
  zellij --new-session-with-layout default --session zj-default-layout-test
  ```

- If the symptom disappears with the built-in layout, suspect the custom `default_tab_template` status/plugin pane.
- If it persists even with a built-in layout, suspect `load_plugins` or global config/theme behavior.

## Fix patterns

- Disable background plugins first, especially ones connected to status-line pipes.
- Remove corresponding status placeholders from status plugin format strings, e.g. remove a `{pipe_*}` token when disabling its producer plugin.
- Avoid `latest` plugin URLs for durable setups. Pin plugin URLs to a known-good release asset, or replace remote WASM status plugins with Zellij built-ins (`status-bar`, `compact-bar`) if stability matters more than custom UI.
- Restart the Zellij session after layout/plugin changes; many settings are only loaded at session start.

## Pitfalls

- `zellij setup --check` only proves the KDL is well-defined. It does not prove third-party WASM plugins render correctly against the current Zellij version.
- Closing normal panes or switching tabs does not remove panes injected by `default_tab_template`; new tabs will recreate them.
- A background plugin in `load_plugins` can affect the UI without appearing as a normal visible pane.
- Remote `latest` WASM URLs introduce unpinned runtime changes independent of the Nix-pinned `pkgs.zellij` version.

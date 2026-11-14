# Editor and terminal integration

## Neovim

A deprecation trace through lazy.nvim can originate in the plugin configuration it loaded, not the loader. Check the active config link and `:checkhealth vim.deprecated` for the actual caller. After Mason plugin updates, installed servers can be auto-enabled and attach to buffers unexpectedly; inspect attached clients and constrain `automatic_enable` to the intended server list if appropriate. A changed config does not stop clients already attached to a running editor.

For Markdown rendering or Tree-sitter failures, check compatibility among the editor, plugin branch, parser and configuration API. A plugin being installed or loaded does not prove its parser or language server is active in a representative buffer.

## Zellij

A valid KDL config does not prove the live plugin UI works. Compare the active config link and session state, then isolate a custom layout from global `load_plugins`; a `default_tab_template` may inject plugin panes into every tab, and background plugins may not appear as ordinary panes. Start a separate session with a built-in layout to isolate the custom layout; do not kill existing sessions without consent because pane state may be lost.

A remote WASM URL ending in `latest` can retain stale cached content when the URL stays unchanged. Pin a release URL or use a fixed-hash managed file; a changed URL is also a different plugin permission identity. Layout and plugin changes may require a new session after deployment.

If a status plugin flashes pane frames, isolate its frame-toggle option from the global frame setting rather than discarding the user's layout. A locally observed combination does not prove either option fails in isolation.

## Neovim investigation sequence

1. Check `readlink -f ~/.config/nvim` and
   `readlink -f ~/.local/share/nvim/lazy/lazy.nvim`, then run
   `nvim --headless '+qa'`. Run `:checkhealth vim.deprecated` and inspect the
   stack trace rather than attributing warnings to the loader. Lazy's spec
   notices are a separate source:

   ```sh
   nvim --headless +'lua local n=require("lazy.core.config").spec.notifs; print("lazy spec notices", #n); for _,x in ipairs(n) do print(x.level, x.msg, x.file or "") end' '+qa'
   ```

2. For unexpected LSPs, open a representative file and inspect attached
   clients, plus `~/.local/state/nvim/lsp.log`:

   ```sh
   nvim --headless /path/to/example.md \
     +'sleep 2' \
     +'lua local out={}; for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do table.insert(out,c.name) end; table.sort(out); print("clients="..table.concat(out,","))' \
     '+qa'
   ```

   `configs/neovim/lua/lsp/init.lua` passes the same explicit
   `mason_server_names` list to `ensure_installed` and `automatic_enable`.
   This avoids silently attaching unrelated installed servers. Restart the
   editor or stop already-attached clients after changing the config.
3. The Markdown stack is wired through lazy specs in
   `configs/neovim/lua/cfg/lazy.lua`, `core/obsidian.lua` and
   `ui/render-markdown.lua`; check plugin load, the intended Markdown LSP
   attachment and active Tree-sitter parsing in a Markdown buffer. The
   `nvim-treesitter` main branch in `ui/treesitter.lua` uses
   `require("nvim-treesitter").install(...)` and a `FileType` autocmd calling
   `vim.treesitter.start`, not the older `nvim-treesitter.configs` API.
   Stale parsers from an old plugin checkout can shadow installed parsers.
4. `nix/modules/neovim.nix` manages the entire config directory as an
   out-of-store symlink and supplies the package. Enabling Home Manager's
   `programs.neovim` can generate `nvim/init.lua` inside that symlink and
   conflict; adding another Neovim provider can also collide at `bin/nvim`.
   Check the resolved symlink and package providers before changing ownership.

## Zellij investigation sequence

1. Inspect `nix/modules/zellij.nix`, `configs/zellij/config.kdl` and
   `configs/zellij/layouts/*.kdl`, the live symlink, `zellij --version`, and
   `zellij setup --check`. Search for `default_tab_template`, plugin panes,
   `load_plugins`, and remote WASM URLs.
2. Compare `zellij list-sessions`, `zellij action list-tabs`, and
   `zellij action list-panes` with the current session's
   `~/.cache/zellij/*/session_info/*/session-layout.kdl` and
   `session-metadata.kdl`. Metadata can expose plugin and suppressed panes
   omitted from the concise pane list.
3. Isolate the custom layout in a separate session:

   ```sh
   zellij --new-session-with-layout default --session zj-default-layout-test
   ```

   If the built-in layout works, inspect the custom template's injected status
   pane; if not, investigate global background plugins. Check logs correlated
   with the reproduction, not just startup warnings.
4. For suspected stale remote WASM, compare cached files with release asset
   checksums, pin the URL to a release, and account for the new permission
   identity. For frame flicker, test the status plugin's
   `hide_frame_for_single_pane` separately from global `pane_frames`; do not
   infer a universal regression from one combination. Deploy the intended
   config and use a fresh session for a live check without destroying existing
   sessions.

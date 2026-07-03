# Neovim Mason LSP Auto-enable After Plugin Updates

## Context

In this dotfiles repo, the Neovim config uses `vim.lsp.config()` plus `mason-lspconfig.nvim`. After updating lazy-managed plugins, `mason-lspconfig.nvim` may default to automatically enabling every installed Mason LSP via `vim.lsp.enable()`.

That can silently attach servers that are installed but not intentionally configured in `configs/neovim/lua/lsp/init.lua`.

## Symptom

While editing markdown/wiki files, Neovim's LSP log may be spammed with messages like:

```text
"VAULT Lock is good"
"FILES Lock is good"
```

The log path is typically:

```text
~/.local/state/nvim/lsp.log
```

The messages can appear as `[ERROR]` log lines because they are emitted through Neovim's LSP log path, even when the server text itself sounds informational.

## Root cause pattern

- `markdown-oxide` and/or `marksman` are installed under Mason.
- `mason-lspconfig.nvim` auto-enables installed servers by default.
- A markdown/wiki buffer attaches those servers even though they are not in the user's explicit `server_names` list.

A quick probe from the repo can confirm attached clients:

```bash
nvim --headless '/home/swe/wikis/project-kairos/project-kairos/Logs/2026-06-25.md' \
  +'sleep 2' \
  +'lua local out={}; for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do table.insert(out, c.name) end; table.sort(out); print("clients="..table.concat(out,","))' \
  '+qa' 2>&1
```

Before the fix, this may show:

```text
clients=markdown_oxide,marksman
```

## Durable fix pattern

Constrain Mason auto-enable to the same explicit list used for intentional server setup:

```lua
mason_lspconfig.setup({
  ensure_installed = mason_server_names,
  automatic_enable = mason_server_names,
})
```

This keeps Mason's installer behavior while preventing unrelated installed servers from attaching to buffers.

## Verification

1. `nvim --headless '+qa' 2>&1` exits cleanly.
2. Open a representative markdown/wiki file headlessly and print clients; expected output for this repo is no markdown LSP clients unless one has been intentionally added to `server_names`.
3. Check the tail of `~/.local/state/nvim/lsp.log` for new `VAULT Lock is good` / `FILES Lock is good` lines after the verification open.

## Live-session cleanup

If the user already has Neovim open, the config change does not stop currently attached clients. Tell them to restart Neovim or run:

```vim
:LspStop markdown_oxide
:LspStop marksman
```

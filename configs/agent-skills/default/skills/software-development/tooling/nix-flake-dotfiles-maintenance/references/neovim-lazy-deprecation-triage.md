# Neovim lazy.nvim Deprecation Triage

Use this when the user reports many deprecation notices after updating `lazy.nvim` in the dotfiles-managed Neovim config.

## Key lesson

Deprecation notices can appear to come from lazy.nvim because lazy is the loader in the stack trace, while the deprecated API is actually in the plugin config that lazy loaded. Do not assume `lazy.nvim` is stale just because the warning appears during lazy startup.

## Triage sequence

1. Confirm the live config target and lazy version:
   - `readlink -f ~/.config/nvim`
   - `readlink -f ~/.local/share/nvim/lazy/lazy.nvim`
   - `git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse --short HEAD`
   - `git -C ~/.local/share/nvim/lazy/lazy.nvim ls-remote origin refs/heads/main refs/heads/stable`
2. Run a clean startup probe:
   - `nvim --headless '+qa' 2>&1`
3. If deprecation warnings remain, capture the authoritative source:
   - `nvim --headless '+checkhealth vim.deprecated' '+noautocmd write! /tmp/nvim-deprecated-health' '+qa' 2>&1`
   - Read `/tmp/nvim-deprecated-health` for stack traces.
4. Check lazy's own spec warnings separately:
   - `nvim --headless +'lua local n=require("lazy.core.config").spec.notifs; print("lazy spec notices", #n); for _,x in ipairs(n) do print(x.level, x.msg, x.file or "") end' '+qa' 2>&1`

## Durable fixes from the session

For Neovim 0.12+ LSP deprecations in `configs/neovim/lua/lsp/init.lua`:

- Replace `vim.lsp.set_log_level("error")` with `vim.lsp.log.set_level("error")`, optionally keeping a fallback for older Neovim.
- Replace `vim.lsp.with(handler, opts)` with an explicit wrapper that merges `handler_config` and passes it to the handler.
- Ensure signature help wraps `vim.lsp.handlers.signature_help`, not the hover handler.

Example wrapper:

```lua
local border = { border = "shadow" }
local function with_lsp_window_options(handler)
  return function(err, result, ctx, handler_config)
    handler_config = vim.tbl_deep_extend("force", {}, border, handler_config or {})
    return handler(err, result, ctx, handler_config)
  end
end
vim.lsp.handlers["textDocument/signatureHelp"] = with_lsp_window_options(vim.lsp.handlers.signature_help)
vim.lsp.handlers["textDocument/hover"] = with_lsp_window_options(vim.lsp.handlers.hover)
```

## Verification

- `nvim --headless '+qa' 2>&1` should be silent and exit 0.
- `:checkhealth vim.deprecated` should report `OK No deprecated functions detected`.
- Lazy spec notices should report `lazy spec notices 0`.
- Stage only the intended Neovim Lua config file; leave unrelated `pkglock.json` changes untouched unless the user asked to commit/update plugin locks.

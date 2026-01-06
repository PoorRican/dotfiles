--[[ init.lua ]]

-- LEADER
-- These keybindings need to be defined before the first /
-- is called; otherwise, it will default to "\"
vim.g.mapleader = ","
vim.g.localleader = "\\"

-- IMPORTS (vars, opts, keys are kept, plugins managed by lazy.nvim)
require('vars')      -- Variables
require('opts')      -- Options
require('keys')      -- Keymaps

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable", -- Use the latest stable release
    lazyrepo,
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim with your plugin configurations from lua/lazy-config.lua
require("lazy").setup(require("lazy-config"), {
  checker = {
    enabled = true,
    notify = true,
  },
  change_detection = {
    enabled = true,
    notify = true,
  },
})

vim.cmd.colorscheme("sourcerer")

-- █▓▒░ Setup VimWiki ░▒▓█  
-- This can be moved to the vimwiki plugin config in lazy-config.lua if preferred
vim.cmd([[
let g:vimwiki_list = [{'path': '~/vimwiki/',
                     \ 'syntax': 'markdown', 'ext': '.md'}]

" augroup pencil
"   autocmd!
"   autocmd FileType markdown,mkd,vimwiki call pencil#init({'wrap': 'soft'})
"   autocmd FileType txt        call pencil#init({'textwidth': 74})
" augroup END
]])

-- LSP Diagnostics Options Setup 
-- This diagnostic setup can remain here or be integrated into LSP plugin configs in lazy-config.lua
local sign = function(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = ''
  })
end

sign({name = 'DiagnosticSignError', text = ''})
sign({name = 'DiagnosticSignWarn', text = ''})
sign({name = 'DiagnosticSignHint', text = ''})
sign({name = 'DiagnosticSignInfo', text = ''})

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = true,
    underline = true,
    severity_sort = false,
    float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})

vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])

-- Auto-save configuration
vim.cmd([[
autocmd InsertLeave,FocusLost * silent! update
autocmd FocusLost * silent! wall
]])

-- Individual plugin setups (like nvim-cmp, treesitter, nvim-tree, lualine, todo-comments, mason, lspconfig, rust-tools)
-- are now expected to be handled within their respective configurations in lua/lazy-config.lua
-- (either via `opts = {}` or a `config = function() ... end` block).

-- Setup copilot (can be moved to copilot plugin config in lazy-config.lua if you add it as a plugin)
vim.g.copilot_no_tab_map = true

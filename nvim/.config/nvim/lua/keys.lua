--[[ keys.lua ]]
local map = vim.api.nvim_set_keymap

map('n', ';', ':', {})                  -- command button w/o shift

map('n', '<Leader><Space>', [[:Startify<CR>]], {})
map('n', '<Leader>tr', [[:NvimTreeToggle<CR>]], {})
map('n', '<Leader>ww', [[:VimwikiIndex<CR>]], {})

-- █▓▒░ Tab commands
map('n', '<Leader>tt', [[:tabnew<CR>]], {})
map('n', '<Leader>tn', [[:tabnext<CR>]], {})
map('n', '<Leader>to', [[:tabprev<CR>]], {})
map('n', '<Leader>tc', [[:tabclose<CR>]], {})


-- [[ Dev Stuff ]]

map('n', '<Leader>tg', [[:TagbarToggle<CR>]], {})
map('n', '<Leader>td', [[:TodoTelescope<cr>]], {})
map('n', '<leader>ff', [[:Telescope git_files<cr>]], {})
map('n', '<leader>fg', [[:Telescope live_grep<cr>]], {})
map('n', '<leader>fd', [[:Telescope lsp_definitions<cr>]], {}) 
map('n', '<leader>fs', [[:Telescope lsp_dynamic_workspace_symbols<cr>]], {})
map('n', '<leader>fr', [[:Telescope lsp_references<cr>]], {})
map('n', '<leader>fu', [[:Telescope lsp_incoming_calls<cr>]], {})
map('n', '<leader>fb', [[:Telescope buffers<cr>]], {})
map('n', '<leader>fh', [[:Telescope help_tags<cr>]], {})

map('v', '<Leader>ca', [[:RustCodeAction]], {})
map('n', '<Leader>ca', [[:RustCodeAction]], {})

-- █▓▒░ Git integrations

map('n', '<Leader>gv', [[:GV<CR>]], {})  -- show git branch log

-- █▓▒░ Vimspector
map('n', "<F9>",  ":call vimspector#Launch()<cr>", {})
map('n', "<F5>",  ":call vimspector#StepOver()<cr>", {})
map('n', "<F8>",  ":call vimspector#Reset()<cr>", {})
map('n', "<F10>", ":call vimspector#StepInto()<cr>", {})
map('n', "<F11>", ":call vimspector#StepOver()<cr>", {})
map('n', "<F12>", ":call vimspector#StepOut()<cr>", {})

map('n', "<Leader>db", ":call vimspector#ToggleBreakpoint()<cr>", {})
map('n', "<Leader>dw", ":call vimspector#AddWatch()<cr>", {})
map('n', "<Leader>de", ":call vimspector#Evaluate()<cr>", {})

-- █▓▒░ Code Rice
-- pneumonic "comment block"
map('n', '<Leader>cb', [[i<C-v> █▓▒░ <Esc>]], {})
map('n', '<Leader>cB', [[i<C-v> █▓▒░  ░▒▓█ <Esc>]], {})

-- █▓▒░ FloatTerm configuration
map('n', "<Leader>.i", ":FloatermNew --name=floaterm --height=0.8 --width=0.7 --autoclose=2 zsh <CR> ", {})
map('n', "<Leader>.", ":FloatermToggle floaterm<CR>", {})
map('n', "<C-t>", ":FloatermToggle floaterm<CR>", {})
map('n', "<Leader>.n", ":FloatermNext<CR>", {})
map('n', "<Leader>.p", ":FloatermPrev<CR>", {})
-- Terminal mode mappings for FloatTerm
map('t', "<C-t>", "<C-\\><C-n>:FloatermToggle floaterm<CR>", {})
map('t', "<Esc>", "<C-\\><C-n>", {})
map('t', "<C-h>", "<C-\\><C-n><C-w>h", {})
map('t', "<C-j>", "<C-\\><C-n><C-w>j", {})
map('t', "<C-k>", "<C-\\><C-n><C-w>k", {})
map('t', "<C-l>", "<C-\\><C-n><C-w>l", {})

-- █▓▒░ Trouble configuration (v3 syntax)
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xs", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  {silent = true, noremap = true}
)

-- █▓▒░ Claude Code
vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })

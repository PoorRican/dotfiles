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
map('n', '<leader>ft', [[:Telescope tags<cr>]], {})
-- map('n', '<leader>fb', [[:Telescope buffers<cr>]], {})
map('n', '<leader>fh', [[:Telescope help_tags<cr>]], {})

map('v', '<Leader>ca', [[:RustCodeAction]], {})
map('n', '<Leader>ca', [[:RustCodeAction]], {})

-- █▓▒░ Git integrations

map('n', '<Leader>gv', [[:GV<CR>]], {})
-- map('n', 'ff', [[:Telescope find_files]], {})

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
map('n', "<Leader>.n", ":FloatermNext<CR>", {})
map('n', "<Leader>.p", ":FloatermPrev<CR>", {})
map('t', "<Esc>", "<C-\\><C-n>:q<CR>", {})

-- █▓▒░ Trouble configuration
map("n", "<leader>xx", "<cmd>TroubleToggle<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>",
  {silent = true, noremap = true}
)
map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",
  {silent = true, noremap = true}
)
map("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
  {silent = true, noremap = true}
)

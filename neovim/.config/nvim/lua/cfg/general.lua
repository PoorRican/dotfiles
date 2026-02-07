--                                     ██
--                                    ░░
--  ███████   █████   ██████  ██    ██ ██ ██████████
-- ░░██░░░██ ██░░░██ ██░░░░██░██   ░██░██░░██░░██░░██
--  ░██  ░██░███████░██   ░██░░██ ░██ ░██ ░██ ░██ ░██
--  ░██  ░██░██░░░░ ░██   ░██ ░░████  ░██ ░██ ░██ ░██
--  ███  ░██░░██████░░██████   ░░██   ░██ ███ ░██ ░██
-- ░░░   ░░  ░░░░░░  ░░░░░░     ░░    ░░ ░░░  ░░  ░░
--
--  ▓▓▓▓▓▓▓▓▓▓
-- ░▓ author ▓ xero <x@xero.style>
-- ░▓ code   ▓ https://code.x-e.ro/dotfiles
-- ░▓ mirror ▓ https://git.io/.files
-- ░▓▓▓▓▓▓▓▓▓▓
-- ░░░░░░░░░░
--
-- security
vim.opt.modelines = 0

-- set leader key to comma
vim.g.mapleader = ","

-- hide buffers, not close them
vim.opt.hidden = true

-- maintain undo history between sessions
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- scroll bounds
vim.o.scrolloff = 13

-- faster CursorHold for LSP document highlight
vim.opt.updatetime = 300

-- ipad scrolling
vim.opt.mouse = "a"

-- fuzzy find
vim.opt.path:append("**")
-- lazy file name tab completion
vim.opt.wildmode = "list:longest,list:full"
vim.opt.wildmenu = true
vim.opt.wildignorecase = true
-- ignore files vim doesnt use
vim.opt.wildignore:append(".git,.hg,.svn")
vim.opt.wildignore:append(".aux,*.out,*.toc")
vim.opt.wildignore:append(".o,*.obj,*.exe,*.dll,*.manifest,*.rbc,*.class")
vim.opt.wildignore:append(".ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp")
vim.opt.wildignore:append(".avi,*.divx,*.mp4,*.webm,*.mov,*.m2ts,*.mkv,*.vob,*.mpg,*.mpeg")
vim.opt.wildignore:append(".mp3,*.oga,*.ogg,*.wav,*.flac")
vim.opt.wildignore:append(".eot,*.otf,*.ttf,*.woff")
vim.opt.wildignore:append(".doc,*.pdf,*.cbr,*.cbz")
vim.opt.wildignore:append(".zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz,*.kgb")
vim.opt.wildignore:append(".swp,.lock,.DS_Store,._*")
vim.opt.wildignore:append(".,..")

-- case insensitive search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true

-- make backspace behave in a sane manner
vim.opt.backspace = "indent,eol,start"

-- searching
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.inccommand = "split"

-- use indents of 2
vim.opt.shiftwidth = 2

-- tabs are tabs
vim.opt.expandtab = false

-- an indentation every 2 columns
vim.opt.tabstop = 2

-- let backspace delete indent
vim.opt.softtabstop = 2

-- enable auto indentation
vim.opt.autoindent = true

-- treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- auto-reload files changed externally (for external coding agents)
vim.opt.autoread = true
vim.cmd([[autocmd FocusGained,BufEnter * checktime]])

-- auto-save on focus lost / insert leave
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
	pattern = "*",
	command = "silent! update",
})

vim.api.nvim_create_autocmd("FocusLost", {
	pattern = "*",
	command = "silent! wall",
})

-- show diagnostics on cursor hold
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focusable = false })
	end,
})

-- redirect focus to editor window after closing tool windows
local tool_filetypes = {
	["neo-tree"] = true,
	["Trouble"] = true,
	["trouble"] = true,
	["dap-repl"] = true,
	["dapui_scopes"] = true,
	["dapui_breakpoints"] = true,
	["dapui_stacks"] = true,
	["dapui_watches"] = true,
	["dapui_console"] = true,
	["qf"] = true,
	["help"] = true,
}

local function is_tool_window(winid)
	if not vim.api.nvim_win_is_valid(winid) then return false end
	local bufnr = vim.api.nvim_win_get_buf(winid)
	local ft = vim.bo[bufnr].filetype
	return tool_filetypes[ft] or false
end

local function find_editor_window()
	for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(winid) and not is_tool_window(winid) then
			local config = vim.api.nvim_win_get_config(winid)
			if config.relative == "" then
				return winid
			end
		end
	end
	return nil
end

local tool_window_just_closed = false

vim.api.nvim_create_autocmd("WinClosed", {
	callback = function(args)
		local closed_win = tonumber(args.match)
		if closed_win and is_tool_window(closed_win) then
			tool_window_just_closed = true
			vim.defer_fn(function() tool_window_just_closed = false end, 50)
		end
	end,
})

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if not tool_window_just_closed then return end
		tool_window_just_closed = false

		vim.defer_fn(function()
			local current_win = vim.api.nvim_get_current_win()
			if is_tool_window(current_win) then
				local editor_win = find_editor_window()
				if editor_win then
					vim.api.nvim_set_current_win(editor_win)
				end
			end
		end, 10)
	end,
})

-- colorcolumn: dynamic line width per filetype
local colorcolumn_filetypes = {
	python = "79",
	markdown = "80",
	typescript = "100",
	typescriptreact = "100",
	javascript = "100",
	javascriptreact = "100",
	rust = "100",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		local cc = colorcolumn_filetypes[vim.bo.filetype] or ""
		vim.wo.colorcolumn = cc
	end,
})

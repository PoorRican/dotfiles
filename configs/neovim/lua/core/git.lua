return {
	{
		"tpope/vim-fugitive",
		init = function()
			local r = require("utils.remaps")

			r.map_virtual({ "<leader>G", group = "git" })
			r.noremap("n", "<leader>Gh", "<cmd>Flog<cr>", "history in new tab")
			r.noremap("n", "<leader>Gg", "<cmd>Flog -all<cr>", "history graph in new tab")
		end,
		cmd = {
			"G",
			"GBrowse",
			"GDelete",
			"GMove",
			"GRemove",
			"GRename",
			"GUnlink",
			"Gcd",
			"Gclog",
			"Gdiffsplit",
			"Gdrop",
			"Gedit",
			"Ggrep",
			"Ghdiffsplit",
			"Git",
			"Glcd",
			"Glgrep",
			"Gllog",
			"Gpedit",
			"Gread",
			"Gsplit",
			"Gtabedit",
			"Gvdiffsplit",
			"Gvsplit",
			"Gwq",
			"Gwrite",
		},
	},
	{
		"rbong/vim-flog",
		dependencies = {
			"tpope/vim-fugitive",
		},
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "floggraph",
				callback = function(args)
					vim.keymap.set("n", "<CR>", function()
						local existing_wins = {}
						for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
							existing_wins[winid] = true
						end

						vim.cmd("vertical belowright Flogsplitcommit")

						for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
							if not existing_wins[winid] then
								vim.api.nvim_set_current_win(winid)
								return
							end
						end
					end, { buffer = args.buf, silent = true, desc = "open Flog commit in focused side pane" })
				end,
			})
		end,
		cmd = {
			"Flog",
			"Flogsplit",
			"Floggit",
		},
	},
}

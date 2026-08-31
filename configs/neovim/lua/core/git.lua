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
		cmd = {
			"Flog",
			"Flogsplit",
			"Floggit",
		},
	},
}

-- Upstream shells out with the LSP-provided URL; keep every link as one argv value.
local function openHoverLink(self)
	if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
		return
	end

	local node = vim.treesitter.get_node()
	if not node or node:type() ~= "inline" then
		return
	end

	local text = vim.treesitter.get_node_text(node, self.bufnr)
	local link = text:match("%]%((.-)%)")
	if not link then
		return
	end

	if link:match("^file://") then
		vim.api.nvim_cmd({ cmd = "edit", args = { vim.uri_to_fname(link) } }, {})
		return
	end

	local _, err = vim.ui.open(link)
	if err then
		vim.notify(err, vim.log.levels.ERROR, { title = "Lspsaga hover" })
	end
end

return {
	"nvimdev/lspsaga.nvim",
	cmd = "Lspsaga",
	event = "LspAttach",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		ui = {
			border = "shadow",
		},
		finder = {
			default = "def+ref+imp",
			layout = "float",
			keys = {
				shuttle = "<Tab>",
				toggle_or_open = "<CR>",
				vsplit = "<C-v>",
				split = "<C-x>",
				tabe = "<C-t>",
				quit = "q",
				close = "<Esc>",
			},
		},
		definition = {
			save_pos = true,
		},
		diagnostic = {
			auto_preview = true,
			diagnostic_only_current = false,
		},
		code_action = {
			show_server_name = true,
		},
		lightbulb = {
			enable = true,
			sign = true,
			virtual_text = false,
		},
		symbol_in_winbar = {
			enable = true,
			separator = " > ",
			show_file = true,
			folder_level = 1,
		},
		outline = {
			win_width = 35,
			auto_preview = true,
			close_after_jump = false,
		},
		implement = {
			enable = true,
			sign = true,
			virtual_text = true,
		},
		beacon = {
			enable = false,
		},
	},
	config = function(_, opts)
		require("lspsaga").setup(opts)
		require("lspsaga.hover").open_link = openHoverLink
	end,
}

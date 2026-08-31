local r = require("utils.remaps")
local vim = vim
local X = {}

local function LspToggle()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
		print(" lsp toggled")
end

local function generate_buf_keymapper(bufnr)
	return function(type, input, output, description, extraOptions)
		local options = { buffer = bufnr }
		if extraOptions ~= nil then
			options = vim.tbl_deep_extend("force", options, extraOptions)
		end
		r.noremap(type, input, output, description, options)
	end
end

function X.set_default_on_buffer(client, bufnr)
	local buf_set_keymap = generate_buf_keymapper(bufnr)

	local function buf_set_option(o, v)
		vim.api.nvim_set_option_value(o, v, { buf = bufnr })
	end

	local cap = client.server_capabilities

	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	if cap.definitionProvider then
		buf_set_keymap("n", "<leader>lD", "<cmd>Lspsaga goto_definition<CR>", "go to definition")
		buf_set_keymap("n", "<leader>ld", "<cmd>Lspsaga peek_definition<CR>", "peek definition")
	end

	local finder_methods = {
		"textDocument/definition",
		"textDocument/references",
		"textDocument/implementation",
	}
	if vim.iter(finder_methods):any(function(method)
		return client:supports_method(method, bufnr)
	end) then
		buf_set_keymap("n", "<leader>lF", "<cmd>Lspsaga finder def+ref+imp<CR>", "LSP finder")
	end

	if cap.declarationProvider then
		buf_set_keymap("n", "gD", vim.lsp.buf.declaration, "go to declaration")
	end

	if cap.implementationProvider then
		buf_set_keymap("n", "gi", "<cmd>Lspsaga finder imp<CR>", "find implementations")
		buf_set_keymap("n", "gri", "<cmd>Lspsaga finder imp<CR>", "find implementations")
	end

	if cap.referencesProvider then
		buf_set_keymap("n", "<leader>/r", "<cmd>Lspsaga finder ref<CR>", "find references")
		buf_set_keymap("n", "grr", "<cmd>Lspsaga finder ref<CR>", "find references")
	end

	if cap.typeDefinitionProvider then
		buf_set_keymap("n", "<leader>/t", "<cmd>Lspsaga peek_type_definition<CR>", "peek type definition")
		buf_set_keymap("n", "grt", "<cmd>Lspsaga peek_type_definition<CR>", "peek type definition")
	end

	if cap.hoverProvider then
		buf_set_keymap("n", "K", "<cmd>Lspsaga hover_doc<CR>", "hover docs")
		buf_set_keymap("n", "<leader>lh", "<cmd>Lspsaga hover_doc<CR>", "hover docs")
	end

	if cap.codeActionProvider then
		buf_set_keymap({ "n", "v" }, "<leader>ra", "<cmd>Lspsaga code_action<CR>", "code actions")
		buf_set_keymap({ "n", "v" }, "gra", "<cmd>Lspsaga code_action<CR>", "code actions")
		r.map_virtual({ "<leader>r", group = "refactor", icon = { icon = " ", hl = "Constant" } })
	end

	if cap.renameProvider then
		buf_set_keymap("n", "<leader>rr", "<cmd>Lspsaga rename<CR>", "rename")
		buf_set_keymap("n", "grn", "<cmd>Lspsaga rename<CR>", "rename")
	end

	if cap.documentSymbolProvider then
		buf_set_keymap("n", "<leader>lo", "<cmd>Lspsaga outline<CR>", "document outline")
		buf_set_keymap("n", "gO", "<cmd>Lspsaga outline<CR>", "document outline")
	end

	buf_set_keymap("n", "<leader>lI", ":LspInfo<CR>", "lsp info")
	buf_set_keymap("n", "<leader>ls", vim.lsp.buf.signature_help, "show signature")
	buf_set_keymap("n", "<leader>lE", "<cmd>Lspsaga show_line_diagnostics<CR>", "show line diagnostics")
	buf_set_keymap("n", "<leader>lb", "<cmd>Lspsaga show_buf_diagnostics<CR>", "show buffer diagnostics")
	buf_set_keymap("n", "<leader>lw", "<cmd>Lspsaga show_workspace_diagnostics<CR>", "show workspace diagnostics")
	buf_set_keymap("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", "previous diagnostic")
	buf_set_keymap("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", "next diagnostic")
	buf_set_keymap("n", "<leader>ll", function() require("lsp_lines").toggle() end, "virtual lines")
	buf_set_keymap("n", "<leader>lt", function() LspToggle() end, "toggle lsp")
	r.map_virtual({
		{ "<leader>l", group = "lsp", icon = { icon = "", hl = "Constant" } },
		{ "<leader>lI", group = "lsp Info", icon = { icon = "", hl = "Constant" } },
		{ "<leader>ls", group = "show signature", icon = { icon = "󰅨", hl = "Constant" } },
		{ "<leader>lE", group = "show line diagnostics", icon = { icon = "󰅰", hl = "Constant" } },
		{ "<leader>lb", group = "show buffer diagnostics", icon = { icon = "󰅰", hl = "Constant" } },
		{ "<leader>lw", group = "show workspace diagnostics", icon = { icon = "󰅰", hl = "Constant" } },
		{ "<leader>lD", group = "go to definition", icon = { icon = "", hl = "Constant" } },
		{ "<leader>ld", group = "peek definition", icon = { icon = "", hl = "Constant" } },
		{ "<leader>lF", group = "LSP finder", icon = { icon = "", hl = "Constant" } },
		{ "<leader>lh", group = "hover docs", icon = { icon = "󰋖", hl = "Constant" } },
		{ "<leader>ll", group = "virtual lines", icon = { icon = "󱞽", hl = "Constant" } },
		{ "<leader>/r", group = "find references", icon = { icon = "", hl = "Constant" } },
		{ "<leader>/t", group = "peek type definition", icon = { icon = "", hl = "Constant" } },
		{ "<leader>ra", group = "code actions", icon = { icon = "", hl = "Constant" } },
		{ "<leader>rr", group = "rename", icon = { icon = "", hl = "Constant" } },
		{ "<leader>lo", group = "document outline", icon = { icon = "", hl = "Constant" } },
		{ "<leader>lt", group = "toggle lsp", icon = { icon = "", hl = "Constant" } },
		{ "gi", group = "find implementations", icon = { icon = "", hl = "Constant" } },
	})
end

return X

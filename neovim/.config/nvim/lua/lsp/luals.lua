return function(on_attach)
	return {
		on_attach = function(client, bufnr)
			on_attach(client, bufnr)
			client.server_capabilities.document_formatting = false
			client.server_capabilities.document_range_formatting = false
		end,
		settings = {
			Lua = {
				hint = {
					enable = true
				},
				runtime = {
					version = "LuaJIT",
				},
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
          -- TODO: lsp in neovim might work better with this uncommented
          --
					-- make the server aware of Neovim runtime files
					-- library = {
					-- 	[vim.fn.expand('$VIMRUNTIME/lua')] = true,
					-- 	[vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
					-- },
					checkThirdParty = false
				},
				-- do not send telemetry data containing a randomized but unique identifier
				telemetry = { enable = false },
			},
		},
	}
end

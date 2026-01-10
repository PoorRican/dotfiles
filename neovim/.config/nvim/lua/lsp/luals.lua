return {
	settings = {
		Lua = {
			hint = {
				enable = true,
			},
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
}

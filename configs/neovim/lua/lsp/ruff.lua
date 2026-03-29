return {
	root_markers = { "uv.lock", "pyproject.toml", ".git" },
	settings = {
		ruff = {
			interpreter = (function()
				local cwd = vim.fn.getcwd()
				if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
					return { cwd .. "/.venv/bin/python" }
				elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
					return { cwd .. "/venv/bin/python" }
				end
				return { vim.fn.exepath("python3") or "python3" }
			end)(),
		},
	},
}

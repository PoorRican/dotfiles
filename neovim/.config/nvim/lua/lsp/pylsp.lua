return {
	root_markers = { "uv.lock", "pyproject.toml", ".git" },
	settings = {
		pylsp = {
			plugins = {
				-- Disable pylsp's built-in linters (ruff handles this)
				pycodestyle = { enabled = false },
				mccabe = { enabled = false },
				pyflakes = { enabled = false },
				pylint = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },

				-- Enable mypy
				pylsp_mypy = {
					enabled = true,
					live_mode = true,  -- Run on save
					strict = false,
				},
			},
		},
		python = {
			pythonPath = (function()
				local cwd = vim.fn.getcwd()
				if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
					return cwd .. "/.venv/bin/python"
				elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
					return cwd .. "/venv/bin/python"
				end
				return vim.fn.exepath("python3") or "python3"
			end)(),
		},
	},
}

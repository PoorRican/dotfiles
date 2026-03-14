-- Enable custom mypy command for venv support
vim.env.PYLSP_MYPY_ALLOW_DANGEROUS_CODE_EXECUTION = "1"

local f = require("utils.functions")

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

				-- Enable mypy from project venv (respects project config)
				pylsp_mypy = {
					enabled = true,
					live_mode = true,
					dmypy = false,
					report_progress = true,
					mypy_command = f.get_mypy_command(),
				},
			},
		},
		python = {
			pythonPath = f.get_python_path(),
		},
	},
}

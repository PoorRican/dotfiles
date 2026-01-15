-- Enable custom mypy command for venv support
vim.env.PYLSP_MYPY_ALLOW_DANGEROUS_CODE_EXECUTION = "1"

local function get_python_path()
	local cwd = vim.fn.getcwd()
	if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
		return cwd .. "/.venv/bin/python"
	elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
		return cwd .. "/venv/bin/python"
	end
	return vim.fn.exepath("python3") or "python3"
end

local function get_mypy_command()
	local cwd = vim.fn.getcwd()
	if vim.fn.executable(cwd .. "/.venv/bin/mypy") == 1 then
		return { cwd .. "/.venv/bin/mypy" }
	elseif vim.fn.executable(cwd .. "/venv/bin/mypy") == 1 then
		return { cwd .. "/venv/bin/mypy" }
	end
	return { "mypy" }
end

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

				-- Enable mypy from project venv
				pylsp_mypy = {
					enabled = true,
					live_mode = true,
					dmypy = false,
					report_progress = true,
					strict = true,
					mypy_command = get_mypy_command(),
				},
			},
		},
		python = {
			pythonPath = get_python_path(),
		},
	},
}

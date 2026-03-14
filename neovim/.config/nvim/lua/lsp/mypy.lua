local f = require("utils.functions")

return {
	root_markers = { "pyproject.toml", ".git" },
	settings = {
		python = {
			pythonPath = f.get_python_path(),
		},
	},
}

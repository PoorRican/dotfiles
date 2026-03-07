local vim = vim
local X = {}

X.cmd = function(name, command, desc)
	vim.api.nvim_create_user_command(name, command, desc)
end

X.autocmd = function(evt, opts)
	vim.api.nvim_create_autocmd(evt, opts)
end

X.find_venv_bin = function(start_dir)
	local path = start_dir
	while path ~= "/" and path ~= "" do
		if vim.fn.isdirectory(path .. "/.venv") == 1 then
			return path .. "/.venv/bin"
		elseif vim.fn.isdirectory(path .. "/venv") == 1 then
			return path .. "/venv/bin"
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
	return nil
end

X.get_python_path = function()
	local buf_path = vim.api.nvim_buf_get_name(0)
	local start_dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
	local venv_bin = X.find_venv_bin(start_dir)
	if venv_bin then
		local python = venv_bin .. "/python"
		if vim.fn.executable(python) == 1 then
			return python
		end
	end
	return vim.fn.exepath("python3") or "python3"
end

X.get_mypy_command = function()
	local buf_path = vim.api.nvim_buf_get_name(0)
	local start_dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
	local venv_bin = X.find_venv_bin(start_dir)
	if venv_bin then
		local mypy = venv_bin .. "/mypy"
		if vim.fn.executable(mypy) == 1 then
			return { mypy }
		end
	end
	return { "mypy" }
end

return X

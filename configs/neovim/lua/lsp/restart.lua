local X = {}

local function client_names(clients)
	local names = {}
	for _, client in ipairs(clients) do
		names[client.name] = true
	end
	return vim.tbl_keys(names)
end

function X.restart(options)
	options = options or {}
	local bufnr = options.bufnr or vim.api.nvim_get_current_buf()
	local filter = { bufnr = bufnr }
	if options.name and options.name ~= "" then
		filter.name = options.name
	end

	local clients = vim.lsp.get_clients(filter)
	if #clients == 0 then
		vim.notify("No matching LSP clients to restart", vim.log.levels.WARN)
		return 0
	end

	local names = client_names(clients)
	table.sort(names)
	vim.notify("Restarting LSP: " .. table.concat(names, ", "))

	local restarted = 0
	for _, client in ipairs(clients) do
		if type(client._restart) == "function" then
			client:_restart(false)
			restarted = restarted + 1
		else
			vim.notify("Cannot restart LSP client: " .. client.name, vim.log.levels.ERROR)
		end
	end
	return restarted
end

function X.setup()
	if vim.fn.exists(":LspRestart") == 2 then return end

	vim.api.nvim_create_user_command("LspRestart", function(args)
		X.restart({
			bufnr = 0,
			name = args.args ~= "" and args.args or nil,
		})
	end, {
		desc = "Restart LSP clients attached to the current buffer",
		nargs = "?",
		complete = function(arg_lead)
			local names = client_names(vim.lsp.get_clients({ bufnr = 0 }))
			table.sort(names)
			return vim.tbl_filter(function(name)
				return vim.startswith(name, arg_lead)
			end, names)
		end,
	})
end

return X

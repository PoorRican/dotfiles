local function parse_rust_analyzer_toml()
	local root = vim.fn.getcwd()
	local toml_path = root .. "/rust-analyzer.toml"
	local handle = io.open(toml_path, "r")
	if not handle then
		return {}
	end
	local content = handle:read("*a")
	handle:close()

	local settings = {}
	local current_section
	for line in content:gmatch("[^\r\n]+") do
		local section = line:match("^%[(.+)%]$")
		if section then
			current_section = section
			settings[current_section] = settings[current_section] or {}
		else
			local key, value = line:match("^%s*(%w+)%s*=%s*(.+)$")
			if key and value and current_section then
				value = value:gsub('^"', ""):gsub('"$', "")
				if value == "true" then
					value = true
				elseif value == "false" then
					value = false
				elseif value:match("^%d+$") then
					value = tonumber(value)
				elseif value:match("^%[.+%]$") then
					local array = {}
					for item in value:gmatch('%[([^%]]+)%]') do
						for v in item:gmatch('"([^"]+)"') do
							table.insert(array, v)
						end
					end
					value = array
				end
				settings[current_section][key] = value
			end
		end
	end
	return settings
end

return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", ".git" },
	single_file_support = true,
	settings = {
		["rust-analyzer"] = parse_rust_analyzer_toml(),
	},
}

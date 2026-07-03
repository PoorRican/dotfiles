local function workspace(name, path)
	local expanded = vim.fn.expand(path)
	if vim.fn.isdirectory(expanded) == 1 then
		return { name = name, path = expanded }
	end
end

local function workspaces()
	local items = {}
	local env_path = vim.env.OBSIDIAN_VAULT_PATH
	if env_path and env_path ~= "" then
		table.insert(items, { name = "env", path = vim.fn.expand(env_path) })
	end

	for _, candidate in ipairs({
		{ "kairos", "~/wikis/kairos" },
		{ "memex", "~/wikis/memex" },
		{ "project-kairos", "~/wikis/project-kairos/project-kairos" },
		{ "project-wiki", "~/wikis/wiki/project-wiki" },
		{ "default", "~/Documents/Obsidian Vault" },
	}) do
		local item = workspace(candidate[1], candidate[2])
		if item then
			table.insert(items, item)
		end
	end

	return items
end

return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = { "Obsidian" },
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cond = function()
		return #workspaces() > 0
	end,
	opts = function()
		return {
			legacy_commands = false,
			workspaces = workspaces(),
		}
	end,
}

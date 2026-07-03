local parsers = {
	"bash",
	"c",
	"cmake",
	"cpp",
	"css",
	"dockerfile",
	"go",
	"graphql",
	"hcl",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"php",
	"python",
	"query",
	"regex",
	"ruby",
	"rust",
	"scss",
	"sql",
	"terraform",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

local function install_parsers()
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if ok then
		treesitter.install(parsers):wait(300000)
	end
end

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	dependencies = {
		{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
	},
	build = install_parsers,
	config = function()
		local r = require("utils.remaps")
		require("nvim-treesitter").setup()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
			move = {
				set_jumps = true,
			},
		})

		local function start_treesitter(args)
			pcall(vim.treesitter.start, args.buf)
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
			callback = start_treesitter,
		})
		if vim.bo.filetype ~= "" then
			start_treesitter({ buf = vim.api.nvim_get_current_buf() })
		end

		r.noremap("n", "<leader>rt", function()
			vim.treesitter.inspect_tree({ command = "botleft60vnew" })
		end, "treesitter playground")

		r.noremap("n", "<C-e>", function()
			local result = vim.treesitter.get_captures_at_cursor(0)
			print(vim.inspect(result))
		end, "show treesitter capture group")

		local select = require("nvim-treesitter-textobjects.select")
		local move = require("nvim-treesitter-textobjects.move")
		local swap = require("nvim-treesitter-textobjects.swap")

		local textobjects = {
			{ "af", "@function.outer", "outer function" },
			{ "if", "@function.inner", "inner function" },
			{ "ac", "@class.outer", "outer class" },
			{ "ic", "@class.inner", "inner class" },
			{ "aa", "@parameter.outer", "outer argument" },
			{ "ia", "@parameter.inner", "inner argument" },
			{ "ai", "@conditional.outer", "outer conditional" },
			{ "ii", "@conditional.inner", "inner conditional" },
			{ "al", "@loop.outer", "outer loop" },
			{ "il", "@loop.inner", "inner loop" },
			{ "ab", "@block.outer", "outer block" },
			{ "ib", "@block.inner", "inner block" },
		}
		for _, item in ipairs(textobjects) do
			r.noremap({ "x", "o" }, item[1], function()
				select.select_textobject(item[2], "textobjects")
			end, item[3])
		end

		r.noremap("n", "<leader>rp", function()
			swap.swap_next("@parameter.inner", "textobjects")
		end, "swap parameter next")
		r.noremap("n", "<leader>rP", function()
			swap.swap_previous("@parameter.inner", "textobjects")
		end, "swap parameter prev")

		local motions = {
			{ "]f", move.goto_next_start, "@function.outer", "next function start" },
			{ "]c", move.goto_next_start, "@class.outer", "next class start" },
			{ "]a", move.goto_next_start, "@parameter.inner", "next argument start" },
			{ "]F", move.goto_next_end, "@function.outer", "next function end" },
			{ "]C", move.goto_next_end, "@class.outer", "next class end" },
			{ "[f", move.goto_previous_start, "@function.outer", "previous function start" },
			{ "[c", move.goto_previous_start, "@class.outer", "previous class start" },
			{ "[a", move.goto_previous_start, "@parameter.inner", "previous argument start" },
			{ "[F", move.goto_previous_end, "@function.outer", "previous function end" },
			{ "[C", move.goto_previous_end, "@class.outer", "previous class end" },
		}
		for _, item in ipairs(motions) do
			r.noremap({ "n", "x", "o" }, item[1], function()
				item[2](item[3], "textobjects")
			end, item[4])
		end

		r.map_virtual({
			{ "<leader>r", group = "refactor", icon = { icon = " ", hl = "Constant" } },
			{ "<leader>rt", group = "treesitter playground", icon = { icon = " ", hl = "Constant" } },
			{ "<leader>rp", group = "swap parameter next", icon = { icon = "󰯍 ", hl = "Constant" } },
			{ "<leader>rP", group = "swap parameter prev", icon = { icon = "󰯍 ", hl = "Constant" } },
		})
	end,
}

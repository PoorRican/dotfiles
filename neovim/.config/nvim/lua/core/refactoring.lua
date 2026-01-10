return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{ "<leader>re", function() require("refactoring").refactor("Extract Function") end, mode = "x", desc = "Extract function" },
		{ "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, mode = "x", desc = "Extract variable" },
		{ "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "x" }, desc = "Inline variable" },
		{ "<leader>rb", function() require("refactoring").refactor("Extract Block") end, desc = "Extract block" },
		{ "<leader>rB", function() require("refactoring").refactor("Extract Block To File") end, desc = "Extract block to file" },
		{ "<leader>rp", function() require("refactoring").debug.printf({ below = false }) end, desc = "Debug print" },
		{ "<leader>rc", function() require("refactoring").debug.cleanup({}) end, desc = "Debug cleanup" },
	},
	opts = {
		prompt_func_return_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		prompt_func_param_type = {
			go = false,
			java = false,
			cpp = false,
			c = false,
			h = false,
			hpp = false,
			cxx = false,
		},
		printf_statements = {},
		print_var_statements = {},
		show_success_message = false,
	},
}

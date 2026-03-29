return {
	"mfussenegger/nvim-lint",
	event = "BufWritePost",
	config = function()
		local lint = require("lint")
		local config_path = vim.fn.stdpath("config") .. "/linter-configs/markdownlint.json"

		lint.linters_by_ft = {
			markdown = { "markdownlint" },
		}

		lint.linters.markdownlint.args = {
			"--config", config_path,
			"--stdin",
		}

		vim.api.nvim_create_autocmd("BufWritePost", {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}

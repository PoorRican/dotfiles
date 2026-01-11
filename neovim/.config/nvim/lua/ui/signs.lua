return {
	"lewis6991/gitsigns.nvim",
	config = function()
		local gitsigns = require("gitsigns")
		local r = require("utils.remaps")

		gitsigns.setup({
			signs = {
				add          = { text = '▐' },
				change       = { text = '▐' },
				delete       = { text = '▐' },
				topdelete    = { text = '▐' },
				changedelete = { text = '▐' },
				untracked    = { text = '▐' },
			},
			signcolumn     = true,  -- toggle with `:Gitsigns toggle_signs`
			linehl         = false, -- toggle with `:Gitsigns toggle_linehl`
			numhl          = false, -- toggle with `:Gitsigns toggle_nunhl`
			word_diff      = false, -- toggle with `:Gitsigns toggle_word_diff`
			sign_priority  = 9,
			watch_gitdir   = {
				interval     = 1000,
			},
			attach_to_untracked = false,
		})

		-- Hunk navigation
		r.noremap("n", "]c", function()
			if vim.wo.diff then return "]c" end
			vim.schedule(function() gitsigns.next_hunk() end)
			return "<Ignore>"
		end, "next hunk", { expr = true })

		r.noremap("n", "[c", function()
			if vim.wo.diff then return "[c" end
			vim.schedule(function() gitsigns.prev_hunk() end)
			return "<Ignore>"
		end, "prev hunk", { expr = true })

		-- Hunk actions
		r.noremap("n", "<leader>hs", gitsigns.stage_hunk, "stage hunk")
		r.noremap("v", "<leader>hs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "stage selected")
		r.noremap("n", "<leader>hr", gitsigns.reset_hunk, "reset hunk")
		r.noremap("v", "<leader>hr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "reset selected")
		r.noremap("n", "<leader>hp", gitsigns.preview_hunk, "preview hunk")
		r.noremap("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end, "blame line")
		r.noremap("n", "<leader>hu", gitsigns.undo_stage_hunk, "undo stage hunk")

		-- Buffer actions
		r.noremap("n", "<leader>hS", gitsigns.stage_buffer, "stage buffer")
		r.noremap("n", "<leader>hR", gitsigns.reset_buffer, "reset buffer")

		-- Quick commit current file
		r.noremap("n", "<leader>hc", function()
			vim.cmd("silent! Git add %")
			vim.cmd("Git commit")
		end, "commit file")

		-- Git operations
		r.noremap("n", "<leader>hd", gitsigns.diffthis, "diff this")
		r.noremap("n", "<leader>hD", function() gitsigns.diffthis("~") end, "diff HEAD")
		r.noremap("n", "<leader>tb", gitsigns.toggle_current_line_blame, "toggle blame")
		r.noremap("n", "<leader>td", gitsigns.toggle_deleted, "toggle deleted")

		-- which-key groups
		r.map_virtual({
			{ "<leader>h", group = "git hunks" },
			{ "<leader>t", group = "toggle" },
		})
	end,
	event = { "BufReadPre", "BufNewFile" },
}

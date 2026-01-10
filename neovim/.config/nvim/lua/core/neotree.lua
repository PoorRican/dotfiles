local r = require("utils.remaps")
return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "explorer" },
		{ "<leader>E", "<cmd>Neotree reveal<cr>", desc = "reveal in explorer" },
	},
	opts = {
		close_if_last_window = true,
		popup_border_style = "single",
		enable_git_status = true,
		enable_diagnostics = true,
		sort_case_insensitive = true,
		default_component_configs = {
			indent = {
				with_expanders = true,
				expander_collapsed = "",
				expander_expanded = "",
			},
			icon = {
				folder_closed = "",
				folder_open = "",
				folder_empty = "",
			},
			git_status = {
				symbols = {
					added = "",
					modified = "",
					deleted = "",
					renamed = "",
					untracked = "",
					ignored = "",
					unstaged = "",
					staged = "",
					conflict = "",
				},
			},
		},
		window = {
			position = "left",
			width = 35,
			mappings = {
				["<space>"] = "none",
				["<cr>"] = "open",
				["o"] = "open",
				["s"] = "open_split",
				["v"] = "open_vsplit",
				["t"] = "open_tabnew",
				["a"] = { "add", config = { show_path = "relative" } },
				["d"] = "delete",
				["r"] = "rename",
				["y"] = "copy_to_clipboard",
				["x"] = "cut_to_clipboard",
				["p"] = "paste_from_clipboard",
				["q"] = "close_window",
				["R"] = "refresh",
				["?"] = "show_help",
			},
		},
		filesystem = {
			filtered_items = {
				visible = false,
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_by_name = { ".git", "node_modules", "__pycache__", ".venv" },
			},
			follow_current_file = { enabled = true },
			use_libuv_file_watcher = true,
		},
		buffers = { follow_current_file = { enabled = true } },
		git_status = { window = { position = "float" } },
	},
	init = function()
		r.map_virtual({ "<leader>e", desc = "explorer", icon = { icon = "", hl = "Directory" } })
		r.map_virtual({ "<leader>E", desc = "reveal in explorer", icon = { icon = "", hl = "Directory" } })
		-- open on startup (alongside dashboard)
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				vim.schedule(function()
					local ft = vim.bo.filetype
					local bufname = vim.api.nvim_buf_get_name(0)
					-- Skip for git commit/rebase/merge messages
					if ft == "gitcommit" or ft == "gitrebase"
						or bufname:match("COMMIT_EDITMSG$")
						or bufname:match("MERGE_MSG$")
						or bufname:match("git%-rebase%-todo$") then
						return
					end
					require("neo-tree.command").execute({ action = "show" })
				end)
			end,
		})
	end,
}

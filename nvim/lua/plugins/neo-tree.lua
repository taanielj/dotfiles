return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set(
			"n",
			"<leader>e",
			":Neotree filesystem reveal left toggle=true<CR>",
			{ desc = "Show Files", silent = true }
		)

		require("neo-tree").setup({
			source_selector = {
				statusline = true,
			},
			enable_git_status = true,
			enable_diagnostics = true,
			use_libuv_file_watcher = true,
			follow_current_file = {
				enabled = true,
			},
			default_component_configs = {
				git_status = {
					symbols = {
						-- Change type
						added = "✚", -- NOTE: you can set any of these to an empty string to not show them
						deleted = "✖",
						modified = "",
						renamed = "➜",
						-- Status type
						untracked = "",
						ignored = "◌",
						unstaged = "",
						staged = "✓",
						conflict = "",
					},
					window = {
						position = "float",
						mappings = {
							["A"] = "git_add_all",
							["gu"] = "git_unstage_file",
							["ga"] = "git_add_file",
							["gr"] = "git_revert_file",
							["gc"] = "git_commit",
							["gA"] = "git_amend",
							["gP"] = "git_push",
							["gp"] = "git_pull",
							["g?"] = "git_help",
						},
					},
					align = "right",
				},
			},
			window = {
				mappings = {
					["<space>"] = "none",
				},
			},
			filesystem = {
				group_empty_dirs = true, -- Group empty directories together
				scan_mode = "deep",
				use_libuv_file_watcher = true,
				filtered_items = {
					hide_gitignored = false,
					always_show = {
						".gitignore",
						".github",
					},
					always_show_by_pattern = {
						".env*",
					},
				},
			},
		})
	end,
}

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>e", ":Neotree filesystem reveal left toggle=true<CR>", { desc = "Show Files", silent = true })

		require("neo-tree").setup({
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
                    align = "right",
				},
			},
		})
	end,
}

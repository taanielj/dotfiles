return {
	"catppuccin/nvim",
	lazy = false,
	name = "catpuccin",
	priority = 1000,
    term_colors = false,
	config = function()
		vim.cmd.colorscheme("catppuccin")
		require("catppuccin").setup({
			background = {
				light = "latte",
				dark = "moccha",
			},
			integrations = {
				neotree = {
					enabled = true,
					show_root = true,
					transparent_panel = false,
				},
			},
		})
	end,
}

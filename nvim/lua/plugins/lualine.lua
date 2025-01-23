return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"kyazdani42/nvim-web-devicons", -- Ensure correct dependency for icons
	},
	config = function()
		require("lualine").setup({
			options = {
				theme = "catppuccin",
                globalstatus = true,
			},
			sections = {
				lualine_a = {
					{
						"mode",
						icons_enabled = true, -- Enable icons
						icon = { "", align = "left" }, -- Icon to the right
						separator = nil, -- Optional: Define separator if needed
					},
				},
			},
		})
		vim.o.laststatus = 3 -- Ensure statusline is always shown
	end,
}

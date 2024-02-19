return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				theme = "dracula",
			},
			sections = {
				lualine_a = { "", "mode" },
			},
		})
		vim.o.laststatus = 3
	end,
}

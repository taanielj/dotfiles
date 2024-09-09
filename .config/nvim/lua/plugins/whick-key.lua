return {
	"folke/which-key.nvim",
	dependencies = {
		"echasnovski/mini.icons",
	},
	event = "VeryLazy",
	config = function()
		vim.o.timeoutlen = 200
		local wk = require("which-key")

		wk.add({
			{ "<leader>b", group = "Buffer" },
			{ "<leader>b s", "Sort" },
			{ "<leader>b m", "Move" },
			{ "<leader>l", "LSP" },
			{ "<leader>f", group = "Find" },
			{ "<leader>f h", "Hidden" },
			{ "<leader>g", "Git" },
		})

		require("which-key").setup()
	end,
}

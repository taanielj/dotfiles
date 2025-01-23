return {
	"kdheepak/lazygit.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		vim.keymap.set("n", "<leader>gg", function()
			vim.cmd("LazyGit")

			-- Add an autocommand to refresh Neo-tree after LazyGit closes
			vim.api.nvim_create_autocmd("TermClose", {
				pattern = "*lazygit*",
				callback = function()
					local state = require("neo-tree.sources.manager").get_state("filesystem")
					require("neo-tree.sources.filesystem.commands").refresh(state)
				end,
			})
		end, { desc = "LazyGit" })
	end,
}

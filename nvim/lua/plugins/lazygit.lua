return {
	"kdheepak/lazygit.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("telescope").load_extension("lazygit")
		vim.keymap.set("n", "<leader>gg", function()
			vim.cmd("LazyGit")
		end, { desc = "LazyGit" })
		vim.g.lazygit_on_exit_callback = function()
			local state = require("neo-tree.sources.manager").get_state("filesystem")
			require("neo-tree.sources.filesystem.commands").refresh(state)
		end
	end,
}

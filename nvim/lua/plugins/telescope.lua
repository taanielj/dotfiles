return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")
			-- search current buffer
			vim.keymap.set("n", "<leader> ", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
			-- live grep current buffer
			vim.keymap.set("n", "<leader>f ", function()
				builtin.live_grep({ search_dirs = { vim.fn.expand("%:p") } })
			end, { desc = "Live Grep Buffer" })
			-- find (in) hidden files:
			vim.keymap.set("n", "<leader>fhf", function()
				builtin.find_files({ hidden = true, no_ignore = true })
			end, { desc = "Find Hidden Files" })
			vim.keymap.set("n", "<leader>fhb", function()
				builtin.buffers({ show_all_buffers = true, no_ignore = true })
			end, { desc = "Find Hidden Buffers" })
			vim.keymap.set("n", "<leader>fhg", function()
				builtin.live_grep({ hidden = true, no_ignore = true })
			end, { desc = "Hidden Live Grep" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}

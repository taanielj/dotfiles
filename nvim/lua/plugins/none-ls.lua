return {

	{
		"nvimtools/none-ls.nvim",
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.prettier,
					null_ls.builtins.formatting.black.with({
                        extra_args = { "--line-length", "120" },
                    }),
					null_ls.builtins.formatting.isort,
				},
			})
            local function call_formatter()
                vim.lsp.buf.format({timeout_ms = 5000})
            end
			vim.keymap.set("n", "<leader>m", call_formatter, { desc = "Format" })
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		dependencies = { "nvimtools/none-ls.nvim", "williamboman/mason.nvim" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = nil,
				automatic_installation = true,
			})
		end,
	},
}

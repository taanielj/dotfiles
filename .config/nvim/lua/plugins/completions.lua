return {
	{
		"github/copilot.vim",
		config = function()
			local function SuggestOneWord()
				local suggestion = vim.fn["copilot#Accept"]("")
				local bar = vim.fn["copilot#TextQueuedForInsertion"]()
				return vim.fn.split(bar, [[[ .]\zs]])[1]
			end
			local map = vim.keymap.set
			map("i", "<C-l>", SuggestOneWord, { expr = true, remap = false })
		end,
	},
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
	},
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()
			cmp.setup({
				snippet = {
					-- REQUIRED - you must specify a snippet engine
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
				}, {}),
			})
		end,
	},
}

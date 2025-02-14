return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- lua
					"lua_ls",
					"pyright",
					"dockerls",
					"terraformls",
					"sqlls",
					"html",
					"eslint",
					"cssls",
					"bashls",
					"gopls",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local lspconfig = require("lspconfig")
			---- Language server configurations:
			-- lua language server
			lspconfig.lua_ls.setup({ capabilities = capabilities })
			-- python language server
			lspconfig.pyright.setup({
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "off",
							reportUnusedFunction = "off",
						},
					},
				},
			})
			-- docker language server
			lspconfig.dockerls.setup({ capabilities = capabilities })
			-- html-lsp
			lspconfig.html.setup({
				capabilities = capabilities,
				configurationSection = { "html", "css", "javascript" },
				embeddedLanguages = {
					css = true,
					javascript = true,
				},
				provideFormatter = true,
			})
			-- eslint language server
			lspconfig.eslint.setup({ capabilities = capabilities })
			-- css language server
			lspconfig.cssls.setup({ capabilities = capabilities })
			-- terraform language server
			lspconfig.terraformls.setup({ capabilities = capabilities })
			-- sql language server
			lspconfig.sqlls.setup({ capabilities = capabilities })
			-- bash language server
			lspconfig.bashls.setup({
				filetypes = { "sh", "zsh", "bash" },
				capabilities = capabilities,
			})
			-- go language server
			lspconfig.gopls.setup({ capabilities = capabilities })

			---- Keymaps:
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show hover doc" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
			vim.keymap.set("n", "<leader>la", ":lua vim.lsp.buf.code_action()<CR>", { desc = "Code Action" })
			vim.keymap.set("n", "<leader>lr", ":lua vim.lsp.buf.rename()<CR>", { desc = "Rename Symbol" })
			vim.keymap.set("n", "<leader>lf", ":lua vim.lsp.buf.references()<CR>", { desc = "Find References" })
			vim.keymap.set("n", "<leader>le", ":lua vim.diagnostic.open_float()<CR>", { desc = "Show Diagnostics" })
			vim.keymap.set("n", "<leader>ln", ":lua vim.diagnostic.goto_next()<CR>", { desc = "Next Diagnostic" })
			vim.keymap.set("n", "<leader>lp", ":lua vim.diagnostic.goto_prev()<CR>", { desc = "Previous Diagnostic" })
			vim.keymap.set("n", "<leader>lq", ":Telescope diagnostics<CR>", { desc = "Search Diagnostics" })

			vim.cmd.anoremenu("Popup.Definition <Cmd>:lua vim.lsp.buf.definition()<CR>")

			vim.fn.sign_define("DiagnosticSignError", { text = "󰅙" , texthl = "DiagnosticSignError" })
			vim.fn.sign_define("DiagnosticSignInfo", { text = "󰋼" , texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define("DiagnosticSignHint" , { text = "󰌵", textxl = "DiagnosticSignHint"})
            vim.fn.sign_define("DiagnosticSignWarn", { text = "󰅙" , texthl = "DiagnosticSignWarn" })
			vim.diagnostic.config({
				signs = {
					[vim.diagnostic.severity.ERROR] = "󰅙",
					[vim.diagnostic.severity.INFO] = "󰋼",
					[vim.diagnostic.severity.HINT] = "󰌵",
					[vim.diagnostic.severity.WARN] = "󰅙",
				},
			})
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		dependencies = { "nvimtools/none-ls.nvim", "williamboman/mason.nvim" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = {
					"stylua",
					"black",
					--"sqlfmt",
					"shfmt",
				},
				automatic_installation = true,
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		config = function()
			require("lint").linters_by_ft = {
				go = { "golangci-lint" },
			}
		end,
	},
	{
		"rshkarin/mason-nvim-lint",
		config = function()
			require("mason-nvim-lint").setup({
				ensure_installed = { "golangci-lint" },
				ignore_install = { "custom-linter" },
				quiet_mode = true,
			})
		end,
	},
}

return {
    {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "williamboman/mason.nvim", opts = {} },
            { "j-hui/fidget.nvim",       opt = true },
            "hrsh7th/cmp-nvim-lsp",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        opts = {
            servers = {
                sqlls = { mason = false }, -- disable mason for this server
            },
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc, mode)
                        mode = mode or "n"
                        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    ---- Keymaps:
                    map("gd", require("telescope.builtin").lsp_definitions, "Go to definition")
                    map("gi", require("telescope.builtin").lsp_implementations, "Go to implementation")
                    map("gr", require("telescope.builtin").lsp_references, "Find references")
                    map("gs", require("telescope.builtin").lsp_document_symbols, "Document symbols")
                    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Go to type definition")
                    map("<leader>lw", require("telescope.builtin").lsp_workspace_symbols, "Workspace symbols")
                    map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
                    map("<leader>le", vim.diagnostic.open_float, "Show diagnostics")
                    map("<leader>ln", vim.diagnostic.goto_next, "Next diagnostic")
                    map("<leader>lp", vim.diagnostic.goto_prev, "Previous diagnostic")
                    map("<leader>lq", require("telescope.builtin").diagnostics, "Search diagnostics")
                    map("gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" })

                    -- map("K", vim.lsp.buf.hover, "Show hover doc")

                    -- Highlight references on cursor hold
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                        vim.opt.updatetime = 300
                        local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = function()
                                vim.lsp.buf.document_highlight()
                            end,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
                            end,
                        })
                    end

                    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                        map("<leader>lh", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                        end, "[T]oggle Inlay [H]ints")
                    end
                end,
            })

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
            capabilities = vim.tbl_deep_extend("force", capabilities, {
                textDocument = {
                    textDocument = {
                        foldingRange = {
                            dynamicRegistration = true,
                            lineFoldingOnly = true,
                        },
                    },
                },
            })
            local lspconfig = require("lspconfig")
            ---- Language server configurations:
            -- lua language server
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                settings = {
                    Lua = {
                        format_on_save = false,
                        formatter = nil,
                        runtime = { version = "LuaJIT" },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                "${3rd}/luv/library",
                                unpack(vim.api.nvim_get_runtime_file("", true)),
                            },
                        },
                        completion = {
                            callSnippet = "Replace",
                        },
                    },
                },
            })
            -- python language server
            lspconfig.pyright.setup({
                capabilities = capabilities,
                settings = {
                    python = {
                        analysis = {
                            -- See here for defaults:
                            -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#diagnostic-settings-defaults
                            typeCheckingMode = "standard", -- "off" | "basic" | "standard" | "strict"
                            diagnosticSeverityOverrides = {
                                reportUnusedFunction = "information",
                                reportUnusedExpression = "information", -- maybe in correct?
                            },
                        },
                    },
                },
            })
            lspconfig.html.setup({
                capabilities = capabilities,
                configurationSection = { "html", "css", "javascript" },
                embeddedLanguages = {
                    css = true,
                    javascript = true,
                },
                provideFormatter = true,
            })
            lspconfig.marksman.setup({ capabilities = capabilities })
            lspconfig.dockerls.setup({ capabilities = capabilities })
            lspconfig.gopls.setup({ capabilities = capabilities })
            lspconfig.eslint.setup({ capabilities = capabilities })
            lspconfig.cssls.setup({ capabilities = capabilities })
            lspconfig.terraformls.setup({ capabilities = capabilities })
            lspconfig.bashls.setup({
                filetypes = { "sh", "zsh", "bash" },
                capabilities = capabilities,
            })
            -- lspconfig.hydra_lsp.setup({
            --     capabilities = capabilities,
            --     filetypes = { "yaml", "yml" },
            -- })
            require("mason-lspconfig").setup({
                automatic_installation = true,
                ensure_installed = {
                    "lua_ls",
                    "pyright",
                    -- "ruff",
                    "dockerls",
                    "terraformls",
                    "html",
                    "eslint",
                    "cssls",
                    "bashls",
                    "gopls",
                    -- "hydra_lsp",
                    "marksman",
                },
            })
            vim.cmd.anoremenu("Popup.Definition <Cmd>:lua vim.lsp.buf.definition()<CR>")

            vim.diagnostic.config({
                signs = {
                    [vim.diagnostic.severity.ERROR] = { "󰅙", texthl = "DiagnosticSignError" },
                    [vim.diagnostic.severity.INFO] = { "󰋼", texthl = "DiagnosticSignInfo" },
                    [vim.diagnostic.severity.HINT] = { "󰌵", texthl = "DiagnosticSignHint" },
                    [vim.diagnostic.severity.WARN] = { "󰅙", texthl = "DiagnosticSignWarn" },
                },
                virtual_text = {
                    prefix = "●",
                    source = "if_many",
                    format = function(diagnostic)
                        return string.format("%s %s", diagnostic.source, diagnostic.message)
                    end,
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
                    "isort",
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
            local lint = require("lint")
            lint.linters_by_ft = {
                -- go = { "golangcilint" },
                -- dockerfile = { "hadolint" },
                -- python = { "ruff" },
            }
            -- local golangcilint = lint.linters.golangcilint
            -- golangcilint.args = {
            --     "run",
            --     "--output.json.path=stdout",
            --     "--issues-exit-code=0",
            --     "--show-stats=false",
            --     "--output.text.print-issued-lines=false",
            --     "--output.text.print-linter-name=false",
            --     function()
            --         return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
            --     end,
            -- }

            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group = lint_augroup,
                callback = function()
                    if vim.opt_local.modifiable:get() then
                        lint.try_lint()
                    end
                end,
            })
        end,
    },
    {
        "rshkarin/mason-nvim-lint",
        config = function()
            require("mason-nvim-lint").setup({
                automatic_installation = true,
                ensure_installed = {
                    -- "golangci-lint",
                    -- "hadolint",
                    -- "ruff",
                },
                ignore_install = { "custom-linter" },
                quiet_mode = true,
            })
        end,
    },
}

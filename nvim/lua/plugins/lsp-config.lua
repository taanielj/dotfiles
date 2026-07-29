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
            { "j-hui/fidget.nvim", opt = true },
            "hrsh7th/cmp-nvim-lsp",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc, mode)
                        mode = mode or "n"
                        vim.keymap.set(mode, keys, func, { buf = event.buf, desc = "LSP: " .. desc })
                    end

                    local builtin = require("telescope.builtin")
                    map("gd", builtin.lsp_definitions, "Go to definition")
                    map("gi", builtin.lsp_implementations, "Go to implementation")
                    map("gr", builtin.lsp_references, "Find references")
                    map("gs", builtin.lsp_document_symbols, "Document symbols")
                    map("<leader>D", builtin.lsp_type_definitions, "Go to type definition")
                    map("<leader>lw", builtin.lsp_workspace_symbols, "Workspace symbols")
                    map("<leader>lq", builtin.diagnostics, "Search diagnostics")
                    map("gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
                    map("<leader>le", vim.diagnostic.open_float, "Show diagnostics")
                    map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" })
                    map("<leader>ln", function()
                        vim.diagnostic.jump({ count = 1, float = true })
                    end, "Next diagnostic")
                    map("<leader>lp", function()
                        vim.diagnostic.jump({ count = -1, float = true })
                    end, "Previous diagnostic")

                    local client = vim.lsp.get_client_by_id(event.data.client_id)

                    -- Highlight references on cursor hold
                    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                        vim.opt.updatetime = 300
                        local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
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

                    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                        map("<leader>lh", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                        end, "Toggle inlay hints")
                    end
                end,
            })

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
            -- nvim-ufo folding: Neovim doesn't advertise foldingRange by default.
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = true,
                lineFoldingOnly = true,
            }

            -- Server configs. Empty table = defaults; capabilities are applied below.
            local servers = {
                lua_ls = {
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
                            completion = { callSnippet = "Replace" },
                        },
                    },
                },
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "standard",
                                diagnosticSeverityOverrides = {
                                    reportUnusedFunction = "information",
                                    reportUnusedExpression = "information",
                                },
                            },
                        },
                    },
                },
                ruff = {}, -- Python linter (formatting via black + isort in none-ls)
                html = {
                    configurationSection = { "html", "css", "javascript" },
                    embeddedLanguages = { css = true, javascript = true },
                    provideFormatter = true,
                },
                bashls = { filetypes = { "sh", "zsh", "bash" } },
                -- ruby_lsp = {
                --     init_options = {
                --         addonSettings = {
                --             RubyLSPRails = { enablePendingMigrationsPrompt = false },
                --         },
                --     },
                -- },
                marksman = {}, -- Markdown
                dockerls = {}, -- Dockerfile
                gopls = {}, -- Go
                eslint = {}, -- JavaScript/TypeScript
                cssls = {}, -- CSS
                terraformls = {}, -- Terraform
            }

            for name, cfg in pairs(servers) do
                cfg.capabilities = cfg.capabilities or capabilities
                vim.lsp.config(name, cfg)
                vim.lsp.enable(name)
            end
            -- Scala; config comes from the nvim-metals plugin, not here.
            vim.lsp.enable("metals")

            -- Ensure every managed server plus Java is installed via mason.
            -- (metals is not available through mason-lspconfig.)
            local ensure_installed = vim.tbl_keys(servers)
            table.insert(ensure_installed, "jdtls")
            require("mason-lspconfig").setup({
                automatic_installation = true,
                ensure_installed = ensure_installed,
            })

            vim.cmd.anoremenu("Popup.Definition <Cmd>:lua vim.lsp.buf.definition()<CR>")

            vim.diagnostic.config({
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN] = " ",
                        [vim.diagnostic.severity.INFO] = "󰋼 ",
                        [vim.diagnostic.severity.HINT] = "󰌵 ",
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "",
                        [vim.diagnostic.severity.WARN] = "",
                        [vim.diagnostic.severity.HINT] = "",
                        [vim.diagnostic.severity.INFO] = "",
                    },
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
}

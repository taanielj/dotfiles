return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "williamboman/mason.nvim", opts = {} },
            {
                "j-hui/fidget.nvim",
                opts = {
                    progress = {
                        suppress_on_insert = true,
                        ignore_done_already = true,
                        ignore_empty_message = true,
                        ignore = { "pyright", "sonarlint.nvim", "ruff" },
                    },
                },
            },
            "hrsh7th/cmp-nvim-lsp",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            -- vim.lsp.buf.document_highlight() applies the reply without checking
            -- that the buffer still exists, which errors when it was wiped mid-request.
            local function highlight_references(ev)
                local method = vim.lsp.protocol.Methods.textDocument_documentHighlight
                vim.lsp.buf_request(
                    ev.buf,
                    method,
                    function(client) return vim.lsp.util.make_position_params(0, client.offset_encoding) end,
                    function(err, result, ctx)
                        local client = vim.lsp.get_client_by_id(ctx.client_id)
                        if err or not result or not client or not vim.api.nvim_buf_is_valid(ctx.bufnr) then
                            return
                        end
                        vim.lsp.util.buf_highlight_references(ctx.bufnr, result, client.offset_encoding)
                    end
                )
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
                callback = function(event)
                    local map = require("lib.keymap").buffer(event.buf, "LSP: ")

                    local function builtin(picker)
                        return function() require("telescope.builtin")[picker]() end
                    end
                    map("n", "gd", builtin("lsp_definitions"), "Go to definition")
                    map("n", "gi", builtin("lsp_implementations"), "Go to implementation")
                    map("n", "gr", builtin("lsp_references"), "Find references")
                    map("n", "gs", builtin("lsp_document_symbols"), "Document symbols")
                    map("n", "<leader>lt", builtin("lsp_type_definitions"), "Go to type definition")
                    map("n", "<leader>lw", builtin("lsp_workspace_symbols"), "Workspace symbols")
                    map("n", "<leader>lq", builtin("diagnostics"), "Search diagnostics")
                    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
                    map("n", "<leader>le", vim.diagnostic.open_float, "Show diagnostics")
                    map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
                    map(
                        "n",
                        "<leader>ln",
                        function() vim.diagnostic.jump({ count = 1, float = true }) end,
                        "Next diagnostic"
                    )
                    map(
                        "n",
                        "<leader>lp",
                        function() vim.diagnostic.jump({ count = -1, float = true }) end,
                        "Previous diagnostic"
                    )
                    map("n", "<leader>lD", vim.diagnostic.setqflist, "Workspace diagnostics")
                    map(
                        "n",
                        "<leader>lE",
                        function() vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR }) end,
                        "Workspace errors"
                    )
                    map(
                        "n",
                        "<leader>lW",
                        function() vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.WARN }) end,
                        "Workspace warnings"
                    )
                    map("n", "<leader>ld", vim.diagnostic.setloclist, "Buffer diagnostics")

                    local client = vim.lsp.get_client_by_id(event.data.client_id)

                    if client and client.name == "marksman" then
                        require("lsp.marksman_sync").attach(client)
                    end

                    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                        local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = highlight_references,
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
                        map(
                            "n",
                            "<leader>lh",
                            function()
                                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                            end,
                            "Toggle inlay hints"
                        )
                    end
                end,
            })

            local capabilities = require("lsp.capabilities").get()

            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            format_on_save = false,
                            formatter = nil,
                            runtime = { version = "LuaJIT" },
                            -- lazydev supplies the library, so lua_ls needs no
                            -- third-party workspace directories
                            workspace = { checkThirdParty = false },
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
                -- A project's ruff.toml or pyproject.toml wins; lineLength applies
                -- to projects without one.
                ruff = {
                    init_options = { settings = { configurationPreference = "filesystemFirst", lineLength = 120 } },
                },
                html = {},
                bashls = { filetypes = { "sh", "zsh", "bash" } },
                marksman = {},
                dockerls = {},
                gopls = {},
                eslint = {},
                cssls = {},
                terraformls = {},
            }

            for name, cfg in pairs(servers) do
                cfg.capabilities = cfg.capabilities or capabilities
                vim.lsp.config(name, cfg)
                vim.lsp.enable(name)
            end
            -- Scala; nvim-metals supplies the config.
            vim.lsp.enable("metals")

            -- ensure_installed has no metals: mason-lspconfig does not carry it.
            local ensure_installed = vim.tbl_keys(servers)
            table.insert(ensure_installed, "jdtls")
            -- automatic_enable stays on: it also enables installed servers with no
            -- entry above, such as jdtls and stylua
            require("mason-lspconfig").setup({ ensure_installed = ensure_installed })

            local icons = require("lib.icons")
            vim.diagnostic.config({
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = icons.error .. " ",
                        [vim.diagnostic.severity.WARN] = icons.warning .. " ",
                        [vim.diagnostic.severity.INFO] = icons.info .. " ",
                        [vim.diagnostic.severity.HINT] = icons.hint .. " ",
                    },
                },
                virtual_text = {
                    prefix = "●",
                    source = "if_many",
                    format = function(diagnostic) return string.format("%s %s", diagnostic.source, diagnostic.message) end,
                },
            })
        end,
    },
}

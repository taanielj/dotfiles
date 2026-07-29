return {
    {
        "nvimtools/none-ls.nvim",
        config = function()
            local null_ls = require("null-ls")
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            null_ls.setup({
                capabilities = capabilities,
                sources = {
                    -- Shell scripts
                    null_ls.builtins.formatting.shfmt.with({
                        filetypes = { "sh", "zsh", "bash" },
                    }),
                    -- Lua
                    null_ls.builtins.formatting.stylua.with({
                        lsp_fallback = false,
                    }),
                    -- JavaScript/TypeScript/HTML/CSS/JSON/YAML/Markdown
                    null_ls.builtins.formatting.prettier,
                    -- Python - code formatter
                    null_ls.builtins.formatting.black.with({
                        extra_args = { "--line-length", "120" },
                    }),
                    -- Python - import sorter
                    null_ls.builtins.formatting.isort.with({
                        extra_args = {
                            "--line-length",
                            "120",
                            "--profile",
                            "black",
                        },
                    }),
                    -- Protobuf
                    null_ls.builtins.formatting.buf,
                    -- SQL
                    null_ls.builtins.formatting.sqlfmt,
                    -- Ruby
                    -- null_ls.builtins.formatting.rubocop,
                    -- Makefile linter
                    null_ls.builtins.diagnostics.checkmake,
                },
            })

            local function call_formatter()
                vim.cmd("mkview")
                vim.lsp.buf.format({
                    timeout_ms = 5000,
                    filter = function(client)
                        return client.name ~= "ruff"
                    end,
                })
                vim.cmd("retab")
                vim.cmd("silent! loadview")
                vim.cmd("retab")
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("buffer-format-key", { clear = true }),
                callback = function(args)
                    if args.match ~= "neo-tree" and args.match ~= "neotree" then
                        vim.keymap.set("n", "<leader>m", call_formatter, {
                            buf = args.buf,
                            desc = "Format",
                        })
                    end
                end,
            })
        end,
    },
    {
        "jay-babu/mason-null-ls.nvim",
        dependencies = { "williamboman/mason.nvim" },
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            automatic_installation = true,
            ensure_installed = {
                "stylua", -- Lua
                "black", -- Python code formatter
                "isort", -- Python import sorter
                "shfmt", -- Shell
                "buf", -- Protobuf
                "checkmake", -- Makefile linter
                "sonarlint-language-server", -- SonarLint
            },
        },
    },
}

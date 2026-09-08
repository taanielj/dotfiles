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
                "shfmt", -- Shell
                "buf", -- Protobuf
                "checkmake", -- Makefile linter
                "sonarlint-language-server", -- SonarLint
            },
        },
    },
}

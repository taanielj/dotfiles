return {
    {
        "nvimtools/none-ls.nvim",
        config = function()
            local null_ls = require("null-ls")

            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.shfmt.with({
                        filetypes = { "sh", "zsh", "bash" },
                    }),
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.formatting.prettier,
                    null_ls.builtins.formatting.buf,
                    null_ls.builtins.formatting.sqlfmt,
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

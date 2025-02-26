return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require "null-ls"
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.shfmt.with({
                    filetypes = { "sh", "zsh", "bash" },
                }),
                null_ls.builtins.formatting.stylua.with({
                    lsp_fallback = false,
                }),
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.formatting.black.with({
                    extra_args = { "--line-length", "120" },
                }),
                null_ls.builtins.formatting.isort,
                null_ls.builtins.formatting.sqlfmt,
            },
        })
        local function call_formatter()
            vim.cmd("mkview")
            vim.lsp.buf.format({ timeout_ms = 5000 })
            vim.cmd("retab")
            vim.cmd("silent! loadview")
            vim.cmd("retab")
        end
        vim.keymap.set("n", "<leader>m", call_formatter, { desc = "Format" })
    end,
}

local prettier = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
    "css",
    "scss",
    "less",
    "html",
    "htmlangular",
    "handlebars",
    "json",
    "json5",
    "jsonc",
    "yaml",
    "markdown",
    "markdown.mdx",
    "graphql",
}

local formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    proto = { "buf" },
    sql = { "sqlfmt" },
    jinja = { "sqlfmt" },
}
for _, ft in ipairs(prettier) do
    formatters_by_ft[ft] = { "prettier" }
end

return {
    {
        -- Runs through lsp/format.lua; the LSP formats only where no tool is listed
        "stevearc/conform.nvim",
        cmd = "ConformInfo",
        opts = {
            formatters_by_ft = formatters_by_ft,
            default_format_opts = { lsp_format = "fallback" },
        },
    },
    {
        "mfussenegger/nvim-lint",
        ft = "make",
        config = function()
            require("lint").linters_by_ft = { make = { "checkmake" } }
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
                group = vim.api.nvim_create_augroup("lint", { clear = true }),
                callback = function() require("lint").try_lint() end,
            })
        end,
    },
}

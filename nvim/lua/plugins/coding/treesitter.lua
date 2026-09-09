return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    ---@class TSConfig
    opts = {
        ensure_installed = {
            "astro",
            "bash",
            "zsh",
            "c",
            "css",
            "diff",
            "go",
            "gomod",
            "gowork",
            "gosum",
            "graphql",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "json5",
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "python",
            "query",
            "regex",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "yaml",
        },
    },
    config = function(_, opts)
        local treesitter = require("nvim-treesitter")

        if opts.ensure_installed and #opts.ensure_installed > 0 then
            treesitter.install(opts.ensure_installed)
        end

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(event)
                local parser = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
                if not parser or not require("nvim-treesitter.parsers")[parser] then
                    return
                end

                if pcall(vim.treesitter.start, event.buf, parser) then
                    return
                end

                treesitter.install({ parser }):await(function()
                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(event.buf) then
                            pcall(vim.treesitter.start, event.buf, parser)
                        end
                    end)
                end)
            end,
        })
    end,
}

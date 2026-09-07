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
            -- "ruby",
        },
    },
    config = function(_, opts)
        if opts.ensure_installed and #opts.ensure_installed > 0 then
            require("nvim-treesitter").install(opts.ensure_installed)
            for _, parser in ipairs(opts.ensure_installed) do
                local filetypes = parser -- In this case, parser is the filetype/language name
                vim.treesitter.language.register(parser, filetypes)

                vim.api.nvim_create_autocmd({ "FileType" }, {
                    pattern = filetypes,
                    callback = function(event)
                        pcall(vim.treesitter.start, event.buf, parser)
                    end,
                })
            end
        end

        vim.api.nvim_create_autocmd({ "BufRead" }, {
            callback = function(event)
                local bufnr = event.buf
                local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

                if filetype == "" then
                    return
                end

                -- Filetypes in opts.ensure_installed were already started above
                for _, filetypes in pairs(opts.ensure_installed) do
                    local ft_table = type(filetypes) == "table" and filetypes or { filetypes }
                    if vim.tbl_contains(ft_table, filetype) then
                        return -- Already handled above
                    end
                end

                local parser_name = vim.treesitter.language.get_lang(filetype) -- might return filetype (not helpful)
                if not parser_name then
                    return
                end
                local parser_configs = require("nvim-treesitter.parsers")
                if not parser_configs[parser_name] then
                    return -- Parser not available, skip silently
                end

                local parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

                if not parser_installed then
                    -- :wait() so the parser can start on this same BufRead event
                    require("nvim-treesitter").install({ parser_name }):wait(30000)
                end

                parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

                if parser_installed then
                    pcall(vim.treesitter.start, bufnr, parser_name)
                end
            end,
        })
    end,
}

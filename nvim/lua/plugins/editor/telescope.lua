return {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    -- ui-select backs vim.ui.select everywhere, so telescope loads before any prompt
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-smart-history.nvim",
        "kkharji/sqlite.lua",
        "nvim-telescope/telescope-ui-select.nvim",
        "nvim-tree/nvim-web-devicons",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
    },
    config = function()
        local actions = require("telescope.actions")
        local history_dir = vim.fn.stdpath("data") .. "/databases"
        local history_file = history_dir .. "/telescope_history.sqlite3"
        vim.fn.mkdir(history_dir, "p")
        require("telescope").setup({
            pickers = {
                live_grep = {
                    mappings = {
                        i = { ["<c-f>"] = actions.to_fuzzy_refine },
                    },
                },
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
            },
            defaults = {
                vimgrep_arguments = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "-u",
                },
                history = {
                    path = history_file,
                    limit = 100,
                },
                mappings = {
                    i = {
                        ["<Esc>"] = actions.close,
                        ["<S-Down>"] = actions.cycle_history_next,
                        ["<S-Up>"] = actions.cycle_history_prev,
                    },
                },
            },
        })
        require("telescope").load_extension("ui-select")
        require("telescope").load_extension("fzf")
        require("telescope").load_extension("smart_history")
    end,
}

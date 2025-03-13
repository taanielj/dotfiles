return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
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
        require("telescope").setup({
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
            },
            defaults = {
                history = {
                    path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
                    limit = 100,
                },
                mappings = {
                    i = {
                        ["<S-Down>"] = actions.cycle_history_next,
                        ["<S-Up>"] = actions.cycle_history_prev,
                    },
                },
            },
        })
        require("telescope").load_extension("ui-select")
        require("telescope").load_extension("fzf")
        require("telescope").load_extension("smart_history")
        local builtin = require("telescope.builtin")

        -- search current buffer
        vim.keymap.set("n", "<leader> ", builtin.find_files, { desc = "Find Files" })
        vim.keymap.set("n", "<leader>/", function()
            builtin.current_buffer_fuzzy_find(
                require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
            )
        end, { desc = "Find in current buffer" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
        vim.keymap.set("n", "<leader>fg", function()
            builtin.live_grep({
                grep_open_files = true,
            })
        end, { desc = "Find in Open Files" })
        vim.keymap.set("n", "<leader>fG", builtin.live_grep, { desc = "Find in Project" })
        -- find (in) hidden files:
        vim.keymap.set("n", "<leader>hf", function()
            builtin.find_files({ hidden = true, no_ignore = true })
        end, { desc = "Find Hidden Files" })
        vim.keymap.set("n", "<leader>hb", function()
            builtin.buffers({ show_all_buffers = true, no_ignore = true })
        end, { desc = "Find Hidden Buffers" })
        vim.keymap.set("n", "<leader>hg", function()
            builtin.live_grep({ additional_args = { "--hidden --no-ignore" } })
        end, { desc = "Hidden Live Grep" })
    end,
}

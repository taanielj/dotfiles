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
        -- make sure databases directory exists
        local database_dir = vim.fn.expand("~/.local/share/nvim/databases")
        if not vim.fn.isdirectory(database_dir) then
            vim.fn.mkdir(database_dir, "p")
        end
        require("telescope").setup({
            pickers = {
                live_grep = {
                    mappings = {
                        i = { ["<c-f>"] = require("telescope.actions").to_fuzzy_refine },
                    },
                },
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
            },
            defaults = {
                vimmgrep_arguments = {
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
                    path = database_dir .. "/telescope_history.sqlite3",
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
        -- Find all files in current working directory:
        vim.keymap.set("n", "<leader> ", builtin.find_files, { desc = "Find Files" })
        -- Find all open buffers:
        vim.keymap.set("n", "<leader>/", function()
            local dropdown = require("telescope.themes").get_dropdown({
                winblend = 10,
                previewer = false,
            })

            local original = dropdown.attach_mappings or function()
                return true
            end

            dropdown.attach_mappings = function(prompt_bufnr, map)
                vim.schedule(function()
                    local winid = vim.api.nvim_get_current_win()
                    vim.wo[winid].scrolloff = 8
                end)
                return original(prompt_bufnr, map)
            end

            require("telescope.builtin").current_buffer_fuzzy_find()
        end, { desc = "Find in current buffer" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
        vim.keymap.set("n", "<leader>fG", function()
            builtin.live_grep({
                grep_open_files = true,
            })
        end, { desc = "Find in Open Files" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find in Project" })
        -- Fuzzy find in current working directory:
        -- find (in) hidden files:
        vim.keymap.set("n", "<leader>hf", function()
            builtin.find_files({ hidden = true, no_ignore = true })
        end, { desc = "Find Hidden Files" })
        vim.keymap.set("n", "<leader>hb", function()
            builtin.buffers({ show_all_buffers = true, no_ignore = true })
        end, { desc = "Find Hidden Buffers" })
        vim.keymap.set("n", "<leader>hg", function()
            builtin.live_grep({
                file_ignore_patterns = { ".venv", ".idea", ".git" },
                additional_args = function()
                    return { "--hidden" }
                end,
            })
        end, { desc = "Find in Hidden Files" })
    end,
}

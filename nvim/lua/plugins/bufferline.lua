return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local neotree_manager = require("neo-tree.sources.manager")

            local function get_neotree_display_name()
                -- Find the window that belongs to Neo-tree
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "neo-tree" then
                        local state = neotree_manager.get_state_for_window(win)
                        return state and state.display_name
                    end
                end
            end

            require("bufferline").setup({
                highlights = require("catppuccin.groups.integrations.bufferline").get_theme(),
                options = {
                    middle_mouse_command = "BufDel %d",
                    close_command = "BufDel %d",

                    right_mouse_command = function(bufnr)
                        require("menu").open_buffer_menu(bufnr)
                    end,
                    diagnostics = "nvim_lsp",
                    offsets = {
                        {
                            filetype = "neo-tree",
                            text = get_neotree_display_name,
                            text_align = "left",
                            separator = false,
                        },
                    },
                    groups = {
                        items = {
                            require("bufferline.groups").builtin.pinned:with({ icon = "󰐃 " }),
                        },
                    },
                    separator_style = "slant",
                    -- close_command = "BufDel",
                },
            })
            -- keymap dict
            local bufferline_mappings = {
                -- closing
                { "n", "<leader>bch", ":BufferLineCloseLeft<CR>",       "Close Left" },
                { "n", "<leader>bcl", ":BufferLineCloseRight<CR>",      "Close Right" },
                { "n", "<leader>bca", ":BufferLineCloseOthers<CR>",     "Close All Other Buffers" },
                -- sorting
                { "n", "<leader>bsd", ":BufferLineSortByDirectory<CR>", "Sort by Directory" },
                { "n", "<leader>bst", ":BufferLineSortByTabs<CR>",      "Sort by Tabs" },
                { "n", "<leader>bse", ":BufferLineSortByExtension<CR>", "Sort by Extension" },
                -- move buffer
                { "n", "<leader>bh",  ":BufferLineMovePrev<CR>",        "Move Prev" },
                { "n", "<leader>bl",  ":BufferLineMoveNext<CR>",        "Move Next" },
                -- cycle buffer
                { "n", "<leader>bn",  ":BufferLineCycleNext<CR>",       "Next Buffer" },
                { "n", "<leader>bp",  ":BufferLineCyclePrev<CR>",       "Previous Buffer" },
                { "n", "<Tab>",       ":BufferLineCycleNext<CR>",       "Next Buffer" },
                { "n", "<S-Tab>",     ":BufferLineCyclePrev<CR>",       "Previous Buffer" },
                -- pick buffer
                { "n", "<leader>bp",  ":BufferLinePick<CR>",            "Pick Buffer" },
                -- pin buffer
                { "n", "<leader>bn",  ":BufferLineTogglePin<CR>",       "Pin Buffer" },
            }
            -- set keymaps
            for _, map in ipairs(bufferline_mappings) do
                vim.keymap.set(map[1], map[2], map[3], { desc = map[4], silent = true })
            end
        end,
    },
    {
        "ojroques/nvim-bufdel",
        config = function()
            require("bufdel").setup({
                next = "tabs",
                quit = true,
            })
            local bufdel_mappings = {
                { "n", "ZZ",          ":BufDel<CR>",    "Save and close buffer" },
                { "n", "<leader>bq",  ":BufDel<CR>",    "Save and close buffer" },
                { "n", "<leader>qb",  ":BufDel<CR>",    "Save and close buffer" },
                { "n", "<leader>q!",  ":BufDel!<CR>",   "Close buffer without saving" },
                { "n", "<Leader>qa",  ":wa<CR>:qa<CR>", "Quit and save all" },
                { "n", "<Leader>qfy", ":qa!<CR>",       "Quit without saving?" },
            }

            for _, map in ipairs(bufdel_mappings) do
                vim.keymap.set(map[1], map[2], map[3], { desc = map[4], silent = true })
            end
        end,
    },
}

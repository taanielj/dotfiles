return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "folke/snacks.nvim", -- buffer closing that keeps the window layout
        },
        config = function()
            local neotree_manager = require("neo-tree.sources.manager")

            local function get_neotree_display_name()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "neo-tree" then
                        local state = neotree_manager.get_state_for_window(win)
                        return state and state.display_name
                    end
                end
            end

            require("bufferline").setup({
                highlights = require("catppuccin.special.bufferline").get_theme()(),
                options = {
                    middle_mouse_command = function(bufnr)
                        require("ui.buffers").close({ buf = bufnr })
                    end,
                    close_command = function(bufnr)
                        require("ui.buffers").close({ buf = bufnr })
                    end,

                    right_mouse_command = function(bufnr)
                        require("ui.menu").show("]Buffer", "bufferline", { bufnr = bufnr })
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
                },
            })
        end,
    },
}

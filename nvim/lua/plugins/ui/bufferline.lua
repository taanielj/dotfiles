return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "folke/snacks.nvim", -- buffer closing that keeps the window layout
        },
        config = function()
            require("bufferline").setup({
                highlights = require("catppuccin.special.bufferline").get_theme()(),
                options = {
                    middle_mouse_command = function(bufnr)
                        require("ui.close_buffer").close({ buf = bufnr })
                    end,
                    close_command = function(bufnr)
                        require("ui.close_buffer").close({ buf = bufnr })
                    end,

                    right_mouse_command = function(bufnr)
                        require("menus").tab(bufnr)
                    end,
                    diagnostics = "nvim_lsp",
                    offsets = {
                        {
                            filetype = "neo-tree",
                            text = require("ui.tree").display_name,
                            text_align = "left",
                            separator = false,
                        },
                    },
                    groups = {
                        items = {
                            require("bufferline.groups").builtin.pinned:with({ icon = require("ui.icons").pin .. " " }),
                        },
                    },
                    separator_style = "slant",
                },
            })
        end,
    },
}

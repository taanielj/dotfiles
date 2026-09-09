return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("lualine").setup({
            options = {
                theme = "catppuccin-nvim", -- follows the active catppuccin flavour (catppuccin.lua)
                globalstatus = true,
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        icons_enabled = true,
                        icon = { "", align = "left" },
                        separator = nil,
                    },
                },
                lualine_b = {
                    function()
                        return require("auto-session.lib").current_session_name(true)
                    end,
                    "branch",
                    "diff",
                    "diagnostics",
                },
                lualine_c = {
                    {
                        "filename",
                        file_status = true,
                        path = 1,
                        shorting_target = 40,
                        symbols = { modified = "", readonly = "", unnamed = "[No Name]", newfile = "[New]" },
                    },
                },
                lualine_x = {
                    {
                        require("noice").api.statusline.mode.get,
                        cond = require("noice").api.statusline.mode.has,
                        color = { fg = "#ff9e64" },
                    },
                },
            },
        })
        vim.o.laststatus = 3 -- Ensure statusline is always shown
    end,
}

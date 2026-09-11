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
                    function() return require("auto-session.lib").current_session_name(true) end,
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
                        function() return "DEBUG" end,
                        cond = function() return require("ui.debug_mode").is_active() end,
                        color = "DiagnosticWarn",
                    },
                    {
                        function() return require("noice").api.status.mode.get() end,
                        cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
                        color = { fg = "#ff9e64" },
                    },
                },
            },
        })
    end,
}

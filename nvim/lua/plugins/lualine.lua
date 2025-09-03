return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "kyazdani42/nvim-web-devicons", -- Ensure correct dependency for icons
    },
    config = function()
        require("lualine").setup({
            options = {
                theme = "catppuccin",
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
                        file_status = true, -- Display file status
                        path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
                        shortin_target = 40,
                        symbols = { modified = "", readonly = "", unnamed = "[No Name]", newfile = "[New]" }, -- Icons
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

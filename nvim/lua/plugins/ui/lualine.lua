return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        vim.o.showcmdloc = "statusline"
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
                        function() return "recording @" .. vim.fn.reg_recording() end,
                        cond = function() return vim.fn.reg_recording() ~= "" end,
                        color = { fg = "#ff9e64" },
                    },
                    "%S",
                },
            },
        })
        vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
            group = vim.api.nvim_create_augroup("lualine_recording", { clear = true }),
            -- reg_recording() still names the register during RecordingLeave
            callback = function() vim.schedule(require("lualine").refresh) end,
        })
    end,
}

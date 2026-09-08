return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
        local hooks = require("ibl.hooks")

        local rainbow = {
            RainbowRed = "#E06C75",
            RainbowYellow = "#E5C07B",
            RainbowBlue = "#61AFEF",
            RainbowOrange = "#D19A66",
            RainbowGreen = "#98C379",
            RainbowViolet = "#C678DD",
            RainbowCyan = "#56B6C2",
        }

        -- Runs on setup and again after any :colorscheme, which clears highlights
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            for name, fg in pairs(rainbow) do
                vim.api.nvim_set_hl(0, name, { fg = fg })
            end
        end)

        local order = {
            "RainbowRed",
            "RainbowYellow",
            "RainbowBlue",
            "RainbowOrange",
            "RainbowGreen",
            "RainbowViolet",
            "RainbowCyan",
        }

        require("ibl").setup({
            scope = {
                char = "▎",
                show_start = false,
                show_end = false,
                highlight = order,
            },
            indent = {
                char = "▏",
                tab_char = "·",
                highlight = order,
            },
        })
    end,
}

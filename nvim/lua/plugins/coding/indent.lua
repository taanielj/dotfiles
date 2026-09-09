return {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
        local hooks = require("ibl.hooks")

        local rainbow = {
            { "RainbowRed", "#E06C75" },
            { "RainbowYellow", "#E5C07B" },
            { "RainbowBlue", "#61AFEF" },
            { "RainbowOrange", "#D19A66" },
            { "RainbowGreen", "#98C379" },
            { "RainbowViolet", "#C678DD" },
            { "RainbowCyan", "#56B6C2" },
        }
        local order = vim.tbl_map(function(pair) return pair[1] end, rainbow)

        -- Runs on setup and again after any :colorscheme, which clears highlights
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            for _, pair in ipairs(rainbow) do
                vim.api.nvim_set_hl(0, pair[1], { fg = pair[2] })
            end
        end)

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

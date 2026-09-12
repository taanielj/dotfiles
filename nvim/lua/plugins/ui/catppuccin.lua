return {
    "catppuccin/nvim",
    -- config applies the colorscheme at startup
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            term_colors = false,
            integrations = {
                neotree = true,
                telescope = true,
                treesitter = true,
                blink_cmp = true,
                gitsigns = true,
                snacks = true,
            },
            -- Reapplied with the colorscheme, unlike a highlight set at config time
            custom_highlights = {
                Folded = { bg = "NONE" },
                FoldColumn = { fg = "NONE" },
                NeoTreeDotfile = { fg = "#aaaaaa" },
            },
            dim_inactive = {
                enabled = true,
                shade = "dark",
                percentage = 0.25,
            },
        })
        vim.cmd.colorscheme("catppuccin-macchiato")
    end,
}

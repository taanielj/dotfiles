return {
    "catppuccin/nvim",
    lazy = false,
    name = "catpuccin",
    priority = 1000,
    term_colors = false,
    config = function()
        require("catppuccin").setup({
            flavour = "macchiato",
            integrations = {
                neotree = {
                    enabled = true,
                    show_root = true,
                },
                telescope = true,
                treesitter = true,
                cmp = true,
                gitsigns = true,
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

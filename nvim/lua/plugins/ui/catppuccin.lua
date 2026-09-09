return {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            term_colors = false,
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
        vim.cmd.colorscheme("catppuccin-macchiato") -- -latte, -frappe, -macchiato, -mocha
    end,
}

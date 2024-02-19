return {
    "catppuccin/nvim",
    lazy = false,
    name = "catpuccin",
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("catppuccin")
        require("catppuccin").setup({
            integrations = {
                neotree = {
                    enabled = true,
                    show_root = true,
                    transparent_panel = false,
                },
            },
        })
    end,
}

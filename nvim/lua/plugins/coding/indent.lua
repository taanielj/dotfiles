return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
        require("ibl").setup({
            scope = {
                char = "▎",
                show_start = false,
                show_end = false,
            },
            indent = {
                char = "▏",
                tab_char = "·",
            },
        })
    end,
}

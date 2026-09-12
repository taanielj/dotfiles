return {
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    -- gz: s is flash, gs is document symbols
    opts = {
        mappings = {
            add = "gza",
            delete = "gzd",
            find = "gzf",
            find_left = "gzF",
            highlight = "gzh",
            replace = "gzr",
        },
    },
}

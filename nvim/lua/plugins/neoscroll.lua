return {
    "karb94/neoscroll.nvim",
    opts = {
        easing = "quadratic",
        duration_multiplier = 0.33,
    },
    -- faster up and down movement in normal mode
    vim.keymap.set("n", "<C-U>", "5gk", { noremap = true, silent = true, desc = "Move 5 lines up" }),
    vim.keymap.set("n", "<C-D>", "5gj", { noremap = true, silent = true, desc = "Move 5 lines down" }),
    vim.keymap.set("n", "<C-E>", "5<C-e>", { noremap = true, silent = true, desc = "Scroll 5 lines down" }),
    vim.keymap.set("n", "<C-Y>", "5<C-y>", { noremap = true, silent = true, desc = "Scroll 5 lines up" }),
}

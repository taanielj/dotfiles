return {
    "karb94/neoscroll.nvim",
    opts = {
        easing = "quadratic",
        duration_multiplier = 1,
    },
    -- faster up and down movement in normal mode
    -- vim.keymap.set("n", "<C-U>", "5gk", { noremap = true, silent = true, desc = "Move 5 lines up" }),
    -- vim.keymap.set("n", "<C-D>", "5gj", { noremap = true, silent = true, desc = "Move 5 lines down" }),
    config = function()
        require("neoscroll").setup()
        local neoscroll = require("neoscroll")
        vim.keymap.set("n", "<C-E>", "5<C-e>", { noremap = true, silent = true, desc = "Scroll 5 lines down" })
        vim.keymap.set("n", "<C-Y>", "5<C-y>", { noremap = true, silent = true, desc = "Scroll 5 lines up" })
            -- move up and down by window height with page up and page down
            -- vim.keymap.set("n", "<PageUp>", function() neoscroll.ctrl_u({duration = 100; easing= "quadratic"}) end, { noremap = true, silent = true, desc = "Move up by window height" }),
            -- vim.keymap.set("n", "<PageDown>", function() neoscroll.ctrl_d({duration = 100; easing = "quadratic"}) end, { noremap = true, silent = true, desc = "Move down by window height" })
        local keymap = {
            ["<PageUp>"] = function() neoscroll.ctrl_u({ duration = 100; easing = "quadratic" }) end,
            ["<PageDown>"] = function() neoscroll.ctrl_d({ duration = 100; easing = "quadratic" }) end,
        }
        local modes = { "n", "v" , "x", "i" }
        for key, func in pairs(keymap) do
            vim.keymap.set(modes, key, func, { noremap = true, silent = true, desc = "Scroll" })
        end
    end,
}

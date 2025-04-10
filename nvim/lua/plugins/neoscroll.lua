return {
    "karb94/neoscroll.nvim",
    opts = {
        easing = "quadratic",
        duration_multiplier = 1,
    },
    config = function()
        require("neoscroll").setup({
            hide_cursor = true,
        })
        local neoscroll = require("neoscroll")
        local keymap = {
            ["<C-y>"] = function() neoscroll.scroll(-0.2, { move_cursor = false; duration = 100 }) end,
            ["<C-e>"] = function() neoscroll.scroll(0.2, { move_cursor = false; duration = 100 }) end,
            ["<PageUp>"] = function() neoscroll.ctrl_u({ duration = 100; easing = "quadratic" }) end,
            ["<PageDown>"] = function() neoscroll.ctrl_d({ duration = 100; easing = "quadratic" }) end,
        }
        local modes = { "n", "v" , "x", "i" }
        for key, func in pairs(keymap) do
            vim.keymap.set(modes, key, func, { noremap = true, silent = true, desc = "Scroll" })
        end
    end,
}

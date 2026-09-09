return {
    "karb94/neoscroll.nvim",
    opts = {
        -- <C-y> and <C-e> are in keybinds/view.lua with their own speed
        mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
        easing = "quadratic",
        duration_multiplier = 1,
        hide_cursor = true,
    },
}

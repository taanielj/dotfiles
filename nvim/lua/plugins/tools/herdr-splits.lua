-- Seamless nvim <-> herdr navigation (ctrl+hjkl) and resize (alt+hjkl).
-- Only loads inside herdr; outside it, smart-splits (zellij.lua) owns these keys.
return {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    event = "VeryLazy",
    build = 'lua require("herdr-splits").sync_herdr()',
    opts = {
        at_edge = "wrap",
    },
    keys = {
        { "<C-h>", function() require("herdr-splits").move_cursor_left() end },
        { "<C-j>", function() require("herdr-splits").move_cursor_down() end },
        { "<C-k>", function() require("herdr-splits").move_cursor_up() end },
        { "<C-l>", function() require("herdr-splits").move_cursor_right() end },
        { "<M-h>", function() require("herdr-splits").resize_left() end },
        { "<M-j>", function() require("herdr-splits").resize_down() end },
        { "<M-k>", function() require("herdr-splits").resize_up() end },
        { "<M-l>", function() require("herdr-splits").resize_right() end },
    },
}

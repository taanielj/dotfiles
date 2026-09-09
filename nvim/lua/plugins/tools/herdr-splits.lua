-- Outside herdr, smart-splits.lua owns these keys.
return {
    "lmilojevicc/herdr-splits.nvim",
    cond = require("lib.herdr").inside(),
    event = "VeryLazy",
    build = ':lua require("herdr-splits").sync_herdr()',
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
        -- 0.01 is a one-percent herdr step and floors to one cell for a Neovim split
        { "<M-H>", function() require("herdr-splits").resize_left(0.01) end },
        { "<M-J>", function() require("herdr-splits").resize_down(0.01) end },
        { "<M-K>", function() require("herdr-splits").resize_up(0.01) end },
        { "<M-L>", function() require("herdr-splits").resize_right(0.01) end },
    },
}

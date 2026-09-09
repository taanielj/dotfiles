return {
    "mrjones2014/smart-splits.nvim",
    cond = not require("lib.herdr").inside(), -- inside herdr, herdr-splits owns ctrl+hjkl
    keys = {
        { "<C-h>", function() require("smart-splits").move_cursor_left() end,  silent = true },
        { "<C-j>", function() require("smart-splits").move_cursor_down() end,  silent = true },
        { "<C-k>", function() require("smart-splits").move_cursor_up() end,    silent = true },
        { "<C-l>", function() require("smart-splits").move_cursor_right() end, silent = true },
    },
    opts = {},
}

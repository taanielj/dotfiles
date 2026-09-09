return {
    "soulis-1256/eagle.nvim",
    -- setup() registers the <MouseMove> keymap, so mouse hover needs it loaded
    event = "VeryLazy",
    opts = {
        border = "rounded",
        mouse_mode = true,
        keyboard_mode = true,
        title = "",
        improved_markdown = true,
    },
    keys = {
        {
            "K",
            function()
                local winid = require("ufo").peekFoldedLinesUnderCursor()
                if not winid then
                    vim.cmd("EagleWin")
                end
            end,
            desc = "Hover, or peek the fold",
        },
    },
}

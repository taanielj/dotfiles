local map = require("lib.keymap").rows

-- stylua: ignore
map({
    -- <leader>b  Buffer
    { "n", "<leader>bn",                           "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n", "<leader>bp",                           "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n", "<Tab>",                                "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n", "<S-Tab>",                              "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n", "<leader>bh",                           "<Cmd>BufferLineMovePrev<CR>",                   "Move buffer left" },
    { "n", "<leader>bl",                           "<Cmd>BufferLineMoveNext<CR>",                   "Move buffer right" },
    { "n", "<leader>bP",                           "<Cmd>BufferLinePick<CR>",                       "Pick buffer" },
    { "n", "<leader>bt",                           "<Cmd>BufferLineTogglePin<CR>",                  "Pin buffer" },
    { "n", { "ZZ", "<leader>bq", "<leader>qb" },   function() require("ui.close_buffer").close({ save = true }) end, "Save and close buffer" },
    { "n", "<leader>bch",                          "<Cmd>BufferLineCloseLeft<CR>",                  "Close buffers to the left" },
    { "n", "<leader>bcl",                          "<Cmd>BufferLineCloseRight<CR>",                 "Close buffers to the right" },
    { "n", "<leader>bca",                          "<Cmd>BufferLineCloseOthers<CR>",                "Close other buffers" },
    { "n", "<leader>bsd",                          "<Cmd>BufferLineSortByDirectory<CR>",            "Sort by directory" },
    { "n", "<leader>bst",                          "<Cmd>BufferLineSortByTabs<CR>",                 "Sort by tabs" },
    { "n", "<leader>bse",                          "<Cmd>BufferLineSortByExtension<CR>",            "Sort by extension" },

    -- <leader>q  Close
    { "n", { "ZQ", "<leader>q!" },                 function() require("ui.close_buffer").close({ force = true }) end, "Close buffer without saving" },
    { "n", "<leader>qa",                           "<Cmd>wa<CR><Cmd>qa<CR>",                        "Quit and save all" },
    { "n", "<leader>qfy",                          "<Cmd>qa!<CR>",                                  "Quit without saving?" },

    { "n", "<leader>R",                            function() require("ui.session").restart() end,  "Restart nvim, keeping the session" },
})

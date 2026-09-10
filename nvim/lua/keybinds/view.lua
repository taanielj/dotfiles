local map = require("lib.keymap").rows

-- stylua: ignore
map({
    -- Right-click uses Neovim's own popup_setpos; this is the keyboard route
    { "n", "<leader>.", function() require("menus").popup_at_cursor() end,     "Open menu" },
    { "n", "<leader>e", "<Cmd>Neotree filesystem reveal left toggle=true<CR>", "Show files" },
    { "n", "<leader>A", "<Cmd>Alpha<CR>",                                      "Dashboard" },
    { "n", "<leader>z", function() require("ui.zen").toggle() end,                "Toggle zen mode" },
    { "n", "<leader>gg", function() require("ui.lazygit").open() end,             "LazyGit" },
    { "n", { "-", "<BS>" }, "<Cmd>Oil<CR>",                                    "Open parent directory" },
    { "n", "zR",        function() require("ufo").openAllFolds() end,          "Open all folds" },
    { "n", "zM",        function() require("ufo").closeAllFolds() end,         "Close all folds" },

    -- Animated scroll
    { { "n", "v", "x", "i" }, "<C-y>",      function() require("neoscroll").scroll(-0.2, { move_cursor = false, duration = 100 }) end, "Scroll up a little" },
    { { "n", "v", "x", "i" }, "<C-e>",      function() require("neoscroll").scroll(0.2, { move_cursor = false, duration = 100 }) end,  "Scroll down a little" },
    { { "n", "v", "x", "i" }, "<PageUp>",   function() require("neoscroll").ctrl_u({ duration = 100, easing = "quadratic" }) end,        "Scroll up half a page" },
    { { "n", "v", "x", "i" }, "<PageDown>", function() require("neoscroll").ctrl_d({ duration = 100, easing = "quadratic" }) end,        "Scroll down half a page" },

    -- Resize splits; inside herdr, herdr-splits takes these keys
    { "n", "<M-h>",     "2<C-w><",                                             "Resize split left" },
    { "n", "<M-l>",     "2<C-w>>",                                             "Resize split right" },
    { "n", "<M-j>",     "2<C-w>+",                                             "Resize split down" },
    { "n", "<M-k>",     "2<C-w>-",                                             "Resize split up" },
    { "n", "<M-H>",     "<C-w><",                                              "Resize split left (fine)" },
    { "n", "<M-L>",     "<C-w>>",                                              "Resize split right (fine)" },
    { "n", "<M-J>",     "<C-w>+",                                              "Resize split down (fine)" },
    { "n", "<M-K>",     "<C-w>-",                                              "Resize split up (fine)" },

    -- <leader>w  Wrap
    { "n", "<leader>w", function() require("ui.wrap").toggle() end,           "Toggle wrap window" },
})

-- scrollbind only follows the current window, so wheeling over the other side
-- of a diff moves that side alone; syncing from the hovered window brings the
-- rest along.
local function wheel(key)
    local termcode = vim.api.nvim_replace_termcodes(key, true, false, true)
    return function()
        local win = vim.fn.getmousepos().winid
        vim.cmd.normal({ termcode, bang = true })
        if win ~= 0 and win ~= vim.api.nvim_get_current_win() and vim.wo[win].scrollbind then
            vim.api.nvim_win_call(win, vim.cmd.syncbind)
        end
    end
end

-- stylua: ignore
map({
    { { "n", "x", "i" }, "<ScrollWheelDown>", wheel("<ScrollWheelDown>"), "Scroll down, syncing bound windows" },
    { { "n", "x", "i" }, "<ScrollWheelUp>",   wheel("<ScrollWheelUp>"),   "Scroll up, syncing bound windows" },
})

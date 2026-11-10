local map = require("lib.keymap").rows

-- snacks.scroll animates the jump
local function scroll_fifth(key)
    return function()
        local lines = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 5))
        vim.cmd("normal! " .. lines .. vim.keycode(key))
    end
end
local function half_page(key)
    return function() vim.cmd("normal! " .. vim.keycode(key)) end
end

-- stylua: ignore
map({
    -- Right-click uses Neovim's own popup_setpos; this is the keyboard route
    { "n", "<leader>.", function() require("menus").popup_at_cursor() end,     "Open menu" },
    { "n", "<leader>e", function() require("ui.tree").toggle() end,            "Show files" },
    { "n", "<leader>A", function() require("ui.dashboard").open() end,                     "Dashboard" },
    { "n", "<leader>z", function() require("ui.zen").toggle() end,                "Toggle zen mode" },
    -- Keyed by cwd, branch and filetype. A count opens a second one.
    { "n", "<leader>n", function() Snacks.scratch() end,                          "Scratch buffer" },
    { "n", "<leader>N", function() Snacks.scratch.select() end,                   "Pick a scratch buffer" },
    { "n", "<leader>gg", function() require("ui.lazygit").open() end,             "LazyGit" },
    { "n", { "-", "<BS>" }, "<Cmd>Oil<CR>",                                    "Open parent directory" },
    { "n", "zR",        function() require("lib.folds").show(math.huge) end,   "Open all folds" },
    { "n", "zM",        function() require("lib.folds").show(0) end,           "Close all folds" },
    { "n", "zr",        function() require("lib.folds").step(1) end,           "Open a fold level, or to [count]" },
    { "n", "zm",        function() require("lib.folds").step(-1) end,          "Close a fold level, or to [count]" },

    { { "n", "x", "i" }, "<C-y>",      scroll_fifth("<C-y>"),                              "Scroll up a little" },
    { { "n", "x", "i" }, "<C-e>",      scroll_fifth("<C-e>"),                              "Scroll down a little" },
    { { "n", "x", "i" }, "<PageUp>",   half_page("<C-u>"),                             "Scroll up half a page" },
    { { "n", "x", "i" }, "<PageDown>", half_page("<C-d>"),                             "Scroll down half a page" },

    -- Window navigation and resize cross into the multiplexer's panes
    { { "n", "x" }, "<C-h>",     function() require("lib.splits").move("left") end,          "Window left" },
    { { "n", "x" }, "<C-j>",     function() require("lib.splits").move("down") end,          "Window down" },
    { { "n", "x" }, "<C-k>",     function() require("lib.splits").move("up") end,            "Window up" },
    { { "n", "x" }, "<C-l>",     function() require("lib.splits").move("right") end,         "Window right" },
    { { "n", "x" }, "<M-h>",     function() require("lib.splits").resize("left") end,        "Resize split left" },
    { { "n", "x" }, "<M-j>",     function() require("lib.splits").resize("down") end,        "Resize split down" },
    { { "n", "x" }, "<M-k>",     function() require("lib.splits").resize("up") end,          "Resize split up" },
    { { "n", "x" }, "<M-l>",     function() require("lib.splits").resize("right") end,       "Resize split right" },
    { { "n", "x" }, "<M-H>",     function() require("lib.splits").resize("left", true) end,  "Resize split left (fine)" },
    { { "n", "x" }, "<M-J>",     function() require("lib.splits").resize("down", true) end,  "Resize split down (fine)" },
    { { "n", "x" }, "<M-K>",     function() require("lib.splits").resize("up", true) end,    "Resize split up (fine)" },
    { { "n", "x" }, "<M-L>",     function() require("lib.splits").resize("right", true) end, "Resize split right (fine)" },

    -- <leader>w  Wrap
    { "n", "<leader>w", function() require("ui.wrap").toggle() end,           "Toggle wrap window" },
})

-- scrollbind syncs other windows only to the current one, and the wheel over
-- the other side of a diff scrolls that side alone. syncbind in the hovered
-- window scrolls the bound windows to match.
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

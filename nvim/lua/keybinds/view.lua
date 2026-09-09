local map = require("lib.keymap").rows

map({
    -- ==================
    -- Windows and panels
    -- ==================
    -- Right-click uses Neovim's own popup_setpos; this is the keyboard route
    { "n", "<leader>.", function() require("menus").popup_at_cursor() end,     "Open menu" },
    { "n", "<leader>e", "<Cmd>Neotree filesystem reveal left toggle=true<CR>", "Show files" },
    { "n", "<leader>A", "<Cmd>Alpha<CR>",                                      "Dashboard" },
    { "n", "<leader>z", function() require("zen").toggle() end,                "Toggle zen mode" },
    { "n", { "-", "<BS>" }, "<Cmd>Oil<CR>",                                    "Open parent directory" },
    { "n", "zR",        function() require("ufo").openAllFolds() end,          "Open all folds" },
    { "n", "zM",        function() require("ufo").closeAllFolds() end,         "Close all folds" },

    -- ================
    -- Animated scroll
    -- ================
    { { "n", "v", "x", "i" }, "<C-y>",      function() require("neoscroll").scroll(-0.2, { move_cursor = false, duration = 100 }) end, "Scroll up a little" },
    { { "n", "v", "x", "i" }, "<C-e>",      function() require("neoscroll").scroll(0.2, { move_cursor = false, duration = 100 }) end,  "Scroll down a little" },
    { { "n", "v", "x", "i" }, "<PageUp>",   function() require("neoscroll").ctrl_u({ duration = 100, easing = "quadratic" }) end,        "Scroll up half a page" },
    { { "n", "v", "x", "i" }, "<PageDown>", function() require("neoscroll").ctrl_d({ duration = 100, easing = "quadratic" }) end,        "Scroll down half a page" },

    -- =============
    -- Resize splits
    -- =============
    { "n", "<M-h>",     "2<C-w><",                                             "Resize split left" },
    { "n", "<M-l>",     "2<C-w>>",                                             "Resize split right" },
    { "n", "<M-j>",     "2<C-w>+",                                             "Resize split down" },
    { "n", "<M-k>",     "2<C-w>-",                                             "Resize split up" },
    { "n", "<M-H>",     "<C-w><",                                              "Resize split left (fine)" },
    { "n", "<M-L>",     "<C-w>>",                                              "Resize split right (fine)" },
    { "n", "<M-J>",     "<C-w>+",                                              "Resize split down (fine)" },
    { "n", "<M-K>",     "<C-w>-",                                              "Resize split up (fine)" },
})

-- =================
-- <leader>w  Wrap
-- =================

local spacer_by_window = {}

local function open_wrap_spacer(win, width)
    vim.cmd("vertical rightbelow new")
    local spacer = vim.api.nvim_get_current_win()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.wo.winbar = ""
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, width)
    spacer_by_window[win] = spacer
end

local function splits()
    return vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
end

-- The last split cannot close, so a spacer left alone stays as a window
local function close_wrap_spacer(win)
    local spacer = spacer_by_window[win]
    spacer_by_window[win] = nil
    if spacer and vim.api.nvim_win_is_valid(spacer) and #splits() > 1 then
        vim.api.nvim_win_close(spacer, true)
    end
end

-- A spacer goes with its window; a spacer closed by hand is forgotten
vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("user_wrap_spacer", { clear = true }),
    callback = function(ev)
        local closed = tonumber(ev.match)
        if spacer_by_window[closed] then
            vim.schedule(function()
                close_wrap_spacer(closed)
            end)
            return
        end
        for win, spacer in pairs(spacer_by_window) do
            if spacer == closed then
                spacer_by_window[win] = nil
            end
        end
    end,
})

-- linebreak is the flag this sets; wrap is on by default and cannot signal the state
vim.keymap.set("n", "<leader>w", function()
    local win = vim.api.nvim_get_current_win()
    if vim.wo.linebreak then
        vim.wo.wrap = false
        vim.wo.linebreak = false
        vim.wo.breakindent = false
        vim.wo.breakindentopt = ""
        close_wrap_spacer(win)
        return
    end

    vim.wo.wrap = true
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "list:2"
    open_wrap_spacer(win, vim.v.count ~= 0 and vim.v.count or 125)
end, { desc = "Toggle wrap window" })

-- ============
-- Mouse wheel
-- ============

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

map({
    { { "n", "x", "i" }, "<ScrollWheelDown>", wheel("<ScrollWheelDown>"), "Scroll down, syncing bound windows" },
    { { "n", "x", "i" }, "<ScrollWheelUp>",   wheel("<ScrollWheelUp>"),   "Scroll up, syncing bound windows" },
})

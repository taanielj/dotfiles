-- remap ctrl-q to enter visual block mode in windows, ctrl-q quits on mac anyway
vim.keymap.set("n", "<C-q>", "<C-v>", { noremap = true, silent = true, desc = "Visual block" })

vim.g.mapleader = " "
-- =============================
-- Line movement and indentation
-- =============================

local map = function(mappings)
    -- wrap in table if single mapping
    if mappings[1] == nil or type(mappings[1]) ~= "table" then
        mappings = { mappings }
    end

    for _, m in ipairs(mappings) do
        local modes, keys, cmd, desc = m[1], m[2], m[3], m[4]
        if type(keys) == "string" then
            keys = { keys }
        end
        for _, key in ipairs(keys) do
            vim.keymap.set(modes, key, cmd, { noremap = true, silent = true, desc = desc })
        end
    end
end

local move_mappings = {
    { "n", "<C-Up>",    ":m .-2<CR>==",     "Move line up" },
    { "n", "<C-Down>",  ":m .+1<CR>==",     "Move line down" },
    { "n", "<C-Left>",  "<<hhhh",           "Unindent line" },
    { "n", "<C-Right>", ">>llll",           "Indent line" },
    { "v", "<C-Up>",    ":m '<-2<CR>gv=gv", "Move line up" },
    { "v", "<C-Down>",  ":m '>+1<CR>gv=gv", "Move line down" },
    { "v", "<C-Left>",  "<gvhhhh",          "Unindent line" },
    { "v", "<C-Right>", ">gvllll",          "Indent line" },
}

map(move_mappings)

-- ==============
-- Selecting text
-- ==============

local select_mappings = {
    -- Normal mode
    -- Normal mode select up down v-block mode
    -- { "n", "<S-Up>", "<C-v>k", "Select up" },
    -- { "n", "<S-Down>", "<C-v>j", "Select down" },
    -- Normal mode select up down regular visual mode
    { "n",               "<S-Down>",  "vj",        "Select down" },
    { "n",               "<S-Up>",    "vk",        "Select up" },
    { "n",               "<S-Left>",  "vh",        "Select left" },
    { "n",               "<S-Right>", "vl",        "Select right" },
    { "n",               "<S-Home>",  "v^",        "Select to beginning of line" },
    { "n",               "<Home>",    "^",         "Move to beginning of text" }, -- 0 still selects to beginning of line
    { "n",               "<S-End>",   "v$h",       "Select to end of line" }, -- without newline, hit S-End again to include newline
    -- Insert mode
    { "i",               "<S-Up>",    "<Esc>vkl",  "Select up" },
    { "i",               "<S-Down>",  "<Esc>lvjh", "Select down" },
    { "i",               "<S-Left>",  "<Esc>v",    "Select left" },
    { "i",               "<S-Right>", "<Esc>lv",   "Select right" },
    { "i",               "<S-Home>",  "<Esc>lv",   "Select to beginning of line" },
    { "i",               "<S-End>",   "<Esc>lv$h", "Select to end of line" }, -- without newline, hit S-End again to include newline
    { "i",               "<Home>",    "<Esc>^i",   "Move to beginning of text" },
    -- Ignore Shift key in visual mode and visual mode home and end keys
    { "v",               "<S-Up>",    "k",         "Move up" },
    { "v",               "<S-Down>",  "j",         "Move down" },
    { "v",               "<S-Left>",  "h",         "Move left" },
    { "v",               "<S-Right>", "l",         "Move right" },
    { "v",               "<S-Home>",  "0",         "Move to beginning of line" },
    { "v",               "<Home>",    "^",         "Move to beginning of text" },
    { "v",               "<S-End>",   "$",         "Move to end of line" }, -- with newline
    { "v",               "<End>",     "$h",        "Move to end of line" }, -- without newline
    -- Select all with Ctrl + A
    { { "n", "v", "i" }, "<C-a>",     "ggVG",      "Select all" },
}

map(select_mappings)

-- =============
-- Deleting text
-- =============
-- ctrl backspace in insert delete
vim.keymap.set("i", "<C-H>", function()
    local col = vim.fn.col(".")
    if col == 1 then
        -- Already at start of line, no word to delete
        return ""
    end

    -- Get the character before the cursor
    local prev_char = vim.fn.getline("."):sub(col - 1, col - 1)
    if prev_char:match("%s") then
        -- If previous character is whitespace, delete it and previous word
        return "<C-o>db"
    else
        return "<C-o>dB"
    end
end, { noremap = true, expr = true, silent = true, desc = "Delete previous word consistently" })

-- ctrl delete in insert mode
vim.keymap.set("i", "<C-Del>", function()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    if col >= #line then
        return "<Del>"
    else
        return "<C-o>dw"
    end
end, { noremap = true, silent = true, expr = true, desc = "Delete next word, <Del> if end of line" })

-- ==============
-- Copy and paste
-- ==============

-- ctrl C copy in visual mode
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true, desc = "Copy" })
-- ctrl X cut in visual mode
vim.keymap.set("v", "<C-x>", '"+x', { noremap = true, silent = true, desc = "Cut" })
-- ctrl V paste in visual mode
vim.keymap.set("x", "<C-v>", '"0dP', { noremap = true, silent = true, desc = "Paste without overwriting unnamed reg" })
vim.keymap.set("i", "<C-v>", "<C-o>P", { noremap = true, silent = true, desc = "Paste" })

-- ==================
-- Search and replace
-- ==================

vim.keymap.set(
    "n",
    "<leader>s",
    ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>",
    { noremap = true, silent = true, desc = "Search and replace" }
)

-- clear last search highlight
vim.keymap.set("n", "<Esc>", ":let @/=''<CR>", { noremap = true, silent = true, desc = "Clear search highlight" })
-- home and end in insert mode

-- ===============
-- Wrap and unwrap
-- ===============

-- turn on wrap and linebreak for current window
-- function to close no name buffers
function _G.close_no_name_buffers()
    local bufnr_list = vim.api.nvim_list_bufs()
    for _, bufnr in ipairs(bufnr_list) do
        if vim.api.nvim_buf_get_name(bufnr) == "" then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end
end

vim.keymap.set("n", "<leader>ww", function()
    vim.wo.wrap = true
    vim.wo.linebreak = true
    return '<Cmd>vertical rightbelow new | set winbar="" nonumber norelativenumber<CR><C-w>h<C-w>'
        .. (vim.v.count ~= 0 and vim.v.count or 125) -- linewidth is 120, add 5 to account for line numbers
        .. "|"
end, { expr = true, noremap = true, silent = true, desc = "Wrap current window" })

-- turn off wrap and linebreak for current window, close no name buffers
vim.keymap.set("n", "<leader>wu", function()
    vim.wo.wrap = false
    vim.wo.linebreak = false
    vim.cmd("lua close_no_name_buffers()")
end, { noremap = true, silent = true, desc = "Unwrap current window" })

-- Navigation with wrap enabled:
-- remap j and k to move visual line by line
vim.keymap.set("n", "j", 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set("n", "k", 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap gj and gk to move visual line by line
vim.keymap.set("x", "j", 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set("x", "k", 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap arrow keys in all modes to move visual line by line
vim.keymap.set("n", "<Up>", "gk", { noremap = true })
vim.keymap.set("n", "<Down>", "gj", { noremap = true })
vim.keymap.set("x", "<Up>", "gk", { noremap = true })
vim.keymap.set("x", "<Down>", "gj", { noremap = true })
local function move_cursor_visual(lines)
    local count = math.abs(lines)
    local key = lines > 0 and "gj" or "gk"
    vim.cmd.normal({ tostring(count) .. key, bang = true })
end

vim.keymap.set("i", "<Up>", function()
    move_cursor_visual(-1)
end, { noremap = true, silent = true })

vim.keymap.set("i", "<Down>", function()
    move_cursor_visual(1)
end, { noremap = true, silent = true })

--vim.keymap.set("i", "<Up>", "<C-o>gk", { noremap = true })
--vim.keymap.set("i", "<Down>", "<C-o>gj", { noremap = true })

-- ===========================
-- Surround plugin replacement
-- ===========================

-- surround with quotes, '''''', brackets, etc. in visual mode (non block, only regular)

local surround_mappings = {
    { "v", "'",                          "c''<Esc>P",                          "Add single quotes" },
    { "v", '"',                          'c""<Esc>P',                          "Add double quotes" },
    { "v", "`",                          "c``<Esc>P",                          "Add backticks" },
    { "v", { "(", ")" },                 "c()<Esc>P",                          "Add parentheses" },
    { "v", { "[", "]" },                 "c[]<Esc>P",                          "Add brackets" },
    { "v", { "{", "}" },                 "c{}<Esc>P",                          "Add curly braces" },
    { "v", { "<", ">" },                 "c<><Esc>P",                          "Add angle brackets" },
    -- surround with triple quotes ('''''', """""", ``````, etc.) in visual mode (non block, only regular)
    { "v", "<Leader>'",                  "c''''''<Left><Left><Left><CR><Esc>p" },
    { "v", '<Leader>"',                  'c""""""<Left><Left><Left><CR><Esc>p' },
    { "v", "<Leader>`",                  "c``````<Left><Left><Left><CR><Esc>p" },
    -- surround with double brackets, double parentheses, double curly braces, etc. in visual mode (non block, only regular)
    { "v", { "<Leader>(", "<Leader>)" }, "c(())<Esc>2hp",                      "Add double parentheses" },
    { "v", { "<Leader>[", "<Leader]" },  "c[[]]<Esc>2hp",                      "Add double brackets" },
    { "v", { "<Leader>{", "<Leader}" },  "c{{}}<Esc>2hp",                      "Add double curly braces" },
    { "v", { "<Leader><", "<Leader>>" }, "c<<>><Esc>2hp",                      "Add double angle brackets" },
}
map(surround_mappings)
vim.keymap.set("i", "<Esc>", function()
    -- Get insert-mode cursor position before leaving insert mode
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    -- After <Esc>, cursor moves left: compensate by moving right again
    -- Save a deferred function to run after exiting insert mode
    vim.schedule(function()
        local line_length = #vim.api.nvim_get_current_line()
        if col > 0 and col <= line_length then
            vim.api.nvim_win_set_cursor(0, { row, col })
        end
    end)

    -- Exit insert mode
    return "<Esc>"
end, { expr = true, noremap = true })

-- been using vs-code again, adding ctrl-s to save in all modes:
map {
    { "n", "<C-s>", "<Cmd>w<CR>", "Save file" },
    { "i", "<C-s>", "<Cmd>w<CR>", "Save file" },
    { "v", "<C-s>", "<Cmd>w<CR>", "Save file" },
}


-- Set leader key first
vim.g.mapleader = " "

-- Define the mapping function
local map = function(mappings)
    if mappings[1] == nil or type(mappings[1]) ~= "table" then
        mappings = { mappings }
    end

    for _, m in ipairs(mappings) do
        local modes, keys, cmd, desc, expr = m[1], m[2], m[3], m[4], m[5]
        if type(keys) == "string" then
            keys = { keys }
        end
        if type(modes) == "string" then
            modes = { modes }
        end

        for _, key in ipairs(keys) do
            vim.keymap.set(modes, key, cmd, {
                noremap = true,
                silent = true,
                desc = desc,
                expr = expr,
            })
        end
    end
end

vim.keymap.set("n", "i", function()
    vim.wo.relativenumber = false
    return "i"
end, { noremap = true, expr = true, silent = true, desc = "Insert mode without relative number" })

-- Store all mappings in a single table, grouped by functionality
-- Supply the mode(s), key(s), command and description
local all_mappings = {
    -- ====================
    -- Common functionality
    -- ====================
    { { "n", "i", "v" }, "<C-s>",                      "<Cmd>w<CR>",                                    "Save file" },
    { "n",               "<C-q>",                      "<C-v>",                                         "Visual block" },

    -- =============================
    -- Line movement and indentation
    -- =============================
    { "n",               "<C-Up>",                     ":m .-2<CR>==",                                  "Move line up" },
    { "n",               "<C-Down>",                   ":m .+1<CR>==",                                  "Move line down" },
    { "n",               "<C-Left>",                   "<<hhhh",                                        "Unindent line" },
    { "n",               "<C-Right>",                  ">>llll",                                        "Indent line" },
    { "v",               "<C-Up>",                     ":m '<-2<CR>gv=gv",                              "Move line up" },
    { "v",               "<C-Down>",                   ":m '>+1<CR>gv=gv",                              "Move line down" },
    { "v",               "<C-Left>",                   "<gvhhhh",                                       "Unindent line" },
    { "v",               "<C-Right>",                  ">gvllll",                                       "Indent line" },

    -- ==============
    -- Selecting text
    -- ==============
    -- Normal mode
    { "n",               "<S-Down>",                   "vj",                                            "Select down" },
    { "n",               "<S-Up>",                     "vk",                                            "Select up" },
    { "n",               "<S-Left>",                   "vh",                                            "Select left" },
    { "n",               "<S-Right>",                  "vl",                                            "Select right" },
    { "n",               "<S-Home>",                   "v^",                                            "Select to beginning of line" },
    { "n",               "<Home>",                     "^",                                             "Move to beginning of text" },
    { "n",               "<S-End>",                    "v$h",                                           "Select to end of line" },

    -- Insert mode
    { "i",               "<S-Up>",                     "<Esc>vkl",                                      "Select up" },
    { "i",               "<S-Down>",                   "<Esc>lvjh",                                     "Select down" },
    { "i",               "<S-Left>",                   "<Esc>v",                                        "Select left" },
    { "i",               "<S-Right>",                  "<Esc>lv",                                       "Select right" },
    { "i",               "<S-Home>",                   "<Esc>lv",                                       "Select to beginning of line" },
    { "i",               "<S-End>",                    "<Esc>lv$h",                                     "Select to end of line" },
    { "i",               "<Home>",                     "<Esc>^i",                                       "Move to beginning of text" },

    -- Visual mode
    { "v",               "<S-Up>",                     "k",                                             "Move up" },
    { "v",               "<S-Down>",                   "j",                                             "Move down" },
    { "v",               "<S-Left>",                   "h",                                             "Move left" },
    { "v",               "<S-Right>",                  "l",                                             "Move right" },
    { "v",               "<S-Home>",                   "0",                                             "Move to beginning of line" },
    { "v",               "<Home>",                     "^",                                             "Move to beginning of text" },
    { "v",               "<S-End>",                    "$",                                             "Move to end of line" },
    { "v",               "<End>",                      "$h",                                            "Move to end of line" },

    -- Select all with Ctrl + A
    { "n",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "v",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "i",               "<C-a>",                      "<Esc>ggVG",                                     "Select all" },

    -- ==============
    -- Copy and paste
    -- ==============
    { "v",               "<C-c>",                      '"+y',                                           "Copy" },
    { "v",               "<C-x>",                      '"+x',                                           "Cut" },
    { "x",               "<C-v>",                      '"0dP',                                          "Paste without overwriting unnamed reg" },
    { "i",               "<C-v>",                      "<C-o>P",                                        "Paste" },

    -- ==================
    -- Search and replace
    -- ==================
    { "n",               "<leader>s",                  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>", "Search and replace" },
    { "n",               "<Esc>",                      ":let @/=''<CR>",                                "Clear search highlight" },

    -- ============================
    -- Navigation with wrap enabled
    -- ============================
    { "n",               "j",                          'v:count ? "j" : "gj"',                          "Move down (smart)",                    true },
    { "n",               "k",                          'v:count ? "k" : "gk"',                          "Move up (smart)",                      true },
    { "x",               "j",                          'v:count ? "j" : "gj"',                          "Move down (smart)",                    true },
    { "x",               "k",                          'v:count ? "k" : "gk"',                          "Move up (smart)",                      true },
    { "n",               "<Up>",                       "gk",                                            "Move up (visual line)" },
    { "n",               "<Down>",                     "gj",                                            "Move down (visual line)" },
    { "x",               "<Up>",                       "gk",                                            "Move up (visual line)" },
    { "x",               "<Down>",                     "gj",                                            "Move down (visual line)" },

    -- ====================
    -- Surround replacement
    -- ====================
    { "v",               "'",                          "\"zc''<Esc>\"zP",                               "Add single quotes" },
    { "v",               '"',                          '"zc""<Esc>"zP',                                 "Add double quotes" },
    { "v",               "`",                          '"zc``<Esc>"zP',                                 "Add backticks" },
    { "v",               { "(", ")" },                 '"zc()<Esc>"zP',                                 "Add parentheses" },
    { "v",               { "[", "]" },                 '"zc[]<Esc>"zP',                                 "Add brackets" },
    { "v",               { "{", "}" },                 '"zc{}<Esc>"zP',                                 "Add curly braces" },
    { "v",               { "<", ">" },                 '"zc<><Esc>"zP',                                 "Add angle brackets" },

    -- Triple quotes
    { "v",               "<Leader>'",                  "\"zc''''''<Esc>2h\"zP",                         "Add triple single quotes" },
    { "v",               '<Leader>"',                  '"zc""""""<Esc>2h"zP',                           "Add triple double quotes" },
    { "v",               "<Leader>`",                  '"zc``````<Esc>2h"zP',                           "Add triple backticks" },

    -- Double brackets
    { "v",               { "<Leader>(", "<Leader>)" }, '"zc(())<Esc>2h"zp',                             "Add double parentheses" },
    { "v",               { "<Leader>[", "<Leader>]" }, '"zc[[]]<Esc>2h"zp',                             "Add double brackets" },
    { "v",               { "<Leader>{", "<Leader>}" }, '"zc{{}}<Esc>2h"zp',                             "Add double curly braces" },
    { "v",               { "<Leader><", "<Leader>>" }, '"zc<<>><Esc>2h"zp',                             "Add double angle brackets" },

    -- Markdown formatting
    { "v",               { "<Leader>b", "<Leader>*" }, '"zc****<Esc>2h"zp',                             "Add bold" },
    { "v",               { "<Leader>i", "<Leader>_" }, '"zc__<Esc>h"zp',                                "Add italic" },
    { "v",               "<Leader>s",                  '"zc~~<Esc>h"zp',                                "Add strikethrough" },
    -- Resize window left right
    { { "n", "i", "x" }, "<C-S-Left>",                 "<C-w>h",                                        "Resize window left" },
    { { "n", "i", "x" }, "<C-S-Right>",                "<C-w>l",                                        "Resize window right" },
}

-- Apply all the mappings
map(all_mappings)

-- =================
-- Function mappings
-- ================

-- Wrap and unwrap functions
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
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "list:2"
    return '<Cmd>vertical rightbelow new | set winbar="" nonumber norelativenumber<CR><C-w>h<C-w>'
        .. (vim.v.count ~= 0 and vim.v.count or 125)
        .. "|"
end, { expr = true, noremap = true, silent = true, desc = "Wrap by opening new window" })

-- Unwrap functionality
vim.keymap.set("n", "<leader>wu", function()
    vim.wo.wrap = false
    vim.wo.linebreak = false
    vim.wo.breakindent = false
    vim.wo.breakindentopt = ""
    vim.cmd("lua close_no_name_buffers()")
end, { noremap = true, silent = true, desc = "Unwrap current window" })

-- Insert mode special function mappings
local function move_cursor_visual(lines)
    local count = math.abs(lines)
    local key = lines > 0 and "gj" or "gk"
    vim.cmd.normal({ tostring(count) .. key, bang = true })
end

vim.keymap.set("i", "<Up>", function()
    move_cursor_visual(-1)
end, { noremap = true, silent = true, desc = "Move up in insert mode (visual line)" })

vim.keymap.set("i", "<Down>", function()
    move_cursor_visual(1)
end, { noremap = true, silent = true, desc = "Move down in insert mode (visual line)" })

vim.keymap.set("i", "<C-w>", "<C-o>dv<Plug>WordMotion_b", {
  noremap = false,  -- needed so <Plug> expands
  silent = true,
  desc = "Delete previous word (wordmotion-aware)",
})
vim.keymap.set("i", "<C-Del>", "<C-o>d<Plug>WordMotion_e", {
  noremap = false,
  silent = true,
  desc = "Ctrl-Delete = delete next word (wordmotion-aware)",
})



-- Fix cursor position when exiting insert mode
vim.keymap.set("i", "<Esc>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.schedule(function()
        local line_length = #vim.api.nvim_get_current_line()
        if col > 0 and col <= line_length then
            vim.api.nvim_win_set_cursor(0, { row, col })
        end
    end)
    return "<Esc>"
end, { expr = true, noremap = true, desc = "Exit insert mode preserving cursor position" })


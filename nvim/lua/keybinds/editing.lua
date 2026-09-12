local map = require("lib.keymap").rows

-- stylua: ignore
map({
    -- <leader>  leaves
    { "n",               "<leader>s",                  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>", "Search and replace" },
    { "n",               "<leader>m",                  function() require("lsp.format").buffer() end,       "Format buffer" },

    -- Common functionality
    { { "n", "i", "v" }, "<C-s>",                      "<Cmd>w<CR>",                                    "Save file" },
    { "n",               "<C-q>",                      "<C-v>",                                         "Visual block" },
    { "n",               "<Esc>",                      "<Cmd>nohlsearch<CR>",                           "Clear search highlight" },

    -- Line movement and indentation
    { "n",               "<C-Up>",                     ":silent! m .-2<CR>==",                          "Move line up" },
    { "n",               "<C-Down>",                   ":silent! m .+1<CR>==",                          "Move line down" },
    { "n",               "<C-Left>",                   "<<hhhh",                                        "Unindent line" },
    { "n",               "<C-Right>",                  ">>llll",                                        "Indent line" },
    { "x",               "v",                          function() require("lib.select_node").grow() end, "Grow selection to the enclosing node" },
    { "x",               "<C-Up>",                     ":<C-u>silent! '<,'>m '<-2<CR>gv=gv",            "Move line up" },
    { "x",               "<C-Down>",                   ":<C-u>silent! '<,'>m '>+1<CR>gv=gv",            "Move line down" },
    { "x",               "<C-Left>",                   "<gvhhhh",                                       "Unindent line" },
    { "x",               "<C-Right>",                  ">gvllll",                                       "Indent line" },

    -- Selecting text
    { "n",               "<S-Down>",                   "vj",                                            "Select down" },
    { "n",               "<S-Up>",                     "vk",                                            "Select up" },
    { "n",               "<S-Left>",                   "vh",                                            "Select left" },
    { "n",               "<S-Right>",                  "vl",                                            "Select right" },
    { "n",               "<S-Home>",                   "v^",                                            "Select to beginning of line" },
    { "n",               "<Home>",                     "^",                                             "Move to beginning of text" },
    { "n",               "<S-End>",                    "v$h",                                           "Select to end of line" },

    { "i",               "<S-Up>",                     "<Esc>vkl",                                      "Select up" },
    { "i",               "<S-Down>",                   "<Esc>lvjh",                                     "Select down" },
    { "i",               "<S-Left>",                   "<Esc>v",                                        "Select left" },
    { "i",               "<S-Right>",                  "<Esc>lv",                                       "Select right" },
    { "i",               "<S-Home>",                   "<Esc>lv",                                       "Select to beginning of line" },
    { "i",               "<S-End>",                    "<Esc>lv$h",                                     "Select to end of line" },
    { "i",               "<Home>",                     "<Esc>^i",                                       "Move to beginning of text" },

    { "x",               "<S-Up>",                     "k",                                             "Move up" },
    { "x",               "<S-Down>",                   "j",                                             "Move down" },
    { "x",               "<S-Left>",                   "h",                                             "Move left" },
    { "x",               "<S-Right>",                  "l",                                             "Move right" },
    { "x",               "<S-Home>",                   "0",                                             "Move to beginning of line" },
    { "x",               "<Home>",                     "^",                                             "Move to beginning of text" },
    { "x",               "<S-End>",                    "$",                                             "Move to end of line" },
    { "x",               "<End>",                      "$h",                                            "Move to end of line" },

    { "n",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "x",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "i",               "<C-a>",                      "<Esc>ggVG",                                     "Select all" },

    -- Some terminals send these for Home and End
    { { "n", "i", "v", "c", "t", "o" }, "<Find>",      "<Home>",                                        "Home" },
    { { "n", "i", "v", "c", "t", "o" }, "<Select>",    "<End>",                                         "End" },

    -- Copy and paste
    { "x",               "<C-c>",                      '"+y',                                           "Copy" },
    { "x",               "<C-x>",                      '"+x',                                           "Cut" },
    { "x",               "<C-v>",                      "P",                                             "Paste without yanking the replaced text" },
    { "i",               "<C-v>",                      "<C-o>P",                                        "Paste" },

    -- Navigation with wrap enabled
    { "n",               "j",                          'v:count ? "j" : "gj"',                          "Move down (smart)",                    true },
    { "n",               "k",                          'v:count ? "k" : "gk"',                          "Move up (smart)",                      true },
    { "x",               "j",                          'v:count ? "j" : "gj"',                          "Move down (smart)",                    true },
    { "x",               "k",                          'v:count ? "k" : "gk"',                          "Move up (smart)",                      true },
    { "n",               "<Up>",                       "gk",                                            "Move up (visual line)" },
    { "n",               "<Down>",                     "gj",                                            "Move down (visual line)" },
    { "x",               "<Up>",                       "gk",                                            "Move up (visual line)" },
    { "x",               "<Down>",                     "gj",                                            "Move down (visual line)" },

    -- Surround replacement
    { "x",               "'",                          "\"zc''<Esc>\"zP",                               "Add single quotes" },
    { "x",               '"',                          '"zc""<Esc>"zP',                                 "Add double quotes" },
    { "x",               "`",                          '"zc``<Esc>"zP',                                 "Add backticks" },
    { "x",               { "(", ")" },                 '"zc()<Esc>"zP',                                 "Add parentheses" },
    { "x",               { "[", "]" },                 '"zc[]<Esc>"zP',                                 "Add brackets" },
    { "x",               { "{", "}" },                 '"zc{}<Esc>"zP',                                 "Add curly braces" },
    { "x",               { "<", ">" },                 '"zc<><Esc>"zP',                                 "Add angle brackets" },

    { "x",               "<Leader>'",                  "\"zc''''''<Esc>2h\"zP",                         "Add triple single quotes" },
    { "x",               '<Leader>"',                  '"zc""""""<Esc>2h"zP',                           "Add triple double quotes" },
    { "x",               "<Leader>`",                  '"zc``````<Esc>2h"zP',                           "Add triple backticks" },

    { "x",               { "<Leader>(", "<Leader>)" }, '"zc(())<Esc>2h"zp',                             "Add double parentheses" },
    { "x",               { "<Leader>[", "<Leader>]" }, '"zc[[]]<Esc>2h"zp',                             "Add double brackets" },
    { "x",               { "<Leader>{", "<Leader>}" }, '"zc{{}}<Esc>2h"zp',                             "Add double curly braces" },
    { "x",               { "<Leader><", "<Leader>>" }, '"zc<<>><Esc>2h"zp',                             "Add double angle brackets" },

    { "x",               { "<Leader>b", "<Leader>*" }, '"zc****<Esc>2h"zp',                             "Add bold" },
    { "x",               { "<Leader>i", "<Leader>_" }, '"zc__<Esc>h"zp',                                "Add italic" },
    { "x",               "<Leader>s",                  '"zc~~<Esc>h"zp',                                "Add strikethrough" },

    -- <leader>c  Copilot
    { "n",               "<leader>cc",                 "<Cmd>Copilot<CR>",                              "Copilot" },
    { "n",               "<leader>cd",                 "<Cmd>Copilot disable<CR>",                      "Copilot disable" },
    { "n",               "<leader>ce",                 "<Cmd>Copilot enable<CR>",                       "Copilot enable" },
})

-- While the built-in gcc exists, gc waits timeoutlen for it
local toggle_comment_line = vim.fn.maparg("gcc", "n", false, true).callback
vim.keymap.del("n", "gcc")
map({ { "n", "gc", toggle_comment_line, "Toggle comment line", true } })

-- Insert-mode editing
local function move_cursor_visual(lines)
    local count = math.abs(lines)
    local key = lines > 0 and "gj" or "gk"
    vim.cmd.normal({ tostring(count) .. key, bang = true })
end

local function delete_word_backward()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then
        if row > 1 and vim.tbl_contains(vim.opt.backspace:get(), "eol") then
            local previous = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1]
            vim.api.nvim_buf_set_text(0, row - 2, #previous, row - 1, 0, { "" })
            vim.api.nvim_win_set_cursor(0, { row - 1, #previous })
        end
        return
    end
    local line = vim.api.nvim_get_current_line()

    -- Position cursor for normal-mode wordmotion (at EOL, back up one)
    vim.api.nvim_win_set_cursor(0, { row, math.min(col, #line - 1) })
    vim.fn["wordmotion#motion"](1, "n", "b", 0, {})
    local target_row, target = unpack(vim.api.nvim_win_get_cursor(0))
    -- Like the built-in <C-w>, only a delete from column 0 crosses the line break
    if target_row < row then
        target = 0
    end

    vim.api.nvim_buf_set_text(0, row - 1, target, row - 1, col, { "" })
    vim.api.nvim_win_set_cursor(0, { row, target })
end

local function delete_word_forward()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    if col >= #line then
        return
    end

    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.fn["wordmotion#motion"](1, "n", "e", 0, {})
    local target_row, target = unpack(vim.api.nvim_win_get_cursor(0))
    local stop = target_row > row and #line or target + 1

    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, stop, { "" })
    vim.api.nvim_win_set_cursor(0, { row, col })
end

map({
    { "i", "<Up>", function() move_cursor_visual(-1) end, "Move up in insert mode (visual line)" },
    { "i", "<Down>", function() move_cursor_visual(1) end, "Move down in insert mode (visual line)" },
    { "i", "<C-w>", delete_word_backward, "Delete previous word (wordmotion-aware)" },
    { "i", "<C-Del>", delete_word_forward, "Ctrl-Delete = delete next word (wordmotion-aware)" },
})

vim.keymap.set("i", "<Esc>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.schedule(function()
        local line_length = #vim.api.nvim_get_current_line()
        if col > 0 and col <= line_length then
            vim.api.nvim_win_set_cursor(0, { row, col })
        end
    end)
    return "<Esc>"
end, { expr = true, desc = "Exit insert mode preserving cursor position" })

-- Word selection
vim.keymap.set("n", "<C-S-Right>", "ve", { remap = true, desc = "Select word forward" })
vim.keymap.set("n", "<C-S-Left>", "vb", { remap = true, desc = "Select word backward" })
vim.keymap.set("x", "<C-S-Right>", "e", { remap = true, desc = "Extend selection word forward" })
vim.keymap.set("x", "<C-S-Left>", "b", { remap = true, desc = "Extend selection word backward" })
map({
    {
        "i",
        "<C-S-Left>",
        function()
            vim.cmd("stopinsert")
            vim.cmd("normal! v")
            vim.fn["wordmotion#motion"](1, "v", "b", 0, {})
        end,
        "Select word backward",
    },
})

-- Copilot in insert
local function suggestion_shown() return vim.fn["copilot#GetDisplayedSuggestion"]().text ~= "" end

vim.keymap.set(
    "i",
    "<C-j>",
    'copilot#Accept("\\<CR>")',
    { expr = true, replace_keycodes = false, desc = "Accept suggestion" }
)
vim.keymap.set("i", "<C-l>", "<Plug>(copilot-next)", { remap = true, desc = "Next suggestion" })
vim.keymap.set("i", "<C-h>", "<Plug>(copilot-previous)", { remap = true, desc = "Previous suggestion" })

local function accept_word_or_move()
    if suggestion_shown() then
        vim.api.nvim_feedkeys(vim.fn["copilot#AcceptWord"](), "n", false)
    else
        vim.fn["wordmotion#motion"](1, "n", "", 0, {})
    end
end

local function accept_line_or_select_word()
    if suggestion_shown() then
        vim.api.nvim_feedkeys(vim.fn["copilot#AcceptLine"](), "n", false)
        return
    end
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.cmd("stopinsert")
    -- stopinsert moves back one column
    local row = vim.api.nvim_win_get_cursor(0)[1]
    if col < #vim.api.nvim_get_current_line() then
        vim.api.nvim_win_set_cursor(0, { row, col })
    end
    vim.cmd("normal! v")
    vim.fn["wordmotion#motion"](1, "v", "e", 0, {})
end

map({
    { "i", "<C-Right>", accept_word_or_move, "Accept a word, or move a word" },
    { "i", "<C-Left>", function() vim.fn["wordmotion#motion"](1, "n", "b", 0, {}) end, "Move back a word" },
    { "i", "<C-S-Right>", accept_line_or_select_word, "Accept a line, or select a word" },
})

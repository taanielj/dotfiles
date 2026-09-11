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
    { "v",               "<C-Up>",                     ":<C-u>silent! '<,'>m '<-2<CR>gv=gv",            "Move line up" },
    { "v",               "<C-Down>",                   ":<C-u>silent! '<,'>m '>+1<CR>gv=gv",            "Move line down" },
    { "v",               "<C-Left>",                   "<gvhhhh",                                       "Unindent line" },
    { "v",               "<C-Right>",                  ">gvllll",                                       "Indent line" },

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

    { "v",               "<S-Up>",                     "k",                                             "Move up" },
    { "v",               "<S-Down>",                   "j",                                             "Move down" },
    { "v",               "<S-Left>",                   "h",                                             "Move left" },
    { "v",               "<S-Right>",                  "l",                                             "Move right" },
    { "v",               "<S-Home>",                   "0",                                             "Move to beginning of line" },
    { "v",               "<Home>",                     "^",                                             "Move to beginning of text" },
    { "v",               "<S-End>",                    "$",                                             "Move to end of line" },
    { "v",               "<End>",                      "$h",                                            "Move to end of line" },

    { "n",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "v",               "<C-a>",                      "ggVG",                                          "Select all" },
    { "i",               "<C-a>",                      "<Esc>ggVG",                                     "Select all" },

    -- Some terminals send these for Home and End
    { { "n", "i", "v", "c", "t", "o" }, "<Find>",      "<Home>",                                        "Home" },
    { { "n", "i", "v", "c", "t", "o" }, "<Select>",    "<End>",                                         "End" },

    -- Copy and paste
    { "v",               "<C-c>",                      '"+y',                                           "Copy" },
    { "v",               "<C-x>",                      '"+x',                                           "Cut" },
    { "x",               "<C-v>",                      '"0dP',                                          "Paste without overwriting unnamed reg" },
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
    { "v",               "'",                          "\"zc''<Esc>\"zP",                               "Add single quotes" },
    { "v",               '"',                          '"zc""<Esc>"zP',                                 "Add double quotes" },
    { "v",               "`",                          '"zc``<Esc>"zP',                                 "Add backticks" },
    { "v",               { "(", ")" },                 '"zc()<Esc>"zP',                                 "Add parentheses" },
    { "v",               { "[", "]" },                 '"zc[]<Esc>"zP',                                 "Add brackets" },
    { "v",               { "{", "}" },                 '"zc{}<Esc>"zP',                                 "Add curly braces" },
    { "v",               { "<", ">" },                 '"zc<><Esc>"zP',                                 "Add angle brackets" },

    { "v",               "<Leader>'",                  "\"zc''''''<Esc>2h\"zP",                         "Add triple single quotes" },
    { "v",               '<Leader>"',                  '"zc""""""<Esc>2h"zP',                           "Add triple double quotes" },
    { "v",               "<Leader>`",                  '"zc``````<Esc>2h"zP',                           "Add triple backticks" },

    { "v",               { "<Leader>(", "<Leader>)" }, '"zc(())<Esc>2h"zp',                             "Add double parentheses" },
    { "v",               { "<Leader>[", "<Leader>]" }, '"zc[[]]<Esc>2h"zp',                             "Add double brackets" },
    { "v",               { "<Leader>{", "<Leader>}" }, '"zc{{}}<Esc>2h"zp',                             "Add double curly braces" },
    { "v",               { "<Leader><", "<Leader>>" }, '"zc<<>><Esc>2h"zp',                             "Add double angle brackets" },

    { "v",               { "<Leader>b", "<Leader>*" }, '"zc****<Esc>2h"zp',                             "Add bold" },
    { "v",               { "<Leader>i", "<Leader>_" }, '"zc__<Esc>h"zp',                                "Add italic" },
    { "v",               "<Leader>s",                  '"zc~~<Esc>h"zp',                                "Add strikethrough" },

    -- <leader>c  Copilot
    { "n",               "<leader>cc",                 "<Cmd>Copilot<CR>",                              "Copilot" },
    { "n",               "<leader>cd",                 "<Cmd>Copilot disable<CR>",                      "Copilot disable" },
    { "n",               "<leader>ce",                 "<Cmd>Copilot enable<CR>",                       "Copilot enable" },
})

-- Insert-mode editing
local function move_cursor_visual(lines)
    local count = math.abs(lines)
    local key = lines > 0 and "gj" or "gk"
    vim.cmd.normal({ tostring(count) .. key, bang = true })
end

vim.keymap.set(
    "i",
    "<Up>",
    function() move_cursor_visual(-1) end,
    { silent = true, desc = "Move up in insert mode (visual line)" }
)

vim.keymap.set(
    "i",
    "<Down>",
    function() move_cursor_visual(1) end,
    { silent = true, desc = "Move down in insert mode (visual line)" }
)

vim.keymap.set("i", "<C-w>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then
        return
    end
    local line = vim.api.nvim_get_current_line()

    -- Position cursor for normal-mode wordmotion (at EOL, back up one)
    vim.api.nvim_win_set_cursor(0, { row, math.min(col, #line - 1) })
    vim.fn["wordmotion#motion"](1, "n", "b", 0, {})
    local _, target = unpack(vim.api.nvim_win_get_cursor(0))

    vim.api.nvim_buf_set_text(0, row - 1, target, row - 1, col, { "" })
    vim.api.nvim_win_set_cursor(0, { row, target })
end, { silent = true, desc = "Delete previous word (wordmotion-aware)" })

vim.keymap.set("i", "<C-Del>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    if col >= #line then
        return
    end

    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.fn["wordmotion#motion"](1, "n", "e", 0, {})
    local _, target = unpack(vim.api.nvim_win_get_cursor(0))

    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, target + 1, { "" })
    vim.api.nvim_win_set_cursor(0, { row, col })
end, { silent = true, desc = "Ctrl-Delete = delete next word (wordmotion-aware)" })

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
vim.keymap.set("i", "<C-S-Left>", function()
    vim.cmd("stopinsert")
    vim.cmd("normal! v")
    vim.fn["wordmotion#motion"](1, "v", "b", 0, {})
end, { silent = true, desc = "Select word backward" })

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

vim.keymap.set("i", "<C-Right>", function()
    if suggestion_shown() then
        vim.api.nvim_feedkeys(vim.fn["copilot#AcceptWord"](), "n", false)
    else
        vim.fn["wordmotion#motion"](1, "n", "", 0, {})
    end
end, { silent = true, desc = "Accept a word, or move a word" })

vim.keymap.set(
    "i",
    "<C-Left>",
    function() vim.fn["wordmotion#motion"](1, "n", "b", 0, {}) end,
    { silent = true, desc = "Move back a word" }
)

vim.keymap.set("i", "<C-S-Right>", function()
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
end, { silent = true, desc = "Accept a line, or select a word" })

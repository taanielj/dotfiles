-- A row in `all_mappings` when a mapping fits on a line, a vim.keymap.set call
-- below when it needs a function body. Leader maps are sectioned by prefix,
-- matching `groups`, which which-key reads. Buffer-local maps live with what
-- scopes them, and a plugin's lazy-load triggers stay in its `keys`.

-- Leader must be set before plugins load
vim.g.mapleader = " "

-- A prefix has no mapping of its own to carry a desc
local groups = {
    { "<leader>a",  group = "AI/Claude Code" },
    { "<leader>b",  group = "Buffer" },
    { "<leader>bc", group = "Close" },
    { "<leader>bs", group = "Sort" },
    { "<leader>c",  group = "Copilot / Codesnap" },
    { "<leader>f",  group = "Find" },
    { "<leader>g",  group = "Git" },
    { "<leader>h",  group = "Find hidden" },
    { "<leader>l",  group = "LSP" },
    { "<leader>q",  group = "Close" },
    { "<leader>qf", group = "Force quit" },
    { "<leader>y",  group = "Yank" },
}

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

local all_mappings = {
    -- ==================
    -- <leader>b  Buffer
    -- ==================
    { "n",               "<leader>bn",                 "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n",               "<leader>bp",                 "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n",               "<Tab>",                      "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n",               "<S-Tab>",                    "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n",               "<leader>bh",                 "<Cmd>BufferLineMovePrev<CR>",                   "Move buffer left" },
    { "n",               "<leader>bl",                 "<Cmd>BufferLineMoveNext<CR>",                   "Move buffer right" },
    { "n",               "<leader>bP",                 "<Cmd>BufferLinePick<CR>",                       "Pick buffer" },
    { "n",               "<leader>bt",                 "<Cmd>BufferLineTogglePin<CR>",                  "Pin buffer" },
    { "n",               { "ZZ", "<leader>bq", "<leader>qb" }, function() require("ui.buffers").close() end, "Save and close buffer" },
    -- <leader>bc  Close
    { "n",               "<leader>bch",                "<Cmd>BufferLineCloseLeft<CR>",                  "Close buffers to the left" },
    { "n",               "<leader>bcl",                "<Cmd>BufferLineCloseRight<CR>",                 "Close buffers to the right" },
    { "n",               "<leader>bca",                "<Cmd>BufferLineCloseOthers<CR>",                "Close other buffers" },
    -- <leader>bs  Sort
    { "n",               "<leader>bsd",                "<Cmd>BufferLineSortByDirectory<CR>",            "Sort by directory" },
    { "n",               "<leader>bst",                "<Cmd>BufferLineSortByTabs<CR>",                 "Sort by tabs" },
    { "n",               "<leader>bse",                "<Cmd>BufferLineSortByExtension<CR>",            "Sort by extension" },

    -- =================
    -- <leader>q  Close
    -- =================
    { "n",               "<leader>q!",                 function() require("ui.buffers").close({ force = true }) end, "Close buffer without saving" },
    { "n",               "<leader>qa",                 "<Cmd>wa<CR><Cmd>qa<CR>",                        "Quit and save all" },
    { "n",               "<leader>qfy",                "<Cmd>qa!<CR>",                                  "Quit without saving?" },

    -- =================
    -- <leader>  leaves
    -- =================
    -- Right-click uses Neovim's own popup_setpos; this is the keyboard route
    { "n",               "<leader>.",                  function() require("ui.menu").popup_at_cursor() end, "Open menu" },
    { "n",               "<leader>s",                  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>", "Search and replace" },
    { "n",               "<leader>m",                  function() require("format").buffer() end,       "Format buffer" },

    -- ====================
    -- Common functionality
    -- ====================
    { { "n", "i", "v" }, "<C-s>",                      "<Cmd>w<CR>",                                    "Save file" },
    { "n",               "<C-q>",                      "<C-v>",                                         "Visual block" },
    { "n",               "<Esc>",                      ":let @/=''<CR>",                                "Clear search highlight" },

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

    -- =============
    -- Resize splits
    -- =============
    { "n",               "<M-h>",                      "2<C-w><",                                       "Resize split left" },
    { "n",               "<M-l>",                      "2<C-w>>",                                       "Resize split right" },
    { "n",               "<M-j>",                      "2<C-w>+",                                       "Resize split down" },
    { "n",               "<M-k>",                      "2<C-w>-",                                       "Resize split up" },
    { "n",               "<M-H>",                      "<C-w><",                                        "Resize split left (fine)" },
    { "n",               "<M-L>",                      "<C-w>>",                                        "Resize split right (fine)" },
    { "n",               "<M-J>",                      "<C-w>+",                                        "Resize split down (fine)" },
    { "n",               "<M-K>",                      "<C-w>-",                                        "Resize split up (fine)" },

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
}

map(all_mappings)

-- ================
-- <leader>y  Yank
-- ================

vim.keymap.set("n", "<leader>yb", function()
    if vim.bo.modifiable then
        local path = vim.fn.expand("%:p")
        vim.fn.setreg("+", path)
        vim.notify(path, vim.log.levels.INFO, { title = "Yanked path" })
    end
end, { noremap = true, silent = true, desc = "Yank buffer absolute path" })

vim.keymap.set({ "n", "v" }, "<leader>yl", function()
    local line_start, line_end
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        line_start = vim.fn.line("v")
        line_end = vim.fn.line(".")
        if line_start > line_end then
            line_start, line_end = line_end, line_start
        end
    else
        line_start = vim.fn.line(".")
        line_end = line_start
    end
    local result = vim.fn.expand("%:p") .. ":" .. line_start
    if line_end ~= line_start then
        result = result .. "-" .. line_end
    end
    vim.fn.setreg("+", result)
    vim.notify(result, vim.log.levels.INFO, { title = "Yanked path:line" })
end, { noremap = true, silent = true, desc = "Yank buffer path with line" })

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

local function close_wrap_spacer(win)
    local spacer = spacer_by_window[win]
    spacer_by_window[win] = nil
    if spacer and vim.api.nvim_win_is_valid(spacer) then
        vim.api.nvim_win_close(spacer, true)
    end
end

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

-- ==========
-- :q  Quit
-- ==========

-- A diffview is closed as a whole, like ZZ and <leader>bq do, since :q on
-- one of its windows leaves the rest of the view behind.
vim.keymap.set("ca", "q", function()
    if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q" and require("ui.diffview").is_open() then
        return "DiffviewClose"
    end
    return "q"
end, { expr = true })

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

-- ===================
-- <leader>R  Restart
-- ===================

-- auto-session restores the cwd session on start; the save is forced here
-- rather than left to :restart's qall.
vim.keymap.set("n", "<leader>R", function()
    local unsaved = {}
    for _, info in ipairs(vim.fn.getbufinfo({ bufmodified = 1, buflisted = 1 })) do
        if vim.bo[info.bufnr].buftype == "" then
            unsaved[#unsaved + 1] = info.name ~= "" and vim.fn.fnamemodify(info.name, ":~:.") or "[No Name]"
        end
    end
    if #unsaved > 0 then
        vim.notify("Unsaved before restart: " .. table.concat(unsaved, ", "), vim.log.levels.WARN)
        return
    end

    require("auto-session").auto_save_session()

    -- noice's UI handler errors on the restart event, so it is detached first
    if package.loaded["noice"] then
        require("noice").disable()
    end
    vim.cmd.restart()
end, { desc = "Restart nvim, keeping the session" })

-- ===================
-- Insert-mode editing
-- ===================

vim.keymap.set("n", "i", function()
    vim.wo.relativenumber = false
    return "i"
end, { noremap = true, expr = true, silent = true, desc = "Insert mode without relative number" })

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

vim.keymap.set("i", "<C-w>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then return end
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
    if col >= #line then return end

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
end, { expr = true, noremap = true, desc = "Exit insert mode preserving cursor position" })

-- ==============
-- Word selection
-- ==============

vim.keymap.set("n", "<C-S-Right>", "ve", { remap = true, desc = "Select word forward" })
vim.keymap.set("n", "<C-S-Left>", "vb", { remap = true, desc = "Select word backward" })
vim.keymap.set("x", "<C-S-Right>", "e", { remap = true, desc = "Extend selection word forward" })
vim.keymap.set("x", "<C-S-Left>", "b", { remap = true, desc = "Extend selection word backward" })
vim.keymap.set("i", "<C-S-Left>", function()
    vim.cmd("stopinsert")
    vim.cmd("normal! v")
    vim.fn["wordmotion#motion"](1, "v", "b", 0, {})
end, { silent = true, desc = "Select word backward" })

-- ============
-- Command line
-- ============

-- Wildmenu pum: swap Up/Down (dir nav) with Left/Right (list nav)
vim.keymap.set("c", "<Up>", function()
    return vim.fn.pumvisible() == 1 and "<Left>" or "<Up>"
end, { expr = true })

vim.keymap.set("c", "<Down>", function()
    return vim.fn.pumvisible() == 1 and "<Right>" or "<Down>"
end, { expr = true })

vim.keymap.set("c", "<Left>", function()
    return vim.fn.pumvisible() == 1 and "<Up>" or "<Left>"
end, { expr = true })

vim.keymap.set("c", "<Right>", function()
    return vim.fn.pumvisible() == 1 and "<Down>" or "<Right>"
end, { expr = true })

return { groups = groups }

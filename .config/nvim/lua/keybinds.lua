-- since ctrl+v is used for paste in terminal, rebind VISUAL BLOCK to ctrl+q
vim.keymap.set("v", "<C-q>", "<C-v>", { noremap = true, silent = true, desc = "Visual block" })

vim.g.mapleader = " "
vim.keymap.set("n", "<leader><Tab>", ":BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
-- Normal mode move line up and down
vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })

-- Normal mode indent and unindent line (alternative to number >> and <<, works only on single line)
vim.keymap.set("n", "<C-Left>", "<<hhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("n", "<C-Right>", ">>llll", { noremap = true, silent = true, desc = "Indent line" })

-- Visual mode move line(s) up and down
vim.keymap.set("v", "<C-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("v", "<C-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move line down" })

-- Visual mode indent and unindent
vim.keymap.set("v", "<C-Left>", "<gvhhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("v", "<C-Right>", ">gvllll", { noremap = true, silent = true, desc = "Indent line" })

-- shift hjkl or arrow key opens visual mode and selects text like in vscode
vim.keymap.set("n", "<S-Up>", "vk", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("n", "<S-Down>", "vj", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("n", "<S-Left>", "vh", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("n", "<S-Right>", "vl", { noremap = true, silent = true, desc = "Move right" })

-- enter visual mode from insert with shift hjkl or arrow key
vim.keymap.set("i", "<S-Up>", "<Esc>vkl", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("i", "<S-Down>", "<Esc>lvj", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("i", "<S-Left>", "<Esc>v", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("i", "<S-Right>", "<Esc>lv", { noremap = true, silent = true, desc = "Move right" })

-- shift end home in insert mode enters visual mode and selects until beginnig or
vim.keymap.set("i", "<S-End>", "<Esc>v$", { noremap = true, silent = true, desc = "Move to end of line" })
vim.keymap.set("i", "<S-Home>", "<Esc>v^", { noremap = true, silent = true, desc = "Move to beginning of line" })

-- ctrl backspace in insert delete previous word
vim.keymap.set("i", "<C-H>", "<C-o>db", { noremap = true, silent = true, desc = "Delete previous word" })
-- ctrl delete in insert delete next (FROM CURSOR) word
vim.keymap.set("i", "<C-Delete>", "<C-o>de",
    { noremap = true, silent = true, desc = "Delete from cursor to end of word" })

-- ignore shift key in visual mode for arrows
vim.keymap.set("v", "<S-Up>", "k", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("v", "<S-Down>", "j", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("v", "<S-Left>", "h", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("v", "<S-Right>", "l", { noremap = true, silent = true, desc = "Move right" })

-- ctrl A select all in all modes
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true, silent = true, desc = "Select all" })
vim.keymap.set("v", "<C-a>", "<Esc>ggVG", { noremap = true, silent = true, desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { noremap = true, silent = true, desc = "Select all" })

-- ctrl C copy in visual mode
vim.keymap.set("x", "<C-c>", '"+y', { noremap = true, silent = true, desc = "Copy" })
-- ctrl X cut in visual mode
vim.keymap.set("x", "<C-x>", '"+x', { noremap = true, silent = true, desc = "Cut" })
-- ctrl V paste in visual mode
vim.keymap.set("x", "<C-v>", '"+p', { noremap = true, silent = true, desc = "Paste" })
-- ctrl V paste in insert mode
vim.keymap.set("i", "<C-v>", '<Left><C-o>"+p', { noremap = true, silent = true, desc = "Paste" })
-- ctrl V paste in normal mode - just ctrl v twice, 1st time enters visual-block mode, 2nd pastes

vim.keymap.set("n", "<Tab>", "<C-w>w", { noremap = true, silent = true, desc = "Next window" })

vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>",
    { noremap = true, silent = true, desc = "Search and replace" })
-- ctrl f to open search (just open : and type /)
vim.keymap.set("n", "<C-f>", ":/<Right>", { noremap = true, silent = true, desc = "Search" })
vim.keymap.set("i", "<C-f>", "<Esc>:/<Right>", { noremap = true, silent = true, desc = "Search" })
vim.keymap.set("x", "<C-f>", "<Esc>:/<Right>", { noremap = true, silent = true, desc = "Search" })
-- ctrl-shift-f to open search in files using telescope (space f g)
vim.keymap.set("n", "<C-S-f>", ":Telescope live_grep<CR>", { noremap = true, silent = true, desc = "Search in files" })
vim.keymap.set("i", "<C-S-f>", "<Esc>:Telescope live_grep<CR>",
    { noremap = true, silent = true, desc = "Search in files" })
vim.keymap.set("x", "<C-S-f>", "<Esc>:Telescope live_grep<CR>",
    { noremap = true, silent = true, desc = "Search in files" })

-- clear last search highlight
vim.keymap.set("n", "<leader><CR>", ":let @/=''<CR>", { noremap = true, silent = true, desc = "Clear search highlight" })
-- saving
vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true, desc = "Save" })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { noremap = true, silent = true, desc = "Save" })
vim.keymap.set("x", "<C-s>", "<Esc>:w<CR>", { noremap = true, silent = true, desc = "Save" })
-- save all
vim.keymap.set("n", "<C-S-s>", ":wa<CR>", { noremap = true, silent = true, desc = "Save all" })
vim.keymap.set("i", "<C-S-s>", "<Esc>:wa<CR>a", { noremap = true, silent = true, desc = "Save all" })
vim.keymap.set("x", "<C-S-s>", "<Esc>:wa<CR>", { noremap = true, silent = true, desc = "Save all" })
-- quit and save all
vim.keymap.set("n", "<Leader>qq", ":wa<CR>:q<CR>", { noremap = true, silent = true, desc = "Quit and save all" })

-- home and end in insert mode
vim.keymap.set("i", "<Home>", "<Esc>0i", { noremap = true, silent = true, desc = "Move to beginning of line" })
vim.keymap.set("i", "<End>", "<Esc>$a", { noremap = true, silent = true, desc = "Move to end of line" })



-- prevent pasting from overwriting system clipboard
vim.keymap.set('x', '<C-v>', '"+gP', { noremap = true, silent = true })


-- toggle wrapping at 120 characters
vim.keymap.set('n', '<leader>sw',
    function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
        return '<Cmd>vertical rightbelow new | set winbar="" nonumber norelativenumber<CR><C-w>h<C-w>' ..
            (vim.v.count ~= 0 and vim.v.count or 125) .. '|'
    end, { expr = true })
-- remap j and k to move visual line by line
vim.keymap.set('n', 'j', 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set('n', 'k', 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap gj and gk to move visual line by line
vim.keymap.set('x', 'j', 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set('x', 'k', 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap arrow keys in all modes to move visual line by line
vim.keymap.set('n', '<Up>', 'gk', { noremap = true })
vim.keymap.set('n', '<Down>', 'gj', { noremap = true })
vim.keymap.set('x', '<Up>', 'gk', { noremap = true })
vim.keymap.set('x', '<Down>', 'gj', { noremap = true })
vim.keymap.set('i', '<Up>', '<C-o>gk', { noremap = true })
vim.keymap.set('i', '<Down>', '<C-o>gj', { noremap = true })

vim.keymap.set({'n', 'v', 'x', 'o'}, '<Del>', 'col(".") == col("$") ? "Jx" : "x"', { noremap = true, expr = true })

vim.g.mapleader = " "
vim.keymap.set("n", "<leader><Tab>", ":BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
-- Normal mode move line up and down
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })

-- Normal mode indent and unindent line (alternative to number >> and <<, works only on single line)
vim.keymap.set("n", "<C-h>", "<<hhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("n", "<C-l>", ">>llll", { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set("n", "<C-Left>", "<<hhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("n", "<C-Right>", ">>llll", { noremap = true, silent = true, desc = "Indent line" })

-- Visual mode move line(s) up and down
vim.keymap.set("v", "<C-j>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("v", "<C-k>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("v", "<C-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("v", "<C-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move line down" })

-- Visual mode indent and unindent
vim.keymap.set("v", "<C-h>", "<gvhhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("v", "<C-l>", ">gvllll", { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set("v", "<C-Left>", "<gvhhhh", { noremap = true, silent = true, desc = "Unindent line" })
vim.keymap.set("v", "<C-Right>", ">gvllll", { noremap = true, silent = true, desc = "Indent line" })

-- shift hjkl or arrow key opens visual mode and selects text like in vscode
vim.keymap.set("n", "<S-j>", "vj", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("n", "<S-k>", "vk", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("n", "<S-h>", "vh", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("n", "<S-l>", "vl", { noremap = true, silent = true, desc = "Move right" })

vim.keymap.set("n", "<S-Up>", "vk", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("n", "<S-Down>", "vj", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("n", "<S-Left>", "vh", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("n", "<S-Right>", "vl", { noremap = true, silent = true, desc = "Move right" })

-- enter visual mode from insert with shift hjkl or arrow key
vim.keymap.set("i", "<S-Up>", "<Esc>vkl", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("i", "<S-Down>", "<Esc>lvj", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("i", "<S-Left>", "<Esc>v", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("i", "<S-Right>", "<Esc>lv", { noremap = true, silent = true, desc = "Move right" })

-- shift end home in insert mode enters visual mode and selects until beginnig or end of line
vim.keymap.set("i", "<S-End>", "<Esc>v$", { noremap = true, silent = true, desc = "Move to end of line" })
vim.keymap.set("i", "<S-Home>", "<Esc>v^", { noremap = true, silent = true, desc = "Move to beginning of line" })

-- ctrl backspace in insert delete previous word
vim.keymap.set("i", "<C-H>", "<C-o>db", { noremap = true, silent = true, desc = "Delete previous word" })
-- ctrl delete in insert delete next (FROM CURSOR) word
vim.keymap.set("i", "<C-Delete>", "<C-o>de", { noremap = true, silent = true, desc = "Delete from cursor to end of word" })

-- ignore shift key in visual mode
vim.keymap.set("v", "<S-k>", "k", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("v", "<S-j>", "j", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("v", "<S-h>", "h", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("v", "<S-l>", "l", { noremap = true, silent = true, desc = "Move right" })

vim.keymap.set("v", "<S-Up>", "k", { noremap = true, silent = true, desc = "Move up" })
vim.keymap.set("v", "<S-Down>", "j", { noremap = true, silent = true, desc = "Move down" })
vim.keymap.set("v", "<S-Left>", "h", { noremap = true, silent = true, desc = "Move left" })
vim.keymap.set("v", "<S-Right>", "l", { noremap = true, silent = true, desc = "Move right" })

-- ctrl A select all in all modes
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true, silent = true, desc = "Select all" })
vim.keymap.set("v", "<C-a>", "<Esc>ggVG", { noremap = true, silent = true, desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { noremap = true, silent = true, desc = "Select all" })

-- ctrl C copy in visual mode
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true, desc = "Copy" })

vim.keymap.set("n", "<Tab>", "<C-w>w", { noremap = true, silent = true, desc = "Next window" })

vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>", { noremap = true, silent = true, desc = "Search and replace" })

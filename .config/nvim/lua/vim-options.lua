vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.g.mapleader = " "
-- set leader + tab to switch between buffers
vim.api.nvim_set_keymap("n", "<leader><Tab>", ":bnext<CR>", { noremap = true, silent = true , desc = "Next buffer" })

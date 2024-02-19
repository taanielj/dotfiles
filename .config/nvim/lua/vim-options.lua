vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
-- use relative line numbers while in normal mode
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    pattern = "*",
    command = "set norelativenumber",
})

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    pattern = "*",
    command = "set relativenumber",
})

vim.g.mapleader = " "
vim.keymap.set("n", "<leader><Tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })

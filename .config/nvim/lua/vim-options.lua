vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")

vim.opt.smartindent = true


-- undo setup
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.opt.scrolloff = 10

-- search stuff
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true


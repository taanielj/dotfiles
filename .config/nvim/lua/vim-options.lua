vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set clipboard=unnamedplus")


-- undo setup
vim.opt.swapfile = false
vim.opt.backup = false


-- search stuff
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.cmd("set colorcolumn=121")

-- set persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- wrap lines
vim.opt.textwidth = 120
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.whichwrap = "b,s,<,>,[,],~"


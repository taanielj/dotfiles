vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set clipboard=unnamedplus")
vim.cmd("set mousemoveevent")
-- undo setup
vim.opt.swapfile = false
vim.opt.backup = false

-- search stuff
vim.opt.hlsearch = true  -- highlight search results
vim.opt.incsearch = true -- incremental search
vim.opt.smartcase = true -- ignore case if search pattern is all lowercase

-- colorscheme support (for true color in kitty/tmux/windows terminal)
vim.opt.termguicolors = true

vim.cmd("set colorcolumn=121")

-- set persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"


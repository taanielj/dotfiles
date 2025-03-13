vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set clipboard=unnamedplus")
vim.cmd("set scroll=5")
vim.o.mousemoveevent = true
vim.opt.scroll = 5
-- undo setup
vim.opt.swapfile = false
vim.opt.backup = false

-- search stuff
vim.opt.hlsearch = true    -- highlight search results
vim.opt.incsearch = true   -- incremental search
-- Unless \C or capital letter in search pattern, search is case-insensitive
vim.opt.ignorecase = true  -- ignore case when searching
vim.opt.smartcase = true   -- ignore case if search pattern is all lowercase
vim.opt.signcolumn = "yes" -- always show sign column

vim.opt.listchars = {
    tab = "▸ ",
    trail = "•",
    extends = "❯",
    precedes = "❮",
    nbsp = "␣",
}
vim.opt.inccommand = "split" -- show live preview of substitution
-- colorscheme support (for true color in kitty/tmux/windows terminal)
vim.opt.termguicolors = true

vim.cmd("set colorcolumn=121")

-- set persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"



vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
    focusable = false,
})

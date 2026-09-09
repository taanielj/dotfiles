vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
-- WSL: the built-in provider uses win32yank.exe from PATH (installed by setup/win32yank.sh).
vim.opt.clipboard = "unnamedplus"
vim.opt.scroll = 5
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"
vim.o.mousemoveevent = true
vim.opt.swapfile = false

-- Unless \C or capital letter in search pattern, search is case-insensitive
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes:2" -- a git sign and a diagnostic on the same line

vim.opt.listchars = {
    tab = "▸ ",
    trail = "•",
    extends = "❯",
    precedes = "❮",
    nbsp = "␣",
}
vim.opt.inccommand = "split"
vim.opt.termguicolors = true

vim.opt.colorcolumn = "121"

vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.o.timeoutlen = 200 -- how long which-key waits before showing the popup
vim.o.updatetime = 300 -- how long CursorHold waits, which drives the LSP reference highlights
vim.opt.sessionoptions:remove("blank") -- nameless windows (fidget, wrap spacers) would come back as empty splits

-- Folds come from ufo; every fold starts open
local icons = require("ui.icons")
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "1"
vim.o.foldnestmax = 1
vim.o.foldminlines = 1
vim.opt.fillchars = {
    eob = " ",
    fold = ".",
    foldopen = icons.fold_open,
    foldsep = " ",
    foldclose = icons.fold_closed,
}

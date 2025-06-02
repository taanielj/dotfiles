vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set clipboard=unnamedplus")
vim.cmd("set scroll=5")
vim.cmd("set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175")
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



vim.lsp.handlers["textDocument/hover"] = function(err, result, _, config)
  if err or not result or not result.contents then return end

  local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
  if vim.tbl_isempty(lines) then return end

  return vim.lsp.util.open_floating_preview(lines, "markdown", vim.tbl_deep_extend("force", config or {}, {
    border = "rounded",
    focusable = false,
  }))
end


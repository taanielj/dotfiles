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
vim.opt.backup = false

vim.opt.hlsearch = true
vim.opt.incsearch = true
-- Unless \C or capital letter in search pattern, search is case-insensitive
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"

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



vim.keymap.set({"n","i","v","c","t","o"}, "<Find>",   "<Home>", { remap = true })
vim.keymap.set({"n","i","v","c","t","o"}, "<Select>", "<End>",  { remap = true })

vim.lsp.handlers["textDocument/hover"] = function(err, result, _, config)
  if err or not result or not result.contents then return end

  local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
  if vim.tbl_isempty(lines) then return end

  return vim.lsp.util.open_floating_preview(lines, "markdown", vim.tbl_deep_extend("force", config or {}, {
    border = "rounded",
    focusable = false,
  }))
end

vim.o.timeoutlen = 200 -- how long which-key waits before showing the popup
vim.opt.sessionoptions:remove("blank") -- nameless windows (fidget, wrap spacers) would come back as empty splits

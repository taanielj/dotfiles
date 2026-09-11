local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("core.options")
require("keybinds")
require("core.autocmds")
require("ui.md2html")
require("menus").setup()
require("lazy").setup({
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.coding" },
    { import = "plugins.tools" },
})

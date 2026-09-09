local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("core.options") -- Basic vim options
require("keybinds")    -- Keybinds
require("zen")         -- Zen mode
require("core.autocmds")     -- Autocommands
require("md2html")     -- Yank markdown as HTML
require("menus").setup()
require("lazy").setup({
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.coding" },
    { import = "plugins.tools" },
})

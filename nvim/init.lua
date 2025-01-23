

-- Set up the lazy loader
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

-- Load ./lua/vim-options.lua Options such as tabstop, linenumbers etc 
require("vim-options")
-- Load .lua/keybinds.lua Contains keybinds not related to plugins
require("keybinds")
-- load plugins automatically in lua/plugins folder
require("lazy").setup("plugins")


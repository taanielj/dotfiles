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

require("vim-options") -- Basic vim options
require("keybinds")    -- Keybinds
require("zen")         -- Zen mode
require("autocmd")     -- Autocommands
require("md2html")     -- Yank markdown as HTML
require("ui.menu").setup() -- Entries added to Neovim's right-click menu
require("lazy").setup({
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.coding" },
    { import = "plugins.tools" },
})

-- A require-based reload cannot reach lazy's plugin specs, so restart instead
vim.keymap.set("n", "<leader>R", "<Cmd>restart<CR>", { noremap = true, silent = true, desc = "Restart nvim" })

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

require("vim-options") -- Basic vim options
require("keybinds")    -- Keybinds
require("autocmd")     -- Autocommands
-- load plugins automatically in lua/plugins folder
require("lazy").setup("plugins")

function ReloadPlugins()
    local plugin_path = vim.fn.stdpath("config") .. "/lua/plugins/"
    local lua_files = vim.fn.glob(plugin_path .. "*.lua", false, true)
    for _, file in ipairs(lua_files) do
        local lua_file = file:match("lua/(.-)%.lua") -- find all *.lua files in lua/plugins folder
        if lua_file then                       -- truthy check, if file match is not nil
            package.loaded[lua_file] = nil     -- unload the plugin
            require(lua_file)                  -- require the plugin
        end
    end
end

function LoadConfig()
    require("vim-options")
    require("keybinds")
    require("autocmd")
    require("mouse")
    ReloadPlugins()
end

vim.keymap.set("n", "<leader>R", LoadConfig, { noremap = true, silent = true, desc = "Reload Config" })
-- nvim/init.lua (if your color scheme does not already provide these highlight groups)

vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })

-- Every global mapping, split by area. A plugin that loads at startup has
-- its keys here too, with the require inside the function; a plugin that
-- loads on a key keeps that key as `keys` in its spec, since that is what
-- loads it. Buffer-local maps live with what scopes them.

-- Leader must be set before plugins load
vim.g.mapleader = " "

-- A prefix has no mapping of its own to carry a desc
-- stylua: ignore
local groups = {
    { "<leader>a",  group = "AI/Claude Code" },
    { "<leader>b",  group = "Buffer" },
    { "<leader>bc", group = "Close" },
    { "<leader>bs", group = "Sort" },
    { "<leader>c",  group = "Copilot / Codesnap" },
    { "<leader>d",  group = "Debug" },
    { "<leader>f",  group = "Find" },
    { "<leader>g",  group = "Git" },
    { "<leader>h",  group = "Find hidden" },
    { "<leader>l",  group = "LSP" },
    { "<leader>q",  group = "Close" },
    { "<leader>qf", group = "Force quit" },
    { "<leader>y",  group = "Yank" },
    { "gz",         group = "Surround" },
}

require("keybinds.buffers")
require("keybinds.editing")
require("keybinds.find")
require("keybinds.view")
require("keybinds.yank")
require("keybinds.cmdline")

return { groups = groups }

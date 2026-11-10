-- Every global mapping, split by area.
-- - A plugin that loads at startup has its keys here, with the require inside
--   the function.
-- - A plugin that loads on a key declares that key as `keys` in its spec,
--   because that key loads it.
-- - Buffer-local maps are set in the module that creates the buffer.

-- Leader must be set before plugins load
vim.g.mapleader = " "

-- Labels for prefixes, which have no mapping to put a desc on
-- stylua: ignore
local groups = {
    { "=",          group = "Calculate" },
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

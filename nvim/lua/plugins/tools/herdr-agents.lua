-- Upstream requires HERDR_SOCKET_PATH, which only a herdr pane has.
local inside_herdr = require("lib.herdr").socket() ~= nil

return {
    "ctbaum/herdr-agents.nvim",
    cond = inside_herdr,
    lazy = false,
    dependencies = {
        { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
        { "ishiooon/codex.nvim", dependencies = { "folke/snacks.nvim" } },
    },
    opts = {},
}

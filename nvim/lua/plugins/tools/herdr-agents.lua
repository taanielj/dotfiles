-- Gated on HERDR_SOCKET_PATH per upstream; only loads inside a herdr session.
local inside_herdr = require("lib.herdr").socket() ~= nil

return {
    "ctbaum/herdr-agents.nvim",
    cond = inside_herdr,
    lazy = false,
    dependencies = {
        { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
        { "ishiooon/codex.nvim",   dependencies = { "folke/snacks.nvim" } },
    },
    opts = {},
}

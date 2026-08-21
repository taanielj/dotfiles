-- Bridges Claude Code / Codex agents into herdr sibling panes while keeping
-- their nvim connection (MCP, selections, diagnostics, native diffs).
-- Gated on HERDR_SOCKET_PATH per upstream; only loads inside a herdr session.
local inside_herdr = vim.env.HERDR_SOCKET_PATH ~= nil and vim.env.HERDR_SOCKET_PATH ~= ""

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

return {
    "ctbaum/herdr-agents.nvim",
    cond = require("lib.herdr").inside(),
    lazy = false,
    dependencies = {
        { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
        { "ishiooon/codex.nvim", dependencies = { "folke/snacks.nvim" } },
    },
    opts = function() return { claude = { opts = { port_range = require("lib.claude_port").reuse() } } } end,
    config = function(_, opts)
        require("herdr-agents").setup(opts)
        local remember = require("lib.claude_port").remember
        -- saved once the server is up, and again on exit in case the port changed
        vim.defer_fn(remember, 2000)
        vim.api.nvim_create_autocmd("VimLeavePre", { callback = remember })
    end,
}

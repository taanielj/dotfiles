return {
    "ctbaum/herdr-agents.nvim",
    -- main requires herdr-agents.status, which that commit never added
    commit = "ed5774360f61a6de155657769d7d84a32037972f",
    cond = require("lib.herdr").inside(),
    -- setup starts the claudecode server that an agent pane attaches to
    event = "VeryLazy",
    dependencies = {
        { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
        { "ishiooon/codex.nvim", dependencies = { "folke/snacks.nvim" } },
    },
    opts = function() return { claude = { opts = { port_range = require("lib.claude_port").reuse() } } } end,
    config = function(_, opts)
        require("herdr-agents").setup(opts)
        local remember = require("lib.claude_port").remember
        local ide_name = require("lib.claude_ide_name")
        ide_name.setup()
        remember()
        ide_name.write()
        -- a restarted server can come up on another port
        vim.api.nvim_create_autocmd("VimLeavePre", { callback = remember })
    end,
}

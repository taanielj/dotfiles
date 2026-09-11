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
        local ide_name = require("lib.claude_ide_name")
        ide_name.setup()
        -- saved once the server is up, and again on exit in case the port changed
        vim.defer_fn(function()
            remember()
            ide_name.write()
        end, 2000)
        vim.api.nvim_create_autocmd("VimLeavePre", { callback = remember })
    end,
}

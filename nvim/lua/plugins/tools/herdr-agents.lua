return {
    "ctbaum/herdr-agents.nvim",
    cond = require("lib.herdr").inside(),
    lazy = false,
    dependencies = {
        { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
        { "ishiooon/codex.nvim", dependencies = { "folke/snacks.nvim" } },
    },
    opts = {},
}

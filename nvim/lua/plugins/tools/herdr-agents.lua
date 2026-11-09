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
        -- The agent pane splits off right, with no option to change it; this
        -- turns that split downwards
        local herdr = require("herdr-agents.herdr")
        local json = herdr.json
        herdr.json = function(args)
            if args[1] == "pane" and args[2] == "split" then
                args = vim.deepcopy(args)
                args[vim.fn.index(args, "--direction") + 2] = "down"
            end
            return json(args)
        end
        require("herdr-agents").setup(opts)
        require("lib.claude_port").track()
        require("lib.claude_ide_name").setup()
    end,
}

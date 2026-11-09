-- Inside herdr, herdr-agents.nvim calls claudecode.setup() itself with its pane
-- provider; a second setup() here would start the server twice. Inside the
-- Herdr app, lib/claude_app_terminal.lua is the pane provider.
local inside_herdr = require("lib.herdr").inside()

local inside_app = require("lib.herdr_app").inside()

-- Keys that depend on where Claude runs. Inside herdr or the Herdr app, a prompt
-- about the lines under the cursor goes to the Claude pane. Outside both,
-- Claude is a snacks window with layouts, which the pane providers ignore.
local pane_keys = {
    {
        "<leader>ap",
        function() require("ui.claude_prompt").prompt() end,
        mode = { "n", "x" },
        desc = "Prompt Claude about these lines",
    },
    { "<leader>ae", function() require("ui.claude_editor").toggle() end, desc = "Toggle Claude prompt draft" },
}
local window_keys = {
    -- A layout applies on a fresh open; close Claude first to switch.
    {
        "<leader>aF",
        function()
            require("claudecode.terminal").simple_toggle({
                snacks_win_opts = { position = "float", width = 0.95, height = 0.95 },
            })
        end,
        desc = "Toggle Claude (float)",
    },
}
local host_keys = (inside_herdr or inside_app) and pane_keys or window_keys

return {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = { terminal = { snacks_win_opts = { position = "bottom", height = 0.3 } } },
    config = function(_, opts)
        if inside_herdr then
            return
        end
        if not inside_app then
            return require("claudecode").setup(opts)
        end
        require("claudecode").setup(vim.tbl_deep_extend("force", opts, {
            port_range = require("lib.claude_port").reuse(),
            terminal = { provider = require("lib.claude_app_terminal") },
        }))
        require("lib.claude_port").track()
        require("lib.claude_ide_name").setup()
    end,
    cmd = {
        "ClaudeCode",
        "ClaudeCodeFocus",
        "ClaudeCodeSelectModel",
        "ClaudeCodeAdd",
        "ClaudeCodeSend",
        "ClaudeCodeTreeAdd",
        "ClaudeCodeStatus",
        "ClaudeCodeStart",
        "ClaudeCodeStop",
        "ClaudeCodeOpen",
        "ClaudeCodeClose",
        "ClaudeCodeDiffAccept",
        "ClaudeCodeDiffDeny",
        "ClaudeCodeCloseAllDiffs",
    },
    keys = vim.list_extend({
        { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
        {
            "<leader>as",
            "<cmd>ClaudeCodeTreeAdd<cr>",
            desc = "Add file",
            ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
        },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    }, host_keys),
}

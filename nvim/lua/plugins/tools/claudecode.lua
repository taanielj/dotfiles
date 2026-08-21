-- Inside herdr, herdr-agents.nvim calls claudecode.setup() itself with its pane
-- provider; a second setup() here would start the server twice.
local inside_herdr = vim.env.HERDR_SOCKET_PATH ~= nil and vim.env.HERDR_SOCKET_PATH ~= ""

return {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function(_, opts)
        if not inside_herdr then
            require("claudecode").setup(opts)
        end
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
    keys = {
        { "<leader>a",  nil,                              desc = "AI/Claude Code" },
        { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
        -- Layout variants (only apply on a fresh open; close first to switch).
        {
            "<leader>ah",
            function()
                require("claudecode.terminal").simple_toggle({ snacks_win_opts = { position = "bottom", height = 0.3 } })
            end,
            desc = "Toggle Claude (horizontal)",
        },
        {
            "<leader>aF",
            function()
                require("claudecode.terminal").simple_toggle({ snacks_win_opts = { position = "float", width = 0.95, height = 0.95 } })
            end,
            desc = "Toggle Claude (float)",
        },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",               desc = "Send to Claude" },
        {
            "<leader>as",
            "<cmd>ClaudeCodeTreeAdd<cr>",
            desc = "Add file",
            ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
        },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
}

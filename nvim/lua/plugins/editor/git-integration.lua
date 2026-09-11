-- Inline blame and a diagnostic both sit at the end of the line, so the
-- diagnostic wins.
local function inline_blame(username, info)
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    if #vim.diagnostic.get(0, { lnum = lnum }) > 0 then
        return {}
    end
    if info.author == "Not Committed Yet" then
        return { { " Not committed yet ", "GitSignsCurrentLineBlame" } }
    end
    local author = info.author == username and "You" or info.author
    local when = os.date("%Y-%m-%d", info.author_time)
    return { { (" %s, %s - %s "):format(author, when, info.summary), "GitSignsCurrentLineBlame" } }
end

return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "✚" },
                    change = { text = "┃" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                    untracked = { text = "┆" },
                },
                current_line_blame = true,
                current_line_blame_formatter = inline_blame,
                current_line_blame_formatter_nc = inline_blame,
                blame_formatter = "<author> <author_time:%Y-%m-%d>",
                on_attach = function(bufnr)
                    local gitsigns = require("gitsigns")

                    local map = require("lib.keymap").buffer(bufnr)

                    map("n", "]c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "]c", bang = true })
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            gitsigns.nav_hunk("next")
                        end
                    end, "Jump to next git [c]hange")

                    map("n", "[c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "[c", bang = true })
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            gitsigns.nav_hunk("prev")
                        end
                    end, "Jump to previous git [c]hange")

                    map(
                        "v",
                        "<leader>gs",
                        function() gitsigns.stage_hunk({ vim.fn.line("'<"), vim.fn.line("'>") }) end,
                        "git [s]tage hunk"
                    )
                    map(
                        "v",
                        "<leader>gr",
                        function() gitsigns.reset_hunk({ vim.fn.line("'<"), vim.fn.line("'>") }) end,
                        "git [r]eset hunk"
                    )
                    map("n", "<leader>gs", gitsigns.stage_hunk, "Stage/unstage hunk")
                    map("n", "<leader>gS", gitsigns.stage_buffer, "Stage buffer")
                    map("n", "<leader>gu", gitsigns.reset_buffer_index, "Unstage buffer")
                    map("n", "<leader>gr", gitsigns.reset_hunk, "Reset hunk")
                    map("n", "<leader>gR", gitsigns.reset_buffer, "Reset buffer")
                    map("n", "<leader>gp", gitsigns.preview_hunk, "Preview hunk")
                    map("n", "<leader>gb", require("ui.blame").toggle_column, "Toggle blame column")
                end,
            })
        end,
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
        keys = {
            { "<leader>gd", function() require("ui.diffview").uncommitted() end, desc = "Diff uncommitted changes" },
            {
                "<leader>gD",
                function() require("ui.diffview").branch() end,
                desc = "Diff branch against its base",
            },
            { "<leader>gh", function() require("ui.diffview").file_log() end, desc = "File history" },
            { "<leader>gH", function() require("ui.diffview").branch_log() end, desc = "Branch commits one by one" },
            { "<leader>gc", function() require("ui.diffview").pick_commits() end, desc = "Diff from a picked commit" },
            {
                "<leader>gC",
                function() require("ui.diffview").pick_branch() end,
                desc = "Diff against a picked branch",
            },
        },
        opts = function()
            local actions = require("diffview.actions")
            local close = { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close the diffview" } }
            -- The panel keys shadow the <leader>b and <leader>e prefixes.
            local panel_keys = {
                { "n", "<leader>b", false },
                { "n", "<leader>e", false },
                { "n", "j", actions.select_next_entry, { desc = "Open the next file" } },
                { "n", "<down>", actions.select_next_entry, { desc = "Open the next file" } },
                { "n", "k", actions.select_prev_entry, { desc = "Open the previous file" } },
                { "n", "<up>", actions.select_prev_entry, { desc = "Open the previous file" } },
                {
                    "n",
                    "<cr>",
                    function() require("ui.diffview").focus_first_change() end,
                    { desc = "Open the file at its first change" },
                },
                {
                    "n",
                    "<LeftMouse>",
                    function() require("ui.diffview").click_entry() end,
                    { desc = "Open the clicked file" },
                },
            }
            local view_keys = {
                panel_keys[1],
                panel_keys[2],
                { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage the file" } },
                {
                    { "n", "x" },
                    "dp",
                    require("ui.diffview.stage").hunk_to_index("diffput"),
                    { desc = "Put the hunk into the other side, staging it" },
                },
                {
                    { "n", "x" },
                    "do",
                    require("ui.diffview.stage").hunk_to_index("diffget"),
                    { desc = "Take the hunk from the other side, unstaging it" },
                },
            }
            return {
                hooks = require("ui.diffview").hooks,
                keymaps = {
                    view = { close, unpack(view_keys) },
                    file_panel = { close, unpack(panel_keys) },
                    file_history_panel = { close, unpack(panel_keys) },
                },
            }
        end,
    },
}

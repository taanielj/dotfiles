return {
    {
        "lewis6991/gitsigns.nvim",

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
                blame_formatter = "<author> <author_time:%Y-%m-%d>",
                on_attach = function(bufnr)
                    local gitsigns = require("gitsigns")

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buf = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map("n", "]c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "]c", bang = true })
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            gitsigns.nav_hunk("next")
                        end
                    end, { desc = "Jump to next git [c]hange" })

                    map("n", "[c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "[c", bang = true })
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            gitsigns.nav_hunk("prev")
                        end
                    end, { desc = "Jump to previous git [c]hange" })

                    -- Actions
                    map("v", "<leader>gs", function()
                        gitsigns.stage_hunk({ vim.fn.line("'<"), vim.fn.line("'>") })
                    end, { desc = "git [s]tage hunk" })
                    map("v", "<leader>gr", function()
                        gitsigns.reset_hunk({ vim.fn.line("'<"), vim.fn.line("'>") })
                    end, { desc = "git [r]eset hunk" })
                    map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage/unstage hunk" })
                    map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage buffer" })
                    map("n", "<leader>gU", gitsigns.reset_buffer_index, { desc = "Unstage buffer" })
                    map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset hunk" })
                    map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset buffer" })
                    map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview hunk" })
                    map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff against base" })
                    map("n", "<leader>gl", function()
                        ---@diagnostic disable-next-line: param-type-mismatch
                        gitsigns.diffthis("@")
                    end, { desc = "Diff last commit" })

                    map("n", "<leader>gm", function()
                        ---@diagnostic disable-next-line: param-type-mismatch
                        gitsigns.diffthis(require("git").default_branch() or "main")
                    end, { desc = "Diff against main/master branch" })

                    -- Toggles
                    local function toggle_blame_column()
                        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "gitsigns-blame" then
                                vim.api.nvim_win_close(win, true)
                                return
                            end
                        end
                        local win = vim.api.nvim_get_current_win()
                        gitsigns.blame(nil, function()
                            if vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_set_current_win(win)
                            end
                        end)
                    end
                    map("n", "<leader>gb", gitsigns.toggle_current_line_blame, { desc = "Toggle inline blame" })
                    map("n", "<leader>gB", toggle_blame_column, { desc = "Toggle blame column" })
                    map("n", "<leader>gD", gitsigns.toggle_linehl, { desc = "Diff line highlighting" })

                    -- Open current line in browser (GitHub/GitLab/Bitbucket)
                    local git = require("git")
                    local function is_git_repo()
                        local remote_url = git.run({ "remote", "get-url", "origin" })
                        if remote_url == "" then
                            vim.notify("No git remote found", vim.log.levels.ERROR)
                            return false
                        end
                        return true
                    end

                    local function get_remote_url(line_start, line_end)
                        local branch = git.head()
                        local repo_root = git.run({ "rev-parse", "--show-toplevel" })
                        local file_path = vim.fn.expand("%:p")
                        local relative_path = file_path:sub(#repo_root + 2)
                        local remote_url = git.run({ "remote", "get-url", "origin" })
                        remote_url = remote_url:gsub("git@([^:]+):", "https://%1/"):gsub("%.git$", "")
                        local url

                        local include_lines = not (line_start == 1 and line_end == 1)

                        if remote_url:match("gitlab") then
                            url = string.format("%s/-/blob/%s/%s", remote_url, branch, relative_path)
                            if include_lines then
                                url = url .. "#L" .. line_start
                                if line_end ~= line_start then
                                    url = url .. "-" .. line_end
                                end
                            end
                        elseif remote_url:match("bitbucket") then
                            url = string.format("%s/src/%s/%s", remote_url, branch, relative_path)
                            if include_lines then
                                url = url .. "#lines-" .. line_start
                                if line_end ~= line_start then
                                    url = url .. ":" .. line_end
                                end
                            end
                        else
                            url = string.format("%s/blob/%s/%s", remote_url, branch, relative_path)
                            if include_lines then
                                url = url .. "#L" .. line_start
                                if line_end ~= line_start then
                                    url = url .. "-L" .. line_end
                                end
                            end
                        end
                        return url
                    end
                    local function get_line_range()
                        local line_start, line_end
                        local mode = vim.fn.mode()
                        if mode == "v" or mode == "V" or mode == "\22" then
                            line_start = vim.fn.line("v")
                            line_end = vim.fn.line(".")
                            if line_start > line_end then
                                line_start, line_end = line_end, line_start
                            end
                        else
                            line_start = vim.fn.line(".")
                            line_end = line_start
                        end
                        return line_start, line_end
                    end

                    map({ "n", "v" }, "<leader>go", function()
                        if not is_git_repo() then
                            return
                        end
                        local line_start, line_end = get_line_range()
                        local url = get_remote_url(line_start, line_end)
                        vim.ui.open(url)
                    end, { desc = "Open line in browser" })
                    map({ "n", "v" }, "<leader>yg", function()
                        if not is_git_repo() then
                            return
                        end
                        local line_start, line_end = get_line_range()
                        local url = get_remote_url(line_start, line_end)
                        vim.fn.setreg("+", url)
                        vim.notify("Copied URL to clipboard: " .. url, vim.log.levels.INFO)
                    end, { desc = "Copy line URL to clipboard" })
                end,
            })
        end,
    },
    {
        "tpope/vim-fugitive",
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
        keys = {
            { "<leader>gv", function() require("ui.diffview").uncommitted() end,  desc = "Diff uncommitted changes" },
            { "<leader>gV", function() require("ui.diffview").branch() end,       desc = "Diff branch against its base" },
            { "<leader>gh", function() require("ui.diffview").file_log() end,     desc = "File history" },
            { "<leader>gH", function() require("ui.diffview").branch_log() end,   desc = "Branch commits one by one" },
            { "<leader>gc", function() require("ui.diffview").pick_commits() end, desc = "Diff from a picked commit" },
            { "<leader>gC", function() require("ui.diffview").pick_branch() end,  desc = "Diff against a picked branch" },
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
                { "n", "<cr>", function() require("ui.diffview").focus_first_change() end, { desc = "Open the file at its first change" } },
            }
            local view_keys = {
                panel_keys[1],
                panel_keys[2],
                { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage the file" } },
                { { "n", "x" }, "dp", require("ui.diffview").hunk_to_index("diffput"), { desc = "Put the hunk into the other side, staging it" } },
                { { "n", "x" }, "do", require("ui.diffview").hunk_to_index("diffget"), { desc = "Take the hunk from the other side, unstaging it" } },
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
    {
        "neogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            vim.keymap.set("n", "<leader>gn", "<Cmd>Neogit kind=floating<CR>", { desc = "Open Neogit" })
        end,
    },
}

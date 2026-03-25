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
                on_attach = function(bufnr)
                    local gitsigns = require("gitsigns")

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Helper to detect default branch
                    local function get_default_branch()
                        local handle =
                            io.popen("git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'")
                        local result = handle and handle:read("*a") or ""
                        if handle then
                            handle:close()
                        end
                        result = vim.trim(result)
                        if result == "" then
                            -- fallback to main if unknown
                            return "main"
                        end
                        return result
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
                    map("n", "<leader>gb", gitsigns.blame_line, { desc = "Toggle blame" })
                    map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff against base" })
                    map("n", "<leader>gl", function()
                        ---@diagnostic disable-next-line: param-type-mismatch
                        gitsigns.diffthis("@")
                    end, { desc = "Diff last commit" })

                    -- New: Diff against default branch (main/master)
                    map("n", "<leader>gm", function()
                        local base = get_default_branch()
                        ---@diagnostic disable-next-line: param-type-mismatch
                        gitsigns.diffthis(base)
                    end, { desc = "Diff against main/master branch" })

                    -- Toggles
                    map("n", "<leader>gB", gitsigns.toggle_current_line_blame, { desc = "Toggle git blame line" })
                    map("n", "<leader>gD", gitsigns.toggle_linehl, { desc = "Diff line highlighting" })

                    -- Open current line in browser (GitHub/GitLab/Bitbucket)
                    local function run_cmd(cmd)
                        local handle = io.popen(cmd)
                        local result = handle and handle:read("*a") or ""
                        if handle then
                            handle:close()
                        end
                        return vim.trim(result)
                    end
                    local function is_git_repo()
                        local remote_url = run_cmd("git remote get-url origin 2>/dev/null")
                        if remote_url == "" then
                            vim.notify("No git remote found", vim.log.levels.ERROR)
                            return false
                        end
                        return true
                    end

                    local function get_remote_url(line_start, line_end)
                        -- Detect platform and build URL
                        local branch = run_cmd("git rev-parse --abbrev-ref HEAD 2>/dev/null")
                        local repo_root = run_cmd("git rev-parse --show-toplevel 2>/dev/null")
                        local file_path = vim.fn.expand("%:p")
                        local relative_path = file_path:sub(#repo_root + 2)
                        local remote_url = run_cmd("git remote get-url origin 2>/dev/null")
                        remote_url = remote_url:gsub("git@([^:]+):", "https://%1/"):gsub("%.git$", "")
                        local url
                        if remote_url:match("gitlab") then
                            url = string.format("%s/-/blob/%s/%s#L%d", remote_url, branch, relative_path, line_start)
                            if line_end ~= line_start then
                                url = url .. "-" .. line_end
                            end
                        elseif remote_url:match("bitbucket") then
                            url = string.format("%s/src/%s/%s#lines-%d", remote_url, branch, relative_path, line_start)
                            if line_end ~= line_start then
                                url = url .. ":" .. line_end
                            end
                        else
                            -- Default to GitHub format
                            url = string.format("%s/blob/%s/%s#L%d", remote_url, branch, relative_path, line_start)
                            if line_end ~= line_start then
                                url = url .. "-L" .. line_end
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

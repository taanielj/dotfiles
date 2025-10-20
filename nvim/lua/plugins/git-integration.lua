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

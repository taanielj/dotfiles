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

                    -- Navigation
                    map("n", "]c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "]c", bang = true })
                        else
                            gitsigns.nav_hunk("next")
                        end
                    end, { desc = "Jump to next git [c]hange" })

                    map("n", "[c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "[c", bang = true })
                        else
                            gitsigns.nav_hunk("prev")
                        end
                    end, { desc = "Jump to previous git [c]hange" })

                    -- Actions
                    -- visual mode
                    map("v", "<leader>gs", function()
                        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                    end, { desc = "git [s]tage hunk" })
                    map("v", "<leader>gr", function()
                        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                    end, { desc = "git [r]eset hunk" })
                    -- normal mode
                    map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage hunk" })
                    map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage buffer" })
                    map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset hunk" })
                    map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset buffer" })
                    map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview hunk" })
                    map("n", "<leader>gb", gitsigns.blame_line, { desc = "Toggle blame" })
                    map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff against base" })
                    map("n", "<leader>gl", function()
                        gitsigns.diffthis("@")
                    end, { desc = "Diff last commit" })
                    -- Toggles
                    map(
                        "n",
                        "<leader>gb",
                        gitsigns.toggle_current_line_blame,
                        { desc = "[T]oggle git show [b]lame line" }
                    )
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
        config = true,

        vim.keymap.set("n", "<leader>gn", "<Cmd>Neogit kind=floating<CR>", { desc = "Open Neogit" }),
    },
}

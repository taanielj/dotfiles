local save_dir = vim.fn.expand("~/git/codesnap")

-- CodeSnap reads '< and '>, which are set only when visual mode ends
return {
    "mistricky/codesnap.nvim",
    build = "make build_generator",
    keys = {
        { "<leader>cc", ":CodeSnap<cr>", mode = "x", desc = "Copy code snapshot" },
        {
            "<leader>cs",
            function()
                vim.cmd("normal! \27")
                vim.fn.mkdir(save_dir, "p")
                vim.cmd.CodeSnapSave(vim.fs.joinpath(save_dir, os.date("%Y%m%d-%H%M%S") .. ".png"))
            end,
            mode = "x",
            desc = "Save code snapshot to " .. save_dir,
        },
    },
    opts = {},
}

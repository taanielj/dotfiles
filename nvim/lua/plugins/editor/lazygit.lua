return {
    "kdheepak/lazygit.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
    config = function()
        vim.g.lazygit_on_exit_callback = require("ui.tree").refresh
    end,
}

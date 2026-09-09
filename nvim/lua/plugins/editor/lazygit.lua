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
        vim.g.lazygit_on_exit_callback = function()
            local state = require("neo-tree.sources.manager").get_state("filesystem")
            require("neo-tree.sources.filesystem.commands").refresh(state)
        end
    end,
}

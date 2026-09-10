-- Inside herdr, ui/lazygit.lua opens herdr's lazygit popup instead.
return {
    "kdheepak/lazygit.nvim",
    cond = not require("lib.herdr").inside(),
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    config = function() vim.g.lazygit_on_exit_callback = require("ui.tree").refresh end,
}

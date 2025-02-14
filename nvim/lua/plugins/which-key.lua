return {
    "folke/which-key.nvim",
    dependencies = {
        "echasnovski/mini.icons",
    },
    event = "VeryLazy",
    config = function()
        vim.o.timeoutlen = 200
        local wk = require("which-key")

        wk.add({
            { "<leader>b",   group = "Buffer" },
            { "<leader>bs",  group = "Sort" },
            { "<leader>bc",  group = "Close" },
            { "<leader>l",   group = "LSP" },
            { "<leader>f",   group = "Find" },
            { "<leader>h",   group = "Find Hidden" },
            { "<leader>g",   group = "Git" },
            -- close and force quit
            { "<leader>q",   group = "Close" },
            { "<leader>qf",  group = "Force quit" },
            { "<leader>qfy", "Lose all unsaved changes?" },
        })

        require("which-key").setup()
    end,
}

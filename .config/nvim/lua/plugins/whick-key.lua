return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        vim.o.timeoutlen = 0
        local wk = require("which-key")
        wk.register({
            f = {
            name = "+Find",
                h = {
                    name = "+Hidden",
                }
            },
        }, { prefix = "<leader>" })

        require("which-key").setup()
    end,
}

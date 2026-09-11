return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = "markdown",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ---@module 'render-markdown'
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
    },
    {
        "toppair/peek.nvim",
        ft = "markdown",
        build = "deno task --quiet build",
        opts = {},
        keys = {
            {
                "<leader>p",
                function()
                    local peek = require("peek")
                    if peek.is_open() then
                        peek.close()
                    else
                        peek.open()
                    end
                end,
                ft = "markdown",
                desc = "Preview markdown",
            },
        },
        config = function(_, opts)
            require("peek").setup(opts)
            vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
            vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
        end,
    },
}

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
        "brianhuster/live-preview.nvim",
        cmd = "LivePreview",
        keys = {
            {
                "<leader>p",
                function()
                    if require("livepreview").is_running() then
                        vim.cmd("LivePreview close")
                    else
                        vim.cmd("LivePreview start")
                    end
                end,
                ft = "markdown",
                desc = "Preview markdown",
            },
        },
    },
}

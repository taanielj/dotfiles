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
        -- local fork: editing in the preview, on branch edit-in-preview
        dir = "~/git/live-preview.nvim",
        cmd = "LivePreview",
        config = function()
            -- the shared default port sends a second nvim's browser to the first nvim's server
            local probe = vim.uv.new_tcp()
            probe:bind("127.0.0.1", 0)
            local port = probe:getsockname().port
            probe:close()
            require("livepreview.config").set({ port = port })
        end,
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

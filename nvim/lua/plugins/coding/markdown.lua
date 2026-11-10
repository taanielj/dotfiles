local live_preview_fork = vim.fs.normalize("~/git/live-preview.nvim")

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
        dir = live_preview_fork,
        cond = vim.fn.isdirectory(live_preview_fork) == 1,
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
            -- always start: a closed browser tab leaves the server up, and a toggle would stop it instead
            { "<leader>p", "<cmd>LivePreview start<cr>", ft = "markdown", desc = "Preview markdown" },
        },
    },
}

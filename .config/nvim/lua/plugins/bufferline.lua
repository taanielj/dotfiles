return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("bufferline").setup({
            options = {
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        text_align = "center",
                    },
               },
            },
        })
        -- closing
        vim.keymap.set("n", "<leader>bd", ":BufferLineCloseLeft<CR>", { desc = "Close Left }" })
        vim.keymap.set("n", "<leader>be", ":BufferLineCloseRight<CR>", { desc = "Close Right" })
        vim.keymap.set("n", "<leader>ba", ":BufferLineCloseOthers<CR>", { desc = "Close All Buffers" })
        vim.keymap.set("n", "<leader>bc)", ":bd<CR>", { desc = "Close Current Buffer" })
        -- sorting
        vim.keymap.set("n", "<leader>bsd", ":BufferLineSortByDirectory<CR>", { desc = "Sort by Directory" })
        vim.keymap.set("n", "<leader>bst", ":BufferLineSortByTabs<CR>", { desc = "Sort by Tabs" })
        vim.keymap.set("n", "<leader>bse", ":BufferLineSortByExtension<CR>", { desc = "Sort by Extension" })
        -- move buffer
        vim.keymap.set("n", "<leader>bmh", ":BufferLineMoveLeft<CR>", { desc = "Move Left" })
        vim.keymap.set("n", "<leader>bml", ":BufferLineMoveRight<CR>", { desc = "Move Right" })
        -- cycle buffer
        vim.keymap.set("n", "<leader>bn", ":BufferLineCycleNext<CR>", { desc = "Next Buffer" })
        vim.keymap.set("n", "<leader>bp", ":BufferLineCyclePrev<CR>", { desc = "Previous Buffer" })
    end,
}

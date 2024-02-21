return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("bufferline").setup({
            options ={
                offsets = {
                    { filetype = "NvimTree", padding = 1 }
                }
            }
        })
        vim.g.barbar_auto_setup = false
    end
}

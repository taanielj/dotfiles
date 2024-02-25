return {
    "mbbill/undotree",
    config = function()
        vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { noremap = true, silent = true, desc = "Undo tree" })
    end
}

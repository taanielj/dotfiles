vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- Unmap tmux-navigator keys inside terminal buffers
    vim.keymap.del("t", "<C-h>")
    vim.keymap.del("t", "<C-j>")
    vim.keymap.del("t", "<C-k>")
    vim.keymap.del("t", "<C-l>")
  end,
})

-- Set mappings only in normal mode
vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", { silent = true })
vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>", { silent = true })
vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>", { silent = true })
vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>", { silent = true })

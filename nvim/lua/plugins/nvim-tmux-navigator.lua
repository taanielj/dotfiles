return {
  "christoomey/vim-tmux-navigator",
  config = function()
    -- Normal mode keymaps
    vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", { silent = true })
    vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>", { silent = true })
    vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>", { silent = true })
    vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>", { silent = true })

    -- Remove terminal mode mappings in terminal buffers to prevent conflict with Lazygit
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function()
        for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
          pcall(vim.keymap.del, "t", key)
        end
      end,
    })
  end,
}


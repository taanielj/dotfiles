vim.api.nvim_create_autocmd({"InsertEnter"}, {
    group = vim.api.nvim_create_augroup("NumberToggle", { clear = true }),
    callback = function()
        vim.opt.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
    group = "NumberToggle",
    callback = function()
        vim.opt.relativenumber = true
    end,
})




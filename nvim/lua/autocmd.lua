vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = vim.api.nvim_create_augroup("NumberToggle", { clear = true }),
    callback = function()
        vim.opt.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = "NumberToggle",
    callback = function()
        vim.opt.relativenumber = true
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NeotreeNoFoldColumn", { clear = true }),
    pattern = { "neo-tree", "neotree" },
    callback = function()
        require("ufo").detach()
        vim.opt_local.foldenable = false
    end,
})

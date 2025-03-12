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

vim.api.nvim_create_autocmd({ "FileType" }, {
    group = vim.api.nvim_create_augroup("NeotreeNoFoldColumn", { clear = true }),
    pattern = { "neo-tree", "neotree" },
    callback = function()
        vim.cmd([[
            aunmenu PopUp
            anoremenu PopUp.Open   <cmd>lua require('neotree').open()<CR>
        ]])
        require("ufo").detach()
        vim.opt_local.foldenable = false
    end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight on yank",
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
    end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    group = vim.api.nvim_create_augroup("NeotreeNoFoldColumn", { clear = true }),
    pattern = { "markdown" },
    callback = function()
        -- set tabstop=2
        vim.cmd("setlocal tabstop=2")
        vim.cmd("setlocal shiftwidth=2")
    end,
})

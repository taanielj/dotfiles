local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Relative number toggle on insert
vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup("number_toggle"),
    callback = function()
        vim.opt.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup("number_toggle"),
    callback = function()
        vim.opt.relativenumber = true
    end,
})

-- Neotree special behavior
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("neotree"),
    pattern = { "neo-tree", "neotree" },
    callback = function()
        require("ufo").detach()
        vim.opt_local.foldenable = false
    end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    desc = "Briefly highlight yanked text",
    callback = function()
        vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
    end,
})

-- Markdown tab width
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("markdown"),
    pattern = "markdown",
    callback = function()
        vim.cmd("setlocal tabstop=2")
        vim.cmd("setlocal shiftwidth=2")
    end,
})

-- YAML tab width
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("yaml"),
    pattern = "yaml",
    callback = function()
        vim.cmd("setlocal tabstop=2")
        vim.cmd("setlocal shiftwidth=2")
    end,
})

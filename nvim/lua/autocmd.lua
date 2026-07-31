local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Remove indentkeys that trigger while typing (keeps o,O for new line indent)
vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup("indentkeys"),
    pattern = "*",
    callback = function()
        vim.cmd("setlocal indentkeys-=<:>")
        vim.cmd("setlocal indentkeys-=0}")
        vim.cmd("setlocal indentkeys-=0]")
        vim.cmd("setlocal indentkeys-=0-")
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup("number_toggle"),
    callback = function()
        if vim.bo.filetype ~= "neo-tree" and not require("zen").is_active() then
            vim.wo.relativenumber = true
        end
    end,
})

-- disable conceallevel for json
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("json_conceal"),
    pattern = "json",
    callback = function()
        vim.opt_local.conceallevel = 0
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
        vim.hl.on_yank({ higroup = "Visual", timeout = 200 })
    end,
})

local indent_filetypes = { "yaml", "html", "css", "json", "markdown" }
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("indent_filetypes"),
    pattern = indent_filetypes,
    callback = function()
        vim.cmd("setlocal shiftwidth=2")
        vim.cmd("setlocal tabstop=2")
    end,
})

-- Use real tabs for Makefiles
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("makefile_tabs"),
    pattern = "make",
    callback = function()
        vim.cmd("setlocal noexpandtab")
    end,
})

-- Claude Code (snacks terminal): navigate out with <C-hjkl> from terminal mode.
-- Scoped to snacks_terminal buffers so shells in other :terminals keep <C-l> etc.
-- herdr-splits owns these keys inside herdr; smart-splits owns them outside.
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("claude_term_nav"),
    pattern = "snacks_terminal",
    callback = function(ev)
        local nav = vim.env.HERDR_ENV == "1" and "herdr-splits" or "smart-splits"
        local dirs = { h = "move_cursor_left", j = "move_cursor_down", k = "move_cursor_up", l = "move_cursor_right" }
        for key, fn in pairs(dirs) do
            vim.keymap.set("t", "<C-" .. key .. ">", function()
                require(nav)[fn]()
            end, { buffer = ev.buf, silent = true, desc = "Window nav " .. key })
        end
    end,
})

-- Jump to the first non-blank character if opening at column 1 (useful with vim-fetch)
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = augroup("fetch_first_non_blank"),
    callback = function()
        vim.schedule(function()
            if vim.api.nvim_get_mode().mode == "n" and vim.fn.col('.') == 1 then
                vim.cmd("normal! ^")
            end
        end)
    end,
})

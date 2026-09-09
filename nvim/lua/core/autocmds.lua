local function augroup(name) return vim.api.nvim_create_augroup("user_" .. name, { clear = true }) end

-- o and O still indent new lines; the rest fire mid-typing
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

-- Relative numbers are for jumps; in insert mode the absolute line is the useful one
local number_toggle = augroup("number_toggle")
vim.api.nvim_create_autocmd("InsertEnter", {
    group = number_toggle,
    callback = function() vim.wo.relativenumber = false end,
})
-- 'scroll' goes back to half the window height whenever a window is resized,
-- which the UI does once more after VimEnter
vim.api.nvim_create_autocmd({ "UIEnter", "WinNew", "WinResized" }, {
    group = augroup("scroll"),
    callback = function()
        for _, win in ipairs(vim.v.event.windows or vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
                vim.wo[win].scroll = math.max(1, math.min(5, vim.api.nvim_win_get_height(win)))
            end
        end
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = number_toggle,
    callback = function()
        if vim.bo.filetype ~= "neo-tree" and not require("ui.zen").is_active() then
            vim.wo.relativenumber = true
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("json_conceal"),
    pattern = "json",
    callback = function() vim.opt_local.conceallevel = 0 end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("neotree"),
    pattern = { "neo-tree", "neotree" },
    callback = function()
        require("ufo").detach()
        vim.opt_local.foldenable = false
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    desc = "Briefly highlight yanked text",
    callback = function() vim.hl.on_yank({ higroup = "Visual", timeout = 200 }) end,
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

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("makefile_tabs"),
    pattern = "make",
    callback = function() vim.cmd("setlocal noexpandtab") end,
})

-- Scoped to snacks_terminal buffers so shells in other :terminals keep <C-l> etc.
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("claude_term_nav"),
    pattern = "snacks_terminal",
    callback = function(ev)
        local nav = require("lib.herdr").inside() and "herdr-splits" or "smart-splits"
        local dirs = { h = "move_cursor_left", j = "move_cursor_down", k = "move_cursor_up", l = "move_cursor_right" }
        for key, fn in pairs(dirs) do
            vim.keymap.set(
                "t",
                "<C-" .. key .. ">",
                function() require(nav)[fn]() end,
                { buffer = ev.buf, silent = true, desc = "Window nav " .. key }
            )
        end
    end,
})

-- vim-fetch lands a file:line spec at column 1, so move to the text
vim.api.nvim_create_autocmd("User", {
    group = augroup("fetch_first_non_blank"),
    pattern = "BufFetchPosPost",
    callback = function()
        if vim.fn.col(".") == 1 then
            vim.cmd("normal! ^")
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("markdown_links"),
    pattern = "markdown",
    callback = function(ev)
        vim.keymap.set("n", "gx", function() require("ui.markdown_links").follow() end, {
            buffer = ev.buf,
            desc = "Follow link under cursor",
        })
    end,
})

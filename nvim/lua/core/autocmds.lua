local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

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
    callback = function()
        vim.wo.relativenumber = false
    end,
})
-- 'scroll' goes back to half the window height whenever a window is resized
vim.api.nvim_create_autocmd({ "VimEnter", "WinNew", "WinResized" }, {
    group = augroup("scroll"),
    callback = function()
        for _, win in ipairs(vim.v.event.windows or { vim.api.nvim_get_current_win() }) do
            if vim.api.nvim_win_is_valid(win) then
                vim.wo[win].scroll = 5
            end
        end
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = number_toggle,
    callback = function()
        if vim.bo.filetype ~= "neo-tree" and not require("zen").is_active() then
            vim.wo.relativenumber = true
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("json_conceal"),
    pattern = "json",
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
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

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("makefile_tabs"),
    pattern = "make",
    callback = function()
        vim.cmd("setlocal noexpandtab")
    end,
})

-- Scoped to snacks_terminal buffers so shells in other :terminals keep <C-l> etc.
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("claude_term_nav"),
    pattern = "snacks_terminal",
    callback = function(ev)
        local nav = require("lib.herdr").inside() and "herdr-splits" or "smart-splits"
        local dirs = { h = "move_cursor_left", j = "move_cursor_down", k = "move_cursor_up", l = "move_cursor_right" }
        for key, fn in pairs(dirs) do
            vim.keymap.set("t", "<C-" .. key .. ">", function()
                require(nav)[fn]()
            end, { buffer = ev.buf, silent = true, desc = "Window nav " .. key })
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

-- Marksman resolves the target where it is attached, so anchors and
-- [[wiki links]] land on the right heading.
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("markdown_links"),
    pattern = "markdown",
    callback = function(ev)
        local function target_under_cursor()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2] + 1
            local from = 1
            while true do
                local s, e, target = line:find("%[[^%]]*%]%(([^)]+)%)", from)
                if not s then
                    return nil
                end
                if col >= s and col <= e then
                    return target
                end
                from = e + 1
            end
        end

        vim.keymap.set("n", "gx", function()
            local target = target_under_cursor() or vim.fn.expand("<cfile>")
            if target == "" then
                return
            end
            if target:match("^%a[%w+.-]*:") then -- http:, https:, mailto:
                return vim.ui.open(target)
            end

            local path = vim.uri_decode((target:gsub("#.*$", "")))
            if path ~= "" then
                path = vim.fs.normalize(
                    path:sub(1, 1) == "/" and path or vim.fs.joinpath(vim.fn.expand("%:p:h"), path)
                )
            end

            if path == "" or require("lib.markdown").is_file(path) then
                if next(vim.lsp.get_clients({ bufnr = 0, name = "marksman" })) then
                    return vim.lsp.buf.definition()
                end
                if vim.uv.fs_stat(path) then
                    return vim.cmd.edit(vim.fn.fnameescape(path))
                end
            elseif vim.uv.fs_stat(path) then
                return vim.ui.open(path)
            end
            vim.notify("No such file: " .. path, vim.log.levels.WARN)
        end, { buffer = ev.buf, desc = "Follow link under cursor" })
    end,
})

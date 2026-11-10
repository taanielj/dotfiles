local function augroup(name) return vim.api.nvim_create_augroup("user_" .. name, { clear = true }) end

-- These keys reindent the line while typing. o and O still indent new lines.
vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup("indentkeys"),
    pattern = "*",
    callback = function() vim.opt_local.indentkeys:remove({ "<:>", "0}", "0]", "0-", "0)", ")" }) end,
})

-- Relative numbers help with jumps. In insert mode the absolute line number helps more.
local number_toggle = augroup("number_toggle")
vim.api.nvim_create_autocmd("InsertEnter", {
    group = number_toggle,
    callback = function() vim.wo.relativenumber = false end,
})
-- Neovim resets 'scroll' to half the window height whenever a window is resized.
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

-- `nvim -` has no file name to detect the filetype by.
-- Neovim detects shebangs, <?xml, HTML and diffs in stdin.
vim.api.nvim_create_autocmd("StdinReadPost", {
    group = augroup("stdin_filetype"),
    callback = function()
        local first = vim.fn.getline(vim.fn.nextnonblank(1))
        local ft = first:match("^%s*[{[]") and "json"
            or first:match("^%s*<[%a_!]") and "xml"
            or (first:match("^%-%-%-%s*$") or first:match("^%a[%w_.-]*:%s") or first:match("^%a[%w_.-]*:$"))
                and "yaml"
        if ft then
            -- Neovim's own detection overrides a FALLBACK filetype
            vim.cmd.setfiletype({ args = { "FALLBACK", ft } })
        end
    end,
})

-- herdr's edit_scrollback opens the dump at its first line, and the latest
-- output is at the end
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("herdr_scrollback"),
    pattern = "herdr-scrollback-*.txt",
    callback = function() vim.cmd("normal! G") end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = augroup("claude_draft"),
    pattern = "*/.scratch/prompt.md",
    callback = function(args) require("ui.claude_editor").attach(args.buf) end,
})

-- An agent writes files while this window keeps focus, and nvim doesn't check
-- for that by default. checktime costs one stat per buffer.
-- FocusGained below covers files that change while focus is elsewhere.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = augroup("agent_writes"),
    command = "checktime",
})

-- Refresh the tree after focus returns from herdr's lazygit popup or a sibling
-- agent pane.
vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup("neotree_refresh"),
    callback = function()
        local tree = require("ui.tree")
        if tree.window() then
            tree.refresh()
        end
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
    callback = function() vim.hl.on_yank({ higroup = "Visual", timeout = 200 }) end,
})

local indent_filetypes = { "yaml", "html", "css", "json", "markdown" }
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("indent_filetypes"),
    pattern = indent_filetypes,
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("makefile_tabs"),
    pattern = "make",
    callback = function() vim.opt_local.expandtab = false end,
})

-- Scoped to snacks_terminal buffers so shells in other :terminals keep <C-l> etc.
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("claude_term_nav"),
    pattern = "snacks_terminal",
    callback = function(ev)
        local map = require("lib.keymap").buffer_mapper(ev.buf)
        local dirs = { h = "left", j = "down", k = "up", l = "right" }
        for key, dir in pairs(dirs) do
            map("t", "<C-" .. key .. ">", function() require("lib.splits").move(dir) end, "Window " .. dir)
        end
    end,
})

-- vim-fetch puts the cursor at column 1 of a file:line spec
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
        local map = require("lib.keymap").buffer_mapper(ev.buf)
        local loud = { silent = false }
        map("n", "gx", function() require("ui.markdown_links").follow() end, "Follow link under cursor", loud)
        map(
            "n",
            "gX",
            function() require("ui.markdown_links").to_reference() end,
            "Turn link under cursor into a reference",
            loud
        )
        map(
            "x",
            "gX",
            function() require("ui.markdown_links").references_in_selection() end,
            "Turn links into references",
            loud
        )
    end,
})

vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("user_dashboard_fallback", { clear = true }),
    callback = function(ev)
        local closed = tonumber(ev.match)
        vim.schedule(function()
            local dashboard = require("ui.dashboard")
            if dashboard.only_tree_left(closed) then
                dashboard.open_beside_tree()
            end
        end)
    end,
})

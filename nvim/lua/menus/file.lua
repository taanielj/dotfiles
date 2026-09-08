-- Rows about a file on disk, shared by every menu that shows one.
local icons = require("ui.icons")
local yank = require("yank")

---@param rows table  from ui.menu.rows()
---@param path string
return function(rows, path)
    rows.item(icons.clipboard, "Copy name", function()
        yank.copy(vim.fn.fnamemodify(path, ":t"), "name")
    end)
    rows.item(icons.path, "Copy path", function()
        yank.copy(path, "path")
    end)
    rows.item(icons.relative_path, "Copy relative path", function()
        yank.copy(vim.fn.fnamemodify(path, ":~:."), "path")
    end)
    -- The URL takes two git calls, so it is built on the click, not per menu
    rows.item(icons.browser, "Copy git URL", function()
        local url = require("git").remote_url(path)
        if url then
            yank.copy(url, "git URL")
        else
            vim.notify("No git remote for this file", vim.log.levels.WARN)
        end
    end, vim.fs.root(path, ".git") ~= nil)
end

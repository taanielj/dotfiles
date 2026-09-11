-- Rows about a file on disk, shared by every menu that shows one.
local icons = require("lib.icons")
local yank = require("lib.yank")

---@param rows table  from lib.menu.rows()
---@param path string
return function(rows, path)
    rows.item(icons.clipboard, "Copy name", function() yank.copy(vim.fn.fnamemodify(path, ":t"), "name") end)
    rows.item(icons.path, "Copy path", function() yank.copy(path, "path") end)
    rows.item(
        icons.relative_path,
        "Copy relative path",
        function() yank.copy(vim.fn.fnamemodify(path, ":~:."), "path") end
    )
    -- The URL takes two git calls, so it is built on the click, not per menu
    rows.item(icons.browser, "Copy git URL", function()
        local url = require("lib.git").web_url(path)
        if url then
            yank.copy(url, "git URL")
        end
    end, require("lib.git").root(path) ~= nil)
end

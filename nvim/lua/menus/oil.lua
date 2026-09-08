local icons = require("ui.icons")

return function()
    local oil = require("oil")
    local rows = require("ui.menu").rows()
    local entry, dir = oil.get_cursor_entry(), oil.get_current_dir()
    if not (entry and dir) then
        return rows.entries
    end

    rows.item(icons.open, "Open", function() oil.select() end)
    rows.item(icons.vsplit, "Open in vertical split", function() oil.select({ vertical = true }) end)
    rows.item(icons.hsplit, "Open in horizontal split", function() oil.select({ horizontal = true }) end)
    rows.add({ separator = true })
    require("menus.file")(rows, vim.fs.joinpath(dir, entry.name))

    return rows.entries
end

local manager = require("neo-tree.sources.manager")
local cc = require("neo-tree.sources.common.commands")
local icons = require("ui.icons")

local function get_state()
    local state = manager.get_state_for_window()
    assert(state)
    state.config = state.config or {}
    return state
end

local function call(what)
    return vim.schedule_wrap(function()
        local state = get_state()
        local cb = require("neo-tree.sources." .. state.name .. ".commands")[what] or cc[what]
        cb(state)
    end)
end

-- Copy path to clipboard; `how` is the fnamemodify() modifier.
local function copy_path(how)
    return function()
        local node = get_state().tree:get_node()
        if node.type == "message" then
            return
        end
        vim.fn.setreg('"', vim.fn.fnamemodify(node.path, how))
        vim.fn.setreg("+", vim.fn.fnamemodify(node.path, how))
    end
end

local function item(icon, name, cmd)
    return { name = icon .. "  " .. name, cmd = cmd }
end

return function()
    return {
        item(icons.open, "Open", call("open")),
        item(icons.vsplit, "Open in vertical split", call("open_vsplit")),
        item(icons.hsplit, "Open in horizontal split", call("open_split")),
        { separator = true },
        item(icons.new_file, "New file", call("add")),
        item(icons.new_folder, "New folder", call("add_directory")),
        item(icons.rename, "Rename", call("rename")),
        item(icons.rename, "Rename basename", call("rename_basename")),
        { name = "File details", cmd = call("show_file_details") },
        { separator = true },
        item(icons.copy, "Copy", call("copy_to_clipboard")),
        item(icons.cut, "Cut", call("cut_to_clipboard")),
        item(icons.paste, "Paste", call("paste_from_clipboard")),
        item(icons.path, "Copy absolute path", copy_path(":p")),
        item(icons.relative_path, "Copy relative path", copy_path(":~:.")),
        { separator = true },
        {
            name = "Order by",
            items = {
                { name = "Created date", cmd = call("order_by_created") },
                { name = "Diagnostic severity", cmd = call("order_by_diagnostics") },
                { name = "Git status", cmd = call("order_by_git_status") },
                { name = "Last modified", cmd = call("order_by_modified") },
                { name = "Name", cmd = call("order_by_name") },
                { name = "Size", cmd = call("order_by_size") },
                { name = "Type", cmd = call("order_by_type") },
            },
        },
        {
            name = "Find",
            items = {
                { name = "Fuzzy finder", cmd = call("fuzzy_finder") },
                { name = "Fuzzy finder directory", cmd = call("fuzzy_finder_directory") },
                { name = "Fuzzy sorter", cmd = call("fuzzy_sorter") },
            },
        },
        { name = "Toggle hidden", cmd = call("toggle_hidden") },
        { name = "Refresh", cmd = call("refresh") },
        { separator = true },
        item(icons.delete, "Delete", call("Delete")),
    }
end

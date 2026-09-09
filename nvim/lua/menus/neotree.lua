local icons = require("ui.icons")

-- nil when the window has no tree state, which a click can hit mid-render
local function get_state()
    local state = require("neo-tree.sources.manager").get_state_for_window()
    if state then
        state.config = state.config or {}
    end
    return state
end

local function command(state, what)
    local source = require("neo-tree.sources." .. state.name .. ".commands")
    return source[what] or require("neo-tree.sources.common.commands")[what]
end

local function call(what)
    return vim.schedule_wrap(function()
        local state = get_state()
        if state then
            command(state, what)(state)
        end
    end)
end

-- The popup cannot nest, so a group of commands is a row that prompts. The
-- state is taken before the picker opens, since the choice lands with the
-- picker's focus, not the tree's.
local function choose(prompt, choices)
    return function()
        local state = get_state()
        if not state then
            return
        end
        vim.ui.select(choices, { prompt = prompt, format_item = function(c) return c[1] end }, function(choice)
            if choice then
                command(state, choice[2])(state)
            end
        end)
    end
end

return function()
    local rows = require("ui.menu").rows()
    local state = get_state()
    if not state then
        return rows.entries
    end
    local node = state.tree:get_node()
    local entry = node ~= nil and node.type ~= "message"
    local file = entry and node.type == "file"
    local below_root = entry and node:get_depth() > 1
    local clipboard = next(state.clipboard or {}) ~= nil

    rows.item(icons.open, "Open", call("open"), entry)
    rows.item(icons.vsplit, "Open in vertical split", call("open_vsplit"), file)
    rows.item(icons.hsplit, "Open in horizontal split", call("open_split"), file)
    rows.add({ separator = true })
    rows.item(icons.new_file, "New file", call("add"))
    rows.item(icons.new_folder, "New folder", call("add_directory"))
    rows.item(icons.rename, "Rename", call("rename"), below_root)
    rows.item(icons.rename, "Rename basename", call("rename_basename"), below_root)
    rows.add({ name = "File details", cmd = call("show_file_details") }, entry)
    rows.add({ separator = true })
    rows.item(icons.copy, "Copy", call("copy_to_clipboard"), below_root)
    rows.item(icons.cut, "Cut", call("cut_to_clipboard"), below_root)
    rows.item(icons.paste, "Paste", call("paste_from_clipboard"), clipboard)
    if entry then
        require("menus.file")(rows, node.path)
    end
    rows.add({ separator = true })
    rows.add({ name = "Order by", cmd = choose("Order by", {
        { "Created date", "order_by_created" },
        { "Diagnostic severity", "order_by_diagnostics" },
        { "Git status", "order_by_git_status" },
        { "Last modified", "order_by_modified" },
        { "Name", "order_by_name" },
        { "Size", "order_by_size" },
        { "Type", "order_by_type" },
    }) })
    rows.add({ name = "Find", cmd = choose("Find", {
        { "Fuzzy finder", "fuzzy_finder" },
        { "Fuzzy finder directory", "fuzzy_finder_directory" },
        { "Fuzzy sorter", "fuzzy_sorter" },
    }) })
    rows.add({ name = "Toggle hidden", cmd = call("toggle_hidden") })
    rows.add({ name = "Refresh", cmd = call("refresh") })
    rows.add({ separator = true })
    rows.item(icons.delete, "Delete", call("delete"), below_root)

    return rows.entries
end

-- Neovim's own popup menus, defined from Lua rows. A menu's right-hand side
-- is a key sequence, so a Lua callback is reached through a registry keyed
-- by menu name and rebuilt with the menu.
local M = {}

local callbacks = {}

function M.run(menu, id)
    local cb = (callbacks[menu] or {})[id]
    if cb then
        cb()
    end
end

-- Menu paths are dot-separated, so a name's own dots and spaces are escaped.
local function escape(name)
    return (name:gsub("([\\. |])", "\\%1"))
end

local function rhs(menu, entry)
    if type(entry.cmd) == "string" then
        return entry.cmd
    end

    local id = #callbacks[menu] + 1
    callbacks[menu][id] = entry.cmd
    return ("<Cmd>lua require('ui.menu').run('%s', %d)<CR>"):format(menu, id)
end

-- Separators only between rows that are shown, so a menu whose whole
-- group was left out does not open with a blank line.
local function compact(entries)
    local result = {}
    for _, entry in ipairs(entries) do
        local last = result[#result]
        if entry.separator then
            if last and not last.separator then
                result[#result + 1] = entry
            end
        else
            result[#result + 1] = entry
        end
    end
    if result[#result] and result[#result].separator then
        result[#result] = nil
    end
    return result
end

---Collects a menu's rows, leaving out those whose `when` is false.
function M.rows()
    local entries = {}
    local rows = { entries = entries }
    function rows.add(entry, when)
        if when ~= false then
            entries[#entries + 1] = entry
        end
    end

    function rows.item(icon, name, cmd, when, mode)
        rows.add({ name = icon .. "  " .. name, cmd = cmd, mode = mode }, when)
    end

    return rows
end

---Replaces `menu` with `entries`.
---@return integer rows shown
function M.define(menu, entries)
    vim.cmd("silent! aunmenu " .. menu)
    callbacks[menu] = {}
    local shown = compact(entries)
    for i, entry in ipairs(shown) do
        if entry.separator then
            vim.cmd(("anoremenu %s.-sep%d- <Nop>"):format(menu, i))
        else
            vim.cmd(("%snoremenu %s.%s %s"):format(entry.mode or "a", menu, escape(entry.name), rhs(menu, entry)))
        end
    end
    return #shown
end

---Opens `menu` at the mouse, or at the cursor; an empty menu stays closed.
---@param opts? { at_cursor: boolean }
function M.show(menu, entries, opts)
    if M.define(menu, entries) == 0 then
        return
    end
    vim.cmd((opts and opts.at_cursor and "popup " or "popup! ") .. menu)
end

return M

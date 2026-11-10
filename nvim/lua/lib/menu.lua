-- Neovim's own popup menus, defined from Lua rows.
-- A menu's right-hand side is a key sequence.
local M = {}

-- Lua callbacks, keyed by menu name and rebuilt with the menu
local callbacks = {}

function M.run(menu, id)
    local cb = (callbacks[menu] or {})[id]
    if cb then
        cb()
    end
end

-- Menu paths are dot-separated, and a name's own dots and spaces need escaping
local function escape(name) return (name:gsub("([\\. |])", "\\%1")) end

local function rhs(menu, entry)
    if type(entry.cmd) == "string" then
        return entry.cmd
    end

    local id = #callbacks[menu] + 1
    callbacks[menu][id] = entry.cmd
    return ("<Cmd>lua require('lib.menu').run('%s', %d)<CR>"):format(menu, id)
end

local function drop_stray_separators(entries)
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

---@return integer rows shown
function M.define(menu, entries)
    vim.cmd("silent! aunmenu " .. menu)
    callbacks[menu] = {}
    local shown = drop_stray_separators(entries)
    for i, entry in ipairs(shown) do
        if entry.separator then
            vim.cmd(("anoremenu %s.-sep%d- <Nop>"):format(menu, i))
        else
            vim.cmd(("%snoremenu %s.%s %s"):format(entry.mode or "a", menu, escape(entry.name), rhs(menu, entry)))
        end
    end
    return #shown
end

---@param opts? { at_cursor: boolean }
function M.show(menu, entries, opts)
    if M.define(menu, entries) == 0 then
        return
    end
    vim.cmd((opts and opts.at_cursor and "popup " or "popup! ") .. menu)
end

return M

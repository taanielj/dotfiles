-- Right-click menus are Neovim's own popup menus. 'mousemodel' is popup_setpos,
-- so a click moves the cursor and opens PopUp with no mapping involved; the
-- MenuPopup autocmd rebuilds PopUp for what is under the cursor just before it
-- shows, replacing Neovim's handler, which only disables rows.
--
-- Menus for a clicked thing that is not the buffer (the tree, a bufferline
-- tab) cannot be buffer-local, because <buffer> is rejected for PopUp, so each
-- is a separate hidden menu rebuilt from its spec in lua/menus/ when shown.
--
-- A menu entry's right-hand side is a key sequence rather than a Lua value, so
-- callbacks are reached through a registry keyed by menu name.
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

local function add(menu, path, entries)
    for i, entry in ipairs(entries) do
        if entry.separator then
            vim.cmd(("anoremenu %s.-sep%d- <Nop>"):format(path, i))
        elseif entry.items then
            add(menu, path .. "." .. escape(entry.name), entry.items)
        else
            vim.cmd(("%snoremenu %s.%s %s"):format(
                entry.mode or "a", path, escape(entry.name), rhs(menu, entry)))
        end
    end
end

-- Replaces `menu` with the entries the named spec builds for `ctx`.
function M.define(menu, spec, ctx)
    vim.cmd("silent! aunmenu " .. menu)
    callbacks[menu] = {}
    add(menu, menu, require("menus." .. spec)(ctx))
end

-- What the default menu needs to know about the buffer under the cursor.
function M.buffer_context()
    local bufnr = vim.api.nvim_get_current_buf()
    return {
        bufnr = bufnr,
        -- _get_urls() falls back to <cfile>, so any word would count
        url = vim.iter(vim.ui._get_urls()):any(function(url)
            return url:match("^%a[%w+.-]*://") ~= nil
        end),
        lsp = #vim.lsp.get_clients({ bufnr = bufnr }) > 0,
        diagnostics = #vim.diagnostic.get(bufnr) > 0,
        modifiable = vim.bo[bufnr].modifiable,
    }
end

-- Rebuilds `menu` and shows it at the mouse pointer, or at the cursor.
function M.show(menu, spec, ctx, opts)
    M.define(menu, spec, ctx)
    vim.cmd((opts and opts.at_cursor and "popup " or "popup! ") .. menu)
end

-- As show(), after moving the cursor to the clicked line the way popup_setpos
-- does for PopUp. Menu entries read the node under the cursor.
function M.show_at_mouse(menu, spec, ctx)
    local mouse = vim.fn.getmousepos()
    if mouse.winid ~= 0 and mouse.line > 0 then
        vim.api.nvim_set_current_win(mouse.winid)
        local line = math.min(mouse.line, vim.api.nvim_buf_line_count(0))
        if line > 0 then
            vim.api.nvim_win_set_cursor(mouse.winid, { line, 0 })
        end
    end

    M.show(menu, spec, ctx)
end

-- The keyboard route to the right-click menu.
function M.popup_at_cursor()
    M.show("PopUp", "default", M.buffer_context(), { at_cursor = true })
end

-- Takes PopUp over from Neovim: its handler and rows go, ours rebuild per click.
function M.setup()
    vim.cmd("silent! aunmenu PopUp")
    pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")
    M.define("PopUp", "default", M.buffer_context()) -- never empty when a click lands

    vim.api.nvim_create_autocmd("MenuPopup", {
        group = vim.api.nvim_create_augroup("user_popupmenu", { clear = true }),
        callback = function()
            M.define("PopUp", "default", M.buffer_context())
        end,
    })
end

return M

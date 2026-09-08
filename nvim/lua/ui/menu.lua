-- Neovim's own popup menus. 'mousemodel' is popup_setpos, so a right-click
-- moves the cursor and opens PopUp with no mapping; the MenuPopup autocmd
-- rebuilds PopUp for what is under the cursor, replacing Neovim's handler,
-- which only disables rows. Menus for things that are not the buffer (the
-- tree, a bufferline tab) are separate hidden menus, since PopUp cannot be
-- buffer-local. A menu's right-hand side is a key sequence, so Lua callbacks
-- are reached through a registry keyed by menu name. The terminal popup
-- executes any row, so there are no submenus: a row is an item or a separator.
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

local function add(menu, path, entries)
    for i, entry in ipairs(compact(entries)) do
        if entry.separator then
            vim.cmd(("anoremenu %s.-sep%d- <Nop>"):format(path, i))
        else
            vim.cmd(("%snoremenu %s.%s %s"):format(
                entry.mode or "a", path, escape(entry.name), rhs(menu, entry)))
        end
    end
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

function M.define(menu, spec, ctx)
    vim.cmd("silent! aunmenu " .. menu)
    callbacks[menu] = {}
    add(menu, menu, require("menus." .. spec)(ctx))
end

local symbol_captures = {
    variable = true, constant = true, parameter = true, property = true, field = true,
    ["function"] = true, method = true, constructor = true,
    type = true, module = true, namespace = true, attribute = true,
}

-- Without a parser any word counts as a symbol.
local function symbol_and_call(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return vim.fn.expand("<cword>"):match("^[%w_]+$") ~= nil, true
    end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    parser:parse({ row, row })

    local symbol = vim.iter(vim.treesitter.get_captures_at_cursor(0)):any(function(capture)
        return symbol_captures[capture:match("^[%a_]+")] == true
    end)
    local node = vim.treesitter.get_node()
    while node and not node:type():match("argument") do
        node = node:parent()
    end
    return symbol, node ~= nil
end

-- Only the servers know whether an action applies here, so they are asked;
-- one that has not answered within the wait keeps the row.
local function has_code_actions(bufnr, row)
    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" }) == 0 then
        return false
    end
    local diagnostics = vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr, { lnum = row }))
    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", function(client)
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { diagnostics = diagnostics, triggerKind = 2 }
        return params
    end, 200)
    if not results then
        return true
    end
    return vim.iter(pairs(results)):any(function(_, result)
        return result.result ~= nil and #result.result > 0
    end)
end

function M.buffer_context()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local symbol, in_call = symbol_and_call(bufnr)
    return {
        bufnr = bufnr,
        -- _get_urls() falls back to <cfile>, so any word would count
        url = vim.iter(vim.ui._get_urls()):any(function(url)
            return url:match("^%a[%w+.-]*://") ~= nil
        end),
        symbol = symbol,
        in_call = in_call,
        supports = function(method)
            return #vim.lsp.get_clients({ bufnr = bufnr, method = method }) > 0
        end,
        code_actions = has_code_actions(bufnr, row),
        line_diagnostics = #vim.diagnostic.get(bufnr, { lnum = row }) > 0,
        diagnostics = #vim.diagnostic.get(bufnr) > 0,
        modifiable = vim.bo[bufnr].modifiable,
        empty = vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "",
        clipboard = vim.fn.getreg("+") ~= "",
    }
end

function M.show(menu, spec, ctx, opts)
    M.define(menu, spec, ctx)
    vim.cmd((opts and opts.at_cursor and "popup " or "popup! ") .. menu)
end

-- Moves the cursor to the clicked line first, as popup_setpos does for PopUp,
-- because entries act on the node under the cursor.
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

function M.popup_at_cursor()
    if vim.bo.filetype == "neo-tree" then
        M.show("]NeoTree", "neotree", nil, { at_cursor = true })
    else
        M.show("PopUp", "default", M.buffer_context(), { at_cursor = true })
    end
end

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

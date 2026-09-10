-- A wrapped window keeps a fixed text width, with an empty spacer window on
-- its right taking the rest. The spacer goes with its window.
local M = {}

-- The decorations a spacer hides, remembered from its window: what an
-- ordinary window looks like in this config, without a global to ask
local DECORATIONS = { "winbar", "number", "relativenumber", "fillchars", "colorcolumn", "cursorline" }

---@type table<integer, { id: integer, decorations: table<string, any> }>
local spacer_by_window = {}

-- Unlisted keeps the spacer out of bufferline, unfocusable keeps the split
-- plugins from stepping into it (they navigate by window number, which it has
-- none of), and the separator is drawn by the window on its left.
local function open_wrap_spacer(win, width)
    local decorations = {}
    for _, option in ipairs(DECORATIONS) do
        decorations[option] = vim.wo[win][option]
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    local spacer = vim.api.nvim_open_win(buf, false, { split = "right", win = -1, width = 1, focusable = false })
    vim.wo[spacer].winfixbuf = true
    vim.wo[spacer].winbar = ""
    vim.wo[spacer].number = false
    vim.wo[spacer].relativenumber = false
    vim.wo[spacer].fillchars = "eob: "
    vim.wo[spacer].colorcolumn = ""
    vim.wo[spacer].cursorline = false
    vim.wo[win].winfixwidth = true
    vim.wo[win].fillchars = "vert: "
    vim.api.nvim_win_set_width(win, width)
    spacer_by_window[win] = { id = spacer, decorations = decorations }
end

local function splits()
    return vim.tbl_filter(
        function(win) return vim.api.nvim_win_get_config(win).relative == "" end,
        vim.api.nvim_tabpage_list_wins(0)
    )
end

-- The last split cannot close, so a spacer left alone becomes an ordinary
-- window that buffers can be switched into
local function close_wrap_spacer(win)
    local entry = spacer_by_window[win]
    spacer_by_window[win] = nil
    if not entry or not vim.api.nvim_win_is_valid(entry.id) then
        return
    end
    if #splits() > 1 then
        vim.api.nvim_win_close(entry.id, true)
        return
    end
    vim.api.nvim_win_set_config(entry.id, { focusable = true })
    vim.wo[entry.id].winfixbuf = false
    for option, value in pairs(entry.decorations) do
        vim.wo[entry.id][option] = value
    end
end

local group = vim.api.nvim_create_augroup("user_wrap_spacer", { clear = true })

-- wincmd and the mouse enter an unfocusable split anyway; step back out
vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
        local entered = vim.api.nvim_get_current_win()
        for win, entry in pairs(spacer_by_window) do
            if entry.id == entered then
                vim.api.nvim_set_current_win(
                    vim.api.nvim_win_is_valid(win) and win or vim.fn.win_getid(vim.fn.winnr("#"))
                )
                return
            end
        end
    end,
})

-- :q means the window, not its spacer: with the spacer gone first, quitting
-- the last real window quits nvim as usual
vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
        local win = vim.api.nvim_get_current_win()
        if spacer_by_window[win] then
            close_wrap_spacer(win)
        end
    end,
})

-- A spacer closed by hand is forgotten
vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
        local closed = tonumber(ev.match)
        if spacer_by_window[closed] then
            vim.schedule(function() close_wrap_spacer(closed) end)
            return
        end
        for win, entry in pairs(spacer_by_window) do
            if entry.id == closed then
                spacer_by_window[win] = nil
            end
        end
    end,
})

-- Text columns, the count or up to the colorcolumn, plus this window's gutters
local function width(win)
    local columns = vim.v.count ~= 0 and vim.v.count or tonumber(vim.wo[win].colorcolumn) or 120
    return columns + vim.fn.getwininfo(win)[1].textoff
end

-- linebreak is the flag this sets; wrap is on by default and cannot signal the state
function M.toggle()
    local win = vim.api.nvim_get_current_win()
    if vim.wo.linebreak then
        vim.wo.wrap = false
        vim.wo.linebreak = false
        vim.wo.breakindent = false
        vim.wo.breakindentopt = ""
        vim.wo.winfixwidth = false
        local entry = spacer_by_window[win]
        vim.wo.fillchars = entry and entry.decorations.fillchars or ""
        vim.wo.colorcolumn = entry and entry.decorations.colorcolumn or ""
        close_wrap_spacer(win)
        return
    end

    vim.wo.wrap = true
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "list:2"
    open_wrap_spacer(win, width(win))
    -- The window edge is the colorcolumn now
    vim.wo.colorcolumn = ""
end

return M

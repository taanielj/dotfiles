-- A wrapped window keeps a fixed text width, with an empty spacer window on
-- its right taking the rest. The spacer goes with its window.
local M = {}

local spacer_by_window = {}

local function open_wrap_spacer(win, width)
    vim.cmd("vertical rightbelow new")
    local spacer = vim.api.nvim_get_current_win()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.wo.winbar = ""
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, width)
    spacer_by_window[win] = spacer
end

local function splits()
    return vim.tbl_filter(
        function(win) return vim.api.nvim_win_get_config(win).relative == "" end,
        vim.api.nvim_tabpage_list_wins(0)
    )
end

-- The last split cannot close, so a spacer left alone stays as a window
local function close_wrap_spacer(win)
    local spacer = spacer_by_window[win]
    spacer_by_window[win] = nil
    if spacer and vim.api.nvim_win_is_valid(spacer) and #splits() > 1 then
        vim.api.nvim_win_close(spacer, true)
    end
end

-- A spacer closed by hand is forgotten
vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("user_wrap_spacer", { clear = true }),
    callback = function(ev)
        local closed = tonumber(ev.match)
        if spacer_by_window[closed] then
            vim.schedule(function() close_wrap_spacer(closed) end)
            return
        end
        for win, spacer in pairs(spacer_by_window) do
            if spacer == closed then
                spacer_by_window[win] = nil
            end
        end
    end,
})

-- linebreak is the flag this sets; wrap is on by default and cannot signal the state
function M.toggle()
    local win = vim.api.nvim_get_current_win()
    if vim.wo.linebreak then
        vim.wo.wrap = false
        vim.wo.linebreak = false
        vim.wo.breakindent = false
        vim.wo.breakindentopt = ""
        close_wrap_spacer(win)
        return
    end

    vim.wo.wrap = true
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "list:2"
    open_wrap_spacer(win, vim.v.count ~= 0 and vim.v.count or 125)
end

return M

-- Strips the window down to the text: numbers, signs, the statusline and
-- tab bar, the tree, and the multiplexer's chrome around nvim. Leaving
-- restores what was taken, from a snapshot, so the options come back as
-- they were set and not as this file remembers them.
local M = {}

local bare = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    cursorline = false,
    colorcolumn = "",
}

-- nil while off; otherwise what to hand back
local state

local function tree_is_open()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
            return true
        end
    end
    return false
end

local function enter()
    local win = vim.api.nvim_get_current_win()
    state = {
        win = win,
        window = {},
        laststatus = vim.o.laststatus,
        showtabline = vim.o.showtabline,
        tree = tree_is_open(),
    }
    for option, value in pairs(bare) do
        state.window[option] = vim.wo[win][option]
        vim.wo[win][option] = value
    end
    require("lualine").hide({ unhide = false, place = { "statusline", "tabline", "winbar" } })
    vim.o.laststatus = 0
    vim.o.showtabline = 0

    state.mux = require("lib.mux").zoom_in()

    if state.tree then
        vim.cmd("Neotree close")
    end
end

local function leave()
    local win = vim.api.nvim_win_is_valid(state.win) and state.win or vim.api.nvim_get_current_win()
    for option, value in pairs(state.window) do
        vim.wo[win][option] = value
    end
    require("lualine").hide({ unhide = true, place = { "statusline", "tabline", "winbar" } })
    vim.o.laststatus = state.laststatus
    vim.o.showtabline = state.showtabline
    vim.cmd("redraw!")

    require("lib.mux").restore(state.mux)

    if state.tree then
        -- "show" reopens the tree without focusing it, so the cursor stays put
        vim.cmd("Neotree show reveal")
        vim.schedule(function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
            end
        end)
    end
    state = nil
end

function M.toggle()
    if state then
        leave()
    else
        enter()
    end
end

function M.is_active()
    return state ~= nil
end

return M

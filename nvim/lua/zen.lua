local _zen_mode_active = false
local _neotree_was_open = false
local _tmux_was_zoomed = false

local function is_neo_tree_open()
    -- Checks whether any window has a filetype of "neo-tree"
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        if ft == "neo-tree" then
            return true
        end
    end
    return false
end

local function is_tmux_zoomed()
    local handle = io.popen("tmux list-panes -F '#{?pane_active,#{window_zoomed_flag},}'")
    if not handle then
        return false
    end
    local result = handle:read("*a")
    handle:close()
    return result:match("1") ~= nil
end

-- Thin wrapper for tmux commands
local function tmux(cmd)
    os.execute("tmux " .. cmd .. " >/dev/null 2>&1 || true")
end

-- Applies zen mode UI and remembers external state
local function zen()
    _neotree_was_open = is_neo_tree_open()
    _tmux_was_zoomed = is_tmux_zoomed()

    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.cursorline = false
    vim.wo.colorcolumn = ""
    require("lualine").hide({ unhide = false, place = { "statusline", "tabline", "winbar" } })
    vim.o.laststatus = 0
    vim.o.showtabline = 0

    tmux("set status off")
    if not _tmux_was_zoomed then
        tmux("resize-pane -Z")
    end

    if _neotree_was_open then
        vim.cmd("Neotree close")
    end
end

-- Restores UI and external state as it was before zen
local function unzen()
    if not _zen_mode_active then
        return
    end
    vim.wo.number = true
    vim.wo.relativenumber = true
    vim.wo.signcolumn = "yes"
    vim.wo.cursorline = true
    vim.wo.colorcolumn = "121"
    require("lualine").hide({ unhide = true, place = { "statusline", "tabline", "winbar" } })
    vim.o.laststatus = 3
    vim.o.showtabline = 2
    vim.cmd("redraw!")

    tmux("set status on")
    if not _tmux_was_zoomed then
        tmux("resize-pane -Z")
    end

    if _neotree_was_open then
        vim.cmd("Neotree reveal")
    end
end

-- Entry point
local function toggle_zen_mode()
    if _zen_mode_active then
        unzen()
        _zen_mode_active = false
    else
        zen()
        _zen_mode_active = true
    end
end


vim.keymap.set("n", "<leader>z", toggle_zen_mode, {
    noremap = true,
    silent = true,
    desc = "Toggle Zen Mode",
})

return {
    toggle = toggle_zen_mode,
    is_tmux_zoomed = is_tmux_zoomed,
    is_neo_tree_open = is_neo_tree_open,
    zen = zen,
    unzen = unzen,
    is_active = function()
        return _zen_mode_active
    end,
}

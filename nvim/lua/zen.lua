local _zen_mode_active = false
local _neotree_was_open = false
local _mux_was_zoomed = {}

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

-- Runs a command, ignoring failures (the multiplexer may be gone)
local function run(cmd)
    os.execute(cmd .. " >/dev/null 2>&1 || true")
end

-- Runs a command and returns its output, or "" if it could not start
local function capture(cmd)
    local handle = io.popen(cmd .. " 2>/dev/null")
    if not handle then
        return ""
    end
    local out = handle:read("*a") or ""
    handle:close()
    return out
end

local function tmux_is_zoomed()
    return capture("tmux list-panes -F '#{?pane_active,#{window_zoomed_flag},}'"):match("1") ~= nil
end

-- herdr's --current follows the focused pane, so address this pane by id
local function herdr_pane()
    return vim.fn.shellescape(vim.env.HERDR_PANE_ID)
end

local function herdr_is_zoomed()
    return capture("herdr pane layout --pane " .. herdr_pane()):match('"zoomed"%s*:%s*true') ~= nil
end

-- Zen applies to every multiplexer that is present, so nvim in tmux in herdr
-- zooms both rather than picking a winner.
local muxes = {
    {
        name = "tmux",
        present = function()
            return vim.env.TMUX ~= nil
        end,
        is_zoomed = tmux_is_zoomed,
        set_zoom = function(on)
            -- resize-pane -Z only toggles, so check where we are first
            if tmux_is_zoomed() ~= on then
                run("tmux resize-pane -Z")
            end
        end,
        set_chrome = function(visible)
            run("tmux set status " .. (visible and "on" or "off"))
        end,
    },
    {
        name = "herdr",
        present = function()
            return vim.env.HERDR_ENV == "1" and vim.env.HERDR_PANE_ID ~= nil
        end,
        is_zoomed = herdr_is_zoomed,
        set_zoom = function(on)
            run("herdr pane zoom --pane " .. herdr_pane() .. (on and " --on" or " --off"))
        end,
        -- The sidebar and tab bar are config-time only, so nothing to hide here
        set_chrome = function() end,
    },
}

local function active_muxes()
    local found = {}
    for _, mux in ipairs(muxes) do
        if mux.present() then
            table.insert(found, mux)
        end
    end
    return found
end

-- Applies zen mode UI and remembers external state
local function zen()
    _neotree_was_open = is_neo_tree_open()

    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.cursorline = false
    vim.wo.colorcolumn = ""
    require("lualine").hide({ unhide = false, place = { "statusline", "tabline", "winbar" } })
    vim.o.laststatus = 0
    vim.o.showtabline = 0

    for _, mux in ipairs(active_muxes()) do
        _mux_was_zoomed[mux.name] = mux.is_zoomed()
        mux.set_chrome(false)
        mux.set_zoom(true)
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

    for _, mux in ipairs(active_muxes()) do
        mux.set_chrome(true)
        mux.set_zoom(_mux_was_zoomed[mux.name] == true)
    end

    if _neotree_was_open then
        -- "show" reopens the tree without focusing it, so the cursor stays put
        local win = vim.api.nvim_get_current_win()
        vim.cmd("Neotree show reveal")
        vim.schedule(function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
            end
        end)
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
    is_neo_tree_open = is_neo_tree_open,
    active_muxes = active_muxes,
    zen = zen,
    unzen = unzen,
    is_active = function()
        return _zen_mode_active
    end,
}

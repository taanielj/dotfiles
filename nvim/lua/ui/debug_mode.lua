-- While a debug session runs, single keys drive it the way insert mode takes
-- over typing. The global mappings they shadow come back when it ends;
-- buffer-local ones still win inside their buffers.
local M = {}

-- stylua: ignore
local keys = {
    { "c", function() require("dap").continue() end,          "Continue" },
    { "n", function() require("dap").step_over() end,         "Step over" },
    { "s", function() require("dap").step_into() end,         "Step into" },
    { "o", function() require("dap").step_out() end,          "Step out" },
    { "r", function() require("dap").run_to_cursor() end,     "Run to cursor" },
    { "t", function() require("dap").toggle_breakpoint() end, "Toggle breakpoint" },
    { "K", function() require("dap-view").hover() end,        "Inspect value" },
    { "q", function() require("dap").terminate() end,         "Terminate" },
}

-- nil while off; otherwise each key's global mapping from before, false for none
local shadowed

-- maparg() would hand back a buffer-local mapping of the current buffer
local function global_mapping(lhs)
    for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
        if mapping.lhs == lhs then
            return mapping
        end
    end
    return false
end

local function enter()
    shadowed = {}
    for _, key in ipairs(keys) do
        shadowed[key[1]] = global_mapping(key[1])
        vim.keymap.set("n", key[1], key[2], { silent = true, desc = "Debug: " .. key[3] })
    end
end

local function leave()
    for lhs, mapping in pairs(shadowed) do
        if mapping then
            vim.fn.mapset(mapping)
        else
            vim.keymap.del("n", lhs)
        end
    end
    shadowed = nil
end

local function set_active(active)
    if active == M.is_active() then
        return
    end
    if active then
        enter()
    else
        leave()
    end
    if package.loaded.lualine then
        require("lualine").refresh()
    end
end

function M.is_active() return shadowed ~= nil end

function M.toggle() set_active(not M.is_active()) end

function M.setup()
    local dap = require("dap")
    dap.listeners.after.event_initialized.debug_mode = function() set_active(true) end

    local function on_end()
        -- The ending session still counts among dap.sessions()
        if vim.tbl_count(dap.sessions()) <= 1 then
            set_active(false)
        end
    end
    dap.listeners.before.event_terminated.debug_mode = on_end
    dap.listeners.before.disconnect.debug_mode = on_end
end

return M

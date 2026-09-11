-- Inside herdr, a program the debug adapter starts in a terminal runs in a
-- herdr pane below this nvim. The pane exits along with a program that
-- succeeds, stays open to read one that fails, and closes when the session is
-- terminated.
local M = {}

---@param label string
local function close_panes(label)
    local herdr = require("lib.herdr").bin()
    vim.system({ herdr, "pane", "list" }, { text = true }, function(res)
        if res.code ~= 0 then
            return
        end
        for _, pane in ipairs(vim.json.decode(res.stdout).result.panes) do
            if pane.label == label then
                vim.system({ herdr, "pane", "close", pane.pane_id })
            end
        end
    end)
end

function M.setup()
    local pane_id = require("lib.herdr").pane_id()
    -- A popup has no pane to split
    if not pane_id then
        return
    end
    local label = "debug " .. pane_id
    local dap = require("dap")
    dap.defaults.fallback.force_external_terminal = true
    dap.defaults.fallback.external_terminal = {
        command = "bash",
        args = { vim.fn.expand("~/.config/herdr/bin/herdr-dap-pane.sh"), label },
    }
    -- dap.terminate() sends terminate when the adapter supports it, disconnect otherwise
    local function on_terminate() close_panes(label) end
    dap.listeners.before.terminate.herdr_debug_pane = on_terminate
    dap.listeners.before.disconnect.herdr_debug_pane = on_terminate
end

return M

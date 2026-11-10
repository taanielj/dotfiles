-- Inside herdr or the Herdr app, a program the debug adapter starts in a
-- terminal runs in a pane below this nvim.
-- - When the program succeeds, the pane closes.
-- - When the program fails, the pane stays open to read its output.
-- - When the session is terminated, the pane closes.
local M = {}

---@param label string
local function close_herdr_panes(label)
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
    local host = require("lib.pane_host")()
    -- A popup has no pane to split
    local pane_id = host and host.pane_id()
    if not pane_id then
        return
    end
    local app = host == require("lib.herdr_app")
    -- Inside herdr, close_herdr_panes finds the debug panes by label. Inside the
    -- Herdr app, dap-pane.sh writes the debug terminals' addresses to `state`.
    local label = "debug " .. pane_id
    local state = vim.fs.joinpath(vim.fn.stdpath("state"), "debug-terminals", pane_id)
    local script = app and "~/.config/herdr-app/bin/dap-pane.sh" or "~/.config/herdr/bin/herdr-dap-pane.sh"
    local dap = require("dap")
    dap.defaults.fallback.force_external_terminal = true
    dap.defaults.fallback.external_terminal = {
        command = "bash",
        args = { vim.fn.expand(script), app and state or label },
    }
    -- dap.terminate() sends terminate when the adapter supports it, disconnect otherwise
    local function on_terminate()
        if not app then
            return close_herdr_panes(label)
        end
        for _, terminal in ipairs(vim.fn.filereadable(state) == 1 and vim.fn.readfile(state) or {}) do
            vim.system({ "hc", "kill", terminal })
        end
        vim.fn.delete(state)
    end
    dap.listeners.before.terminate.herdr_debug_pane = on_terminate
    dap.listeners.before.disconnect.herdr_debug_pane = on_terminate
end

return M

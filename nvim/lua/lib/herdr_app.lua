-- The Herdr desktop app (herdr-app/), whose terminals run in herdr-core.
local M = {}

---@return boolean nvim runs in a terminal of the Herdr app, not the herdr TUI
function M.inside() return vim.env.HC_TERMINAL_ID ~= nil and not require("lib.herdr").inside() end

---Run a Herdr app command in the background, reporting a failure.
---@param command string an app command, or <mod>.<command> for a mod's
---@param args? table<string, string|number|boolean>
function M.run(command, args)
    local cmd = { "herdr-app", "do", command }
    if args then
        table.insert(cmd, vim.json.encode(args))
    end
    vim.system(cmd, { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("herdr-app: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        end
    end)
end

return M

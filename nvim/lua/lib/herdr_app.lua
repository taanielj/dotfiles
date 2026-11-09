-- The Herdr desktop app (herdr-app/), whose terminals run in herdr-core. It
-- answers the same calls as lib/herdr.lua, with a terminal address (t7) where
-- herdr has a pane id.
local M = {}

-- The variable naming the terminal a process runs in
M.ENV = "HC_TERMINAL_ID"

---@return boolean nvim runs in a terminal of the Herdr app, not the herdr TUI
function M.inside() return vim.env.HC_TERMINAL_ID ~= nil and not require("lib.herdr").inside() end

---@return string? this terminal's address
function M.pane_id() return vim.env.HC_TERMINAL_ID end

---Run a command in the background, reporting a failure.
---@param cmd string[]
---@param on_success? fun() runs in the main loop once it exits 0
local function system(cmd, on_success)
    vim.system(cmd, { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify(cmd[1] .. ": " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        elseif on_success then
            vim.schedule(on_success)
        end
    end)
end

---Run a Herdr app command in the background, reporting a failure.
---@param command string an app command, or <mod>.<command> for a mod's
---@param args? table<string, string|number|boolean>
function M.run(command, args)
    local cmd = { "herdr-app", "do", command }
    if args then
        table.insert(cmd, vim.json.encode(args))
    end
    system(cmd)
end

---@param terminal string
---@return table? space, table? tab: where `herdr-app ls` shows the terminal
local function place(terminal)
    local res = vim.system({ "herdr-app", "ls" }, { text = true }):wait()
    local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
    for _, space in ipairs(ok and data.spaces or {}) do
        for _, tab in ipairs(space.tabs) do
            for _, t in ipairs(tab.terminals) do
                if t.terminal == terminal then
                    return space, tab
                end
            end
        end
    end
    return nil, nil
end

---@return string? this terminal's tab
function M.tab_id()
    local _, tab = place(vim.env.HC_TERMINAL_ID)
    return tab and tab.id
end

---@param terminal string
function M.focus(terminal) M.run("pane.focus", { terminal = terminal }) end

---Submit text to the agent in a terminal.
---@param terminal string
---@param text string
---@param on_success? fun()
function M.prompt(terminal, text, on_success) system({ "hc", "send", terminal, text }, on_success) end

---Press Enter in a terminal once its screen shows `match`.
---@param terminal string
---@param match string
---@param on_timeout fun() runs in the main loop when it never shows
function M.enter_when_shown(terminal, match, on_timeout)
    local poll = 'for _ in $(seq 30); do hc read "$1" | grep -qF -- "$2" && exec hc keys "$1" enter; sleep 0.1; done; exit 1'
    vim.system({ "sh", "-c", poll, "sh", terminal, match }, {}, function(res)
        if res.code ~= 0 then
            vim.schedule(on_timeout)
        end
    end)
end

---@param terminal string
---@return lib.Pane?
function M.pane(terminal)
    local res = vim.system({ "hc", "ls", "--json" }, { text = true }):wait()
    local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
    for _, t in ipairs(ok and data.terminals or {}) do
        if t.address == terminal then
            local _, tab = place(terminal)
            return tab and { id = terminal, tab = tab.id, claude = t.agent == "claude-code", title = t.agent, cwd = t.cwd or "" }
        end
    end
    return nil
end

---Calls back in the main loop with this terminal's space and tab names.
---@param on_result fun(space: string?, tab: string?)
function M.labels(on_result)
    vim.schedule(function()
        local space, tab = place(vim.env.HC_TERMINAL_ID)
        on_result(space and space.name, tab and tab.name)
    end)
end

return M

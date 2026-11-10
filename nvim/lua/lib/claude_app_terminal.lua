-- claudecode.nvim's terminal provider inside the Herdr app. Claude runs in an
-- app pane below this nvim, as herdr-agents.nvim does inside the herdr TUI.
local app = require("lib.herdr_app")

local M = {}

---@type string? the address of this nvim's Claude terminal
local terminal

---@param args string[]
---@return table?
local function herdr_app(args)
    local res = vim.system(vim.list_extend({ "herdr-app", "do" }, args), { text = true }):wait()
    local ok, reply = pcall(vim.json.decode, res.stdout or "")
    if res.code ~= 0 or not ok then
        vim.notify("herdr-app: " .. vim.trim(res.stdout or res.stderr or ""), vim.log.levels.ERROR)
        return nil
    end
    return reply
end

---@return boolean
local function running()
    if not terminal then
        return false
    end
    local res = vim.system({ "hc", "get", terminal, "--json" }, { text = true }):wait()
    local ok, info = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
    if ok and info.state == "live" then
        return true
    end
    terminal = nil
    return false
end

---@return string? Claude's pane, nil while parked
local function pane()
    local res = vim.system({ "herdr-app", "ls" }, { text = true }):wait()
    local ok, data = pcall(vim.json.decode, res.stdout or "")
    for _, space in ipairs(ok and data.spaces or {}) do
        for _, tab in ipairs(space.tabs) do
            for _, t in ipairs(tab.terminals) do
                if t.terminal == terminal then
                    return t.pane
                end
            end
        end
    end
    return nil
end

local function focused()
    local res = vim.system({ "herdr-app", "status" }, { text = true }):wait()
    local ok, status = pcall(vim.json.decode, res.stdout or "")
    return ok and status.focused_pane == pane()
end

local function focus_nvim() app.focus(assert(app.pane_id())) end

local function show(focus)
    if not pane() then
        herdr_app({ "terminal.keep", "--terminal", terminal, "--place", "down" })
    elseif focus ~= false then
        app.focus(terminal)
    end
    if focus == false then
        focus_nvim()
    end
end

-- Claude keeps running in a parked terminal
local function hide() herdr_app({ "terminal.park", "--terminal", terminal }) end

function M.setup() end

---@param cmd string
---@param env table<string, string>
---@param _ table
---@param focus boolean?
function M.open(cmd, env, _, focus)
    if running() then
        return show(focus)
    end
    -- App panes don't inherit nvim's environment. Claude finds nvim's lock file in $CLAUDE_CONFIG_DIR/ide/.
    env = vim.tbl_extend("keep", env, { CLAUDE_CONFIG_DIR = vim.env.CLAUDE_CONFIG_DIR })
    local argv = { "env" }
    for key, value in pairs(env) do
        argv[#argv + 1] = key .. "=" .. value
    end
    vim.list_extend(argv, require("claudecode.utils").parse_command(cmd))
    local reply = herdr_app({
        "terminal.open",
        vim.json.encode({ argv = argv, folder = vim.fn.getcwd(), place = "down" }),
    })
    terminal = reply and reply.terminal
    if focus == false then
        focus_nvim()
    end
end

function M.close()
    if running() then
        vim.system({ "hc", "kill", terminal }):wait()
        terminal = nil
    end
end

function M.simple_toggle(cmd, env, config)
    if running() and pane() then
        hide()
    else
        M.open(cmd, env, config)
    end
end

function M.focus_toggle(cmd, env, config)
    if running() and pane() and focused() then
        hide()
    else
        M.open(cmd, env, config)
    end
end

function M.get_active_bufnr() return nil end

function M.is_available() return app.inside() end

return M

-- The herdr panes of the Claude sessions connected to this nvim's claudecode
-- server, found through the open connections themselves: a session attached
-- with /ide counts the same as one this nvim started.
local M = {}

---@param cmd string[]
---@return string? stdout, nil when the command failed
local function run(cmd)
    local res = vim.system(cmd, { text = true }):wait()
    return res.code == 0 and res.stdout or nil
end

---@return integer[] pids at the other end of the claudecode server's connections
local function connected_pids()
    local port = require("claudecode").state.port
    local out = port and run({ "lsof", "-nP", "-a", "-iTCP:" .. port, "-sTCP:ESTABLISHED", "-Fp" }) or ""
    local own, pids = vim.fn.getpid(), {}
    for pid in out:gmatch("p(%d+)") do
        if tonumber(pid) ~= own then
            pids[#pids + 1] = tonumber(pid)
        end
    end
    return pids
end

---@param pid integer
---@return string? the herdr pane the process runs in
local function pane_of(pid)
    local environ = io.open(("/proc/%d/environ"):format(pid), "rb")
    local env
    if environ then
        env = environ:read("a"):gsub("%z", "\n")
        environ:close()
    else
        env = (run({ "ps", "eww", "-o", "command=", "-p", tostring(pid) }) or ""):gsub(" ", "\n")
    end
    return env:match("HERDR_PANE_ID=([^\n]+)")
end

---@param id string
---@return table? herdr's pane record
local function pane_info(id)
    local ok, data = pcall(vim.json.decode, run({ require("lib.herdr").bin(), "pane", "get", id }) or "")
    return ok and vim.tbl_get(data, "result", "pane") or nil
end

---@return table[] Claude panes, those in this nvim's tab first
local function candidates()
    local seen, panes = {}, {}
    for _, pid in ipairs(connected_pids()) do
        local id = pane_of(pid)
        if id and not seen[id] then
            seen[id] = true
            local pane = pane_info(id)
            if pane and pane.agent == "claude" then
                panes[#panes + 1] = pane
            end
        end
    end
    local tab = vim.env.HERDR_TAB_ID
    local here = vim.tbl_filter(function(pane) return pane.tab_id == tab end, panes)
    return #here > 0 and here or panes
end

---Calls back with the Claude pane connected to this nvim, asking when there are several.
---@param on_pane fun(pane_id: string)
function M.pick(on_pane)
    local panes = candidates()
    if #panes == 0 then
        vim.notify("No Claude session connected to this nvim; /ide in Claude connects one", vim.log.levels.WARN)
    elseif #panes == 1 then
        on_pane(panes[1].pane_id)
    else
        vim.ui.select(panes, {
            prompt = "Claude pane",
            format_item = function(pane) return ("%s  %s"):format(pane.terminal_title_stripped or "", pane.cwd or "") end,
        }, function(pane)
            if pane then
                on_pane(pane.pane_id)
            end
        end)
    end
end

return M

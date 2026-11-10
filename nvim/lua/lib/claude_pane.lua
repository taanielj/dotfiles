-- Finds the herdr or Herdr app panes of the Claude sessions connected to this
-- nvim's claudecode server. Looking up the processes on the server's open
-- connections finds a session attached with /ide as well as one this nvim
-- started.
local M = {}

---@param cmd string[]
---@return string?
local function run(cmd)
    local res = vim.system(cmd, { text = true }):wait()
    return res.code == 0 and res.stdout or nil
end

---@return integer[]
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
---@param pane_id_var string
---@return string?
local function pane_of(pid, pane_id_var)
    local environ = io.open(("/proc/%d/environ"):format(pid), "rb")
    local env
    if environ then
        env = environ:read("a"):gsub("%z", "\n")
        environ:close()
    else
        env = (run({ "ps", "eww", "-o", "command=", "-p", tostring(pid) }) or ""):gsub(" ", "\n")
    end
    return env:match(pane_id_var .. "=([^\n]+)")
end

---@return lib.Pane[] Claude panes, those in this nvim's tab first
local function candidates()
    local host = require("lib.pane_host")()
    if not host then
        return {}
    end
    local seen, panes = {}, {}
    for _, pid in ipairs(connected_pids()) do
        local id = pane_of(pid, host.PANE_ID_VAR)
        if id and not seen[id] then
            seen[id] = true
            local pane = host.pane(id)
            if pane and pane.is_claude then
                panes[#panes + 1] = pane
            end
        end
    end
    local tab = host.tab_id()
    local here = vim.tbl_filter(function(pane) return pane.tab == tab end, panes)
    return #here > 0 and here or panes
end

---Calls back with the Claude pane connected to this nvim, asking when there are several.
---@param on_pane fun(pane_id: string)
function M.pick(on_pane)
    local panes = candidates()
    if #panes == 0 then
        vim.notify("No Claude session connected to this nvim; /ide in Claude connects one", vim.log.levels.WARN)
    elseif #panes == 1 then
        on_pane(panes[1].id)
    else
        vim.ui.select(panes, {
            prompt = "Claude pane",
            format_item = function(pane) return ("%s  %s"):format(pane.title, pane.cwd) end,
        }, function(pane)
            if pane then
                on_pane(pane.id)
            end
        end)
    end
end

return M

-- A Claude pane keeps the port and token of the nvim that opened it. The next
-- nvim in the same directory takes both back when the port is still free, so
-- that Claude reattaches instead of pointing at a dead server.
local M = {}

local function store()
    local dir = vim.fn.stdpath("data") .. "/claudecode-ports"
    vim.fn.mkdir(dir, "p")
    return dir .. "/" .. vim.fn.sha256(vim.fn.getcwd()):sub(1, 16) .. ".json"
end

---@return { port: integer, token: string? }?
local function saved()
    local lines = vim.fn.filereadable(store()) == 1 and vim.fn.readfile(store()) or {}
    local ok, data = pcall(vim.json.decode, table.concat(lines))
    return ok and type(data) == "table" and type(data.port) == "number" and data or nil
end

-- bind alone passes on a port another process listens on; listen is the real test
local function free(port)
    local sock = vim.uv.new_tcp()
    if not sock then
        return false
    end
    local ok = sock:bind("127.0.0.1", port) == 0 and sock:listen(1, function() end) == 0
    sock:close()
    return ok
end

---The port_range for claudecode.setup(): the saved port when it is free, else nil for the default range.
---@return { min: integer, max: integer }?
function M.reuse()
    local data = saved()
    if not (data and free(data.port)) then
        return nil
    end
    if data.token then
        local lockfile = require("claudecode.lockfile")
        local generate, token = lockfile.generate_auth_token, data.token
        -- the saved token serves the first call, fresh ones after
        ---@diagnostic disable-next-line: duplicate-set-field
        lockfile.generate_auth_token = function()
            local first = token
            token = nil
            return first or generate()
        end
    end
    return { min = data.port, max = data.port }
end

function M.remember()
    local state = require("claudecode").state
    if not state.port then
        return
    end
    vim.fn.writefile({ vim.json.encode({ port = state.port, token = state.auth_token }) }, store())
    vim.fn.setfperm(store(), "rw-------")
end

return M

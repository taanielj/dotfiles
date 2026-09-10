-- The herdr multiplexer announces itself through the environment: HERDR_ENV
-- inside any of its panes, HERDR_SOCKET_PATH where its agent bridge listens.
local M = {}

function M.inside() return vim.env.HERDR_ENV == "1" end

---@return string the herdr executable, as herdr announces it to its panes
function M.bin() return vim.env.HERDR_BIN_PATH or "herdr" end

---@return string? the agent bridge socket
function M.socket()
    local path = vim.env.HERDR_SOCKET_PATH
    if path ~= nil and path ~= "" then
        return path
    end
    return nil
end

return M

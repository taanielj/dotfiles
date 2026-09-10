-- The herdr multiplexer announces itself through the environment: HERDR_ENV
-- and HERDR_SOCKET_PATH in every pane and popup it runs, HERDR_PANE_ID in a
-- tiled pane only.
local M = {}

function M.inside() return vim.env.HERDR_ENV == "1" end

---@return string the herdr executable, as herdr announces it to its panes
function M.bin() return vim.env.HERDR_BIN_PATH or "herdr" end

---@return string? this pane's id; nil in a popup
function M.pane_id()
    local id = vim.env.HERDR_PANE_ID
    if id ~= nil and id ~= "" then
        return id
    end
    return nil
end

---@return string? the agent bridge socket
function M.socket()
    local path = vim.env.HERDR_SOCKET_PATH
    if path ~= nil and path ~= "" then
        return path
    end
    return nil
end

return M

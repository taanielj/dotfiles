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

---Run herdr in the background, reporting a failure.
---@param args string[] everything after the executable
function M.run(args)
    vim.system(vim.list_extend({ M.bin() }, args), { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("herdr: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        end
    end)
end

return M

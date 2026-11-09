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
---@param on_success? fun() runs in the main loop once herdr exits 0
function M.run(args, on_success)
    vim.system(vim.list_extend({ M.bin() }, args), { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("herdr: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        elseif on_success then
            vim.schedule(on_success)
        end
    end)
end

---Focus a pane by id through herdr's socket, because the CLI focuses only by
---direction.
---@param pane string
function M.focus(pane)
    local pipe = assert(vim.uv.new_pipe())
    pipe:connect(vim.env.HERDR_SOCKET_PATH, function(err)
        if err then
            return pipe:close()
        end
        pipe:write(vim.json.encode({ id = "focus", method = "pane.focus", params = { pane_id = pane } }) .. "\n")
        -- Closes once herdr replies
        pipe:read_start(function()
            if not pipe:is_closing() then
                pipe:close()
            end
        end)
    end)
end

return M

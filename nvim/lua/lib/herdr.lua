local M = {}

-- The variable naming the herdr pane a process runs in
M.ENV = "HERDR_PANE_ID"

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

---@return string? this pane's tab
function M.tab_id() return vim.env.HERDR_TAB_ID end

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

---Submit text to the agent in a pane.
---@param pane string
---@param text string
---@param on_success? fun()
function M.prompt(pane, text, on_success) M.run({ "agent", "prompt", pane, text }, on_success) end

---Press Enter in a pane once its screen shows `match`.
---@param pane string
---@param match string
---@param on_timeout fun() runs in the main loop when it never shows
function M.enter_when_shown(pane, match, on_timeout)
    local wait = { M.bin(), "pane", "wait-output", pane, "--source", "visible", "--match", match, "--timeout", "3000" }
    vim.system(wait, { text = true }, function(res)
        if res.code == 0 then
            M.run({ "pane", "send-keys", pane, "enter" })
        else
            vim.schedule(on_timeout)
        end
    end)
end

---@class lib.Pane
---@field id string
---@field tab string
---@field claude boolean Claude Code runs in it
---@field title string
---@field cwd string

---@param id string
---@return lib.Pane?
function M.pane(id)
    local res = vim.system({ M.bin(), "pane", "get", id }, { text = true }):wait()
    local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
    local pane = ok and vim.tbl_get(data, "result", "pane")
    if not pane then
        return nil
    end
    return {
        id = pane.pane_id,
        tab = pane.tab_id,
        claude = pane.agent == "claude",
        title = pane.terminal_title_stripped or "",
        cwd = pane.cwd or "",
    }
end

---@param kind "tab"|"workspace"
---@param on_result fun(info: table?)
local function get(kind, id, on_result)
    vim.system({ M.bin(), kind, "get", id }, { text = true }, function(res)
        local ok, data = pcall(vim.json.decode, res.stdout or "")
        vim.schedule(function() on_result(ok and vim.tbl_get(data, "result", kind) or nil) end)
    end)
end

---Calls back in the main loop with this pane's workspace and tab labels.
---@param on_result fun(space: string?, tab: string?)
function M.labels(on_result)
    local tab_id = M.tab_id()
    if not tab_id or tab_id == "" then
        return
    end
    get("tab", tab_id, function(tab)
        if not tab then
            return
        end
        get("workspace", tab.workspace_id, function(workspace) on_result(workspace and workspace.label, tab.label) end)
    end)
end

return M

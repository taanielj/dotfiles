local M = {}

M.PANE_ID_VAR = "HERDR_PANE_ID"

function M.inside() return vim.env.HERDR_ENV == "1" end

---@return string
function M.bin() return vim.env.HERDR_BIN_PATH or "herdr" end

---@return string? nil in a popup
function M.pane_id()
    local id = vim.env.HERDR_PANE_ID
    if id ~= nil and id ~= "" then
        return id
    end
    return nil
end

---@return string?
function M.tab_id() return vim.env.HERDR_TAB_ID end

-- The TUI client writes its sidebar state to a file under herdr's state dir,
-- named by an FNV-1a hash of its client socket, a sibling of HERDR_SOCKET_PATH
-- (herdr's src/client/shell/preferences.rs).
local function client_state_path()
    local socket = vim.fs.dirname(vim.env.HERDR_SOCKET_PATH) .. "/herdr-client.sock"
    local ffi = require("ffi")
    local hash = ffi.new("uint64_t", 0xcbf29ce484222325ULL)
    for _, byte in ipairs({ socket:byte(1, -1) }) do
        hash = bit.bxor(hash, ffi.new("uint64_t", byte)) * 0x100000001b3ULL
    end
    local state_dir = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
    return state_dir .. "/herdr/client-shell/local-" .. bit.tohex(hash, 16) .. ".json"
end

---@return boolean false while the state is unreadable, as herdr starts expanded
function M.sidebar_collapsed()
    local file = io.open(client_state_path())
    if not file then
        return false
    end
    local ok, state = pcall(vim.json.decode, file:read("a"))
    file:close()
    return ok and state.sidebar_collapsed == true
end

---Hammerspoon types prefix+b (herdr/tui/config.toml) into the focused
---terminal, because the TUI has no command for its sidebar and only that
---binding toggles it.
function M.toggle_sidebar()
    local chord = 'hs.eventtap.keyStroke({ "ctrl" }, "space") hs.eventtap.keyStroke({}, "b")'
    vim.system({ "hs", "-c", chord }, { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("hs: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        end
    end)
end

---@param args string[]
---@param on_success? fun()
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

---Goes through herdr's socket, because herdr's CLI focuses panes only by
---direction.
---@param pane string
function M.focus(pane)
    local pipe = assert(vim.uv.new_pipe())
    pipe:connect(vim.env.HERDR_SOCKET_PATH, function(err)
        if err then
            return pipe:close()
        end
        pipe:write(vim.json.encode({ id = "focus", method = "pane.focus", params = { pane_id = pane } }) .. "\n")
        pipe:read_start(function()
            if not pipe:is_closing() then
                pipe:close()
            end
        end)
    end)
end

---@param pane string
---@param text string
---@param on_success? fun()
function M.submit_prompt(pane, text, on_success) M.run({ "agent", "prompt", pane, text }, on_success) end

---@param pane string
---@param match string
---@param on_timeout fun()
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
---@field is_claude boolean
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
        is_claude = pane.agent == "claude",
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

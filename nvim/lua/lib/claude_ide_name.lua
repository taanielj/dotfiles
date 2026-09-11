-- claudecode.nvim names every nvim "Neovim" in its lock file, so /ide lists
-- them alike. The name is rewritten as the herdr workspace, tab and current
-- file.
local M = {}

local workspace_label
local tab_label
local written_path
local written_name

local function lock_path()
    local port = require("claudecode").state.port
    if not port then
        return nil
    end
    return require("claudecode.lockfile").lock_dir .. "/" .. port .. ".lock"
end

local function name()
    local parts = { "Neovim" }
    if workspace_label then
        parts[#parts + 1] = workspace_label
    end
    if tab_label then
        parts[#parts + 1] = tab_label
    end
    local file = vim.fn.expand("%:t")
    if file ~= "" then
        parts[#parts + 1] = file
    end
    return table.concat(parts, " · ")
end

-- The lock exists once the server is up; before that there is nothing to name
function M.write()
    local path = lock_path()
    if not path or vim.fn.filereadable(path) == 0 or (path == written_path and name() == written_name) then
        return
    end
    local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(path)))
    if not ok or type(lock) ~= "table" then
        return
    end
    lock.ideName = name()
    vim.fn.writefile({ vim.json.encode(lock) }, path)
    written_path, written_name = path, lock.ideName
end

---@param kind "tab"|"workspace"
---@param on_result fun(info: table?)
local function herdr_get(kind, id, on_result)
    vim.system({ require("lib.herdr").bin(), kind, "get", id }, { text = true }, function(res)
        local ok, data = pcall(vim.json.decode, res.stdout or "")
        vim.schedule(function() on_result(ok and vim.tbl_get(data, "result", kind) or nil) end)
    end)
end

local function fetch_labels()
    local tab_id = vim.env.HERDR_TAB_ID
    if not tab_id or tab_id == "" then
        return
    end
    herdr_get("tab", tab_id, function(tab_info)
        if not tab_info then
            return
        end
        tab_label = tab_info.label
        herdr_get("workspace", tab_info.workspace_id, function(workspace_info)
            workspace_label = workspace_info and workspace_info.label
            M.write()
        end)
    end)
end

-- neo-tree, a terminal or a scratch buffer keeps the last file's name
local function follow_current_file()
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("user_claude_ide_name", { clear = true }),
        callback = function(args)
            if require("lib.buffers").is_file(args.buf) then
                M.write()
            end
        end,
    })
end

function M.setup()
    fetch_labels()
    follow_current_file()
end

return M

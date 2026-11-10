-- claudecode.nvim writes the name "Neovim" into the lock file of every nvim,
-- and /ide then shows identical entries. The lock file name becomes "Neovim",
-- the herdr workspace or Herdr app space, the tab and the current file, joined with " · ".
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
    return vim.fs.joinpath(require("claudecode.lockfile").lock_dir, port .. ".lock")
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

-- The lock file exists once the server is up. Writing the name waits for the lock file.
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

local function fetch_labels()
    local host = require("lib.pane_host")()
    if not host then
        return
    end
    host.labels(function(space, tab)
        workspace_label, tab_label = space, tab
        M.write()
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
    M.write()
end

return M

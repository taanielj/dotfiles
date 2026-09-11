-- claudecode.nvim names every nvim "Neovim" in its lock file, which is all
-- /ide shows for two of them in one workspace. The name is rewritten as the
-- herdr tab and the current file, so the picker tells them apart.
local M = {}

local tab -- the herdr tab label, fetched once
local written -- the name in the lock file now

local function lock_path()
    local port = require("claudecode").state.port
    if not port then
        return nil
    end
    return require("claudecode.lockfile").lock_dir .. "/" .. port .. ".lock"
end

local function name()
    local parts = { "Neovim" }
    if tab then
        parts[#parts + 1] = tab
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
    if not path or vim.fn.filereadable(path) == 0 or name() == written then
        return
    end
    local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(path)))
    if not ok or type(lock) ~= "table" then
        return
    end
    lock.ideName = name()
    vim.fn.writefile({ vim.json.encode(lock) }, path)
    written = lock.ideName
end

function M.setup()
    local tab_id = vim.env.HERDR_TAB_ID
    if tab_id and tab_id ~= "" then
        vim.system({ require("lib.herdr").bin(), "tab", "get", tab_id }, { text = true }, function(res)
            local ok, data = pcall(vim.json.decode, res.stdout or "")
            tab = ok and vim.tbl_get(data, "result", "tab", "label") or nil
            vim.schedule(M.write)
        end)
    end
    -- Named file buffers only: neo-tree, a terminal or a scratch buffer keeps
    -- the last file's name
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("user_claude_ide_name", { clear = true }),
        callback = function()
            if vim.bo.buftype == "" and vim.fn.expand("%:t") ~= "" then
                M.write()
            end
        end,
    })
end

return M

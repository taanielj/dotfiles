-- Marksman registers no file watchers, and Neovim reports only the markdown it
-- creates itself, so notes written by anything else stay out of the index. The
-- server does honour workspace.fileOperations, hence this re-listing.

local M = {}

local DEBOUNCE_MS = 2000
local PATTERNS = { "*.md", "*.markdown" }

---@type table<integer, { known: table<string, true>, pending: boolean }>
local tracked = {}

-- Fallback for workspaces marksman rooted on something other than a repo.
local function walk(root)
    local files = {}
    for name, type in
        vim.fs.dir(root, {
            depth = 16,
            skip = function(dir)
                local base = vim.fs.basename(dir)
                return base ~= ".git" and base ~= "node_modules"
            end,
        })
    do
        if type == "file" and require("lib.markdown").is_file(name) then
            files[vim.fs.joinpath(root, name)] = true
        end
    end
    return files
end

local function list(root, done)
    local function fallback()
        vim.schedule(function()
            local ok, files = pcall(walk, root)
            done(ok and files or {})
        end)
    end

    local cmd = { "git", "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--" }
    vim.list_extend(cmd, PATTERNS)
    local spawned = pcall(vim.system, cmd, { cwd = root, text = true }, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                fallback()
                return
            end
            local files = {}
            for _, rel in ipairs(vim.split(res.stdout or "", "\0", { trimempty = true })) do
                local path = vim.fs.joinpath(root, rel)
                -- ls-files still reports files deleted from the working tree.
                if vim.uv.fs_stat(path) then
                    files[path] = true
                end
            end
            done(files)
        end)
    end)
    if not spawned then
        fallback()
    end
end

local function sync(client, now)
    local state = tracked[client.id]
    if not state or client:is_stopped() then
        return
    end

    if not now then
        if state.pending then
            return
        end
        state.pending = true
        vim.defer_fn(function()
            state.pending = false
            sync(client, true)
        end, DEBOUNCE_MS)
        return
    end

    list(client.root_dir, function(found)
        if client:is_stopped() then
            return
        end
        local created, deleted = {}, {}
        for path in pairs(found) do
            if not state.known[path] then
                created[#created + 1] = { uri = vim.uri_from_fname(path) }
            end
        end
        for path in pairs(state.known) do
            if not found[path] then
                deleted[#deleted + 1] = { uri = vim.uri_from_fname(path) }
            end
        end
        state.known = found
        if #created > 0 then
            client:notify("workspace/didCreateFiles", { files = created })
        end
        if #deleted > 0 then
            client:notify("workspace/didDeleteFiles", { files = deleted })
        end
    end)
end

---@param client vim.lsp.Client the attached marksman client
function M.attach(client)
    if tracked[client.id] or not client.root_dir then
        return
    end
    local state = { known = {}, pending = false }
    tracked[client.id] = state
    -- Baseline: what marksman itself just indexed.
    list(client.root_dir, function(found) state.known = found end)

    local group = vim.api.nvim_create_augroup("user_marksman_sync_" .. client.id, { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "CursorHold", "FocusGained" }, {
        group = group,
        pattern = PATTERNS,
        desc = "Tell marksman about markdown files written outside Neovim",
        callback = function() sync(client) end,
    })
    vim.api.nvim_create_autocmd("LspDetach", {
        group = group,
        callback = function(event)
            if event.data.client_id ~= client.id then
                return
            end
            -- LspDetach fires per buffer, with the leaving buffer still attached
            if vim.tbl_count(client.attached_buffers) <= 1 then
                tracked[client.id] = nil
                vim.schedule(function() pcall(vim.api.nvim_del_augroup_by_id, group) end)
            end
        end,
    })
end

vim.api.nvim_create_user_command("MarksmanSync", function()
    for id, state in pairs(tracked) do
        local client = vim.lsp.get_client_by_id(id)
        if client then
            state.known = {}
            sync(client, true)
        end
    end
end, { desc = "Re-announce every markdown file to marksman" })

return M

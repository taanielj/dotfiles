-- Claude Code's Edit and Write tools write the file on disk, which may be open
-- here with unsaved changes. Its hooks call in over RPC: before the write, so
-- the change on disk is expected rather than a conflict; after it, to reload
-- the buffer with the unsaved changes put back. The reload keeps nvim's
-- "changed since reading" warning for real conflicts.
local M = {}

-- a permission prompt can sit between the two hooks
local EXPECT_MS = 60000

---@type table<integer, integer> buffer -> vim.uv.now() deadline
local expected = {}

---@param path string
---@return string?
local function read(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("a")
    file:close()
    return content
end

---@param path string
---@return integer[]
local function buffers_for(path)
    local real = vim.uv.fs_realpath(path) or path
    return vim.tbl_filter(function(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        return vim.api.nvim_buf_is_loaded(buf)
            and require("lib.buffers").is_file(buf)
            and (vim.uv.fs_realpath(name) or name) == real
    end, vim.api.nvim_list_bufs())
end

---@return string? nil when old is missing, or repeated without replace_all
local function edit_tool_replace(text, old, new, all)
    if old == "" then
        return nil
    end
    local parts, from = {}, 1
    while true do
        local start = text:find(old, from, true)
        if not start then
            break
        end
        parts[#parts + 1] = text:sub(from, start - 1) .. new
        from = start + #old
    end
    if #parts == 0 or (#parts > 1 and not all) then
        return nil
    end
    parts[#parts + 1] = text:sub(from)
    return table.concat(parts)
end

---@param text string
---@return string[]
local function split(text) return vim.split(text:gsub("\n$", ""), "\n", { plain = true }) end

---@param lines string[]
---@param edits { old_string: string, new_string: string, replace_all: boolean? }[]
---@return string[]? nil when an edit does not apply
local function merged(lines, edits)
    -- with the final newline an edit can match through the last line
    local text = table.concat(lines, "\n") .. "\n"
    for _, edit in ipairs(edits) do
        text = edit_tool_replace(text, edit.old_string, edit.new_string, edit.replace_all)
        if not text then
            return nil
        end
    end
    return split(text)
end

---@param old string[]
---@param new string[]
---@return integer[][] { old_start, old_count, new_start, new_count } per changed block
local function hunks(old, new)
    return vim.text.diff(table.concat(old, "\n") .. "\n", table.concat(new, "\n") .. "\n", {
        result_type = "indices",
    }) --[[@as integer[][] ]]
end

-- Only changed lines are replaced, so marks on the rest stay put
---@param buf integer
---@param lines string[]
local function set_lines(buf, lines)
    local changes = hunks(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines)
    for i = #changes, 1, -1 do
        local old_start, old_count, new_start, new_count = unpack(changes[i])
        local first = old_count == 0 and old_start or old_start - 1
        local replacement = vim.list_slice(lines, new_start, new_start + new_count - 1)
        vim.api.nvim_buf_set_lines(buf, first, first + old_count, false, replacement)
    end
end

---@param row integer a line before the change
---@param changes integer[][] from hunks()
---@return integer the line its text moved to
local function follow(row, changes)
    local shift = 0
    for _, change in ipairs(changes) do
        local old_start, old_count, new_start, new_count = unpack(change)
        if old_count == 0 then
            shift = shift + (row > old_start and new_count or 0)
        elseif row >= old_start + old_count then
            shift = shift + new_count - old_count
        elseif row >= old_start then
            return new_start + math.min(row - old_start, math.max(new_count - 1, 0))
        end
    end
    return row + shift
end

-- The reload puts every cursor back where it was by line number, not by text
---@param buf integer
---@param changes integer[][] from hunks()
---@return table<integer, vim.fn.winsaveview.ret> window -> its view after the change
local function followed_views(buf, changes)
    local views = {}
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
        view.lnum, view.topline = follow(view.lnum, changes), follow(view.topline, changes)
        views[win] = view
    end
    return views
end

---@param buf integer
---@param path string
---@param tool string
---@param input table the tool's input
local function sync(buf, path, tool, input)
    expected[buf] = nil
    local content = read(path)
    if not content then
        return
    end
    if vim.bo[buf].fileformat == "dos" then
        content = content:gsub("\r\n", "\n")
    end
    local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local unsaved_with_edit
    if tool ~= "Write" and vim.bo[buf].modified then
        unsaved_with_edit = merged(before, input.edits or { input })
        if not unsaved_with_edit then
            -- left as it is, the buffer gets nvim's warning when saved
            vim.notify(
                ("Claude's edit to %s clashes with unsaved changes; :e! loads its version"):format(
                    vim.fn.fnamemodify(path, ":~:.")
                ),
                vim.log.levels.WARN
            )
            return
        end
    end

    local views = followed_views(buf, hunks(before, unsaved_with_edit or split(content)))
    vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent edit!")
        if unsaved_with_edit then
            -- one undo step takes back the edit
            pcall(vim.cmd.undojoin)
            set_lines(buf, unsaved_with_edit)
        end
    end)
    for win, view in pairs(views) do
        vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
    end
end

---Entry point for the Claude Code hook: PreToolUse and PostToolUse on Edit, MultiEdit and Write.
---@param input_path string the hook's JSON input, saved to a file
function M.hook(input_path)
    local ok, input = pcall(vim.json.decode, read(input_path) or "")
    local path = ok and vim.tbl_get(input, "tool_input", "file_path")
    if not path then
        return
    end
    for _, buf in ipairs(buffers_for(path)) do
        if input.hook_event_name == "PreToolUse" then
            expected[buf] = vim.uv.now() + EXPECT_MS
        else
            sync(buf, path, input.tool_name, input.tool_input)
        end
    end
end

-- Registered on load, which the first hook call does, so an nvim started
-- before this module existed takes edits too
vim.api.nvim_create_autocmd("FileChangedShell", {
    group = vim.api.nvim_create_augroup("user_agent_edits", { clear = true }),
    callback = function(args)
        local deadline = expected[args.buf]
        vim.v.fcs_choice = (deadline and vim.uv.now() < deadline) and "" or "ask"
    end,
})

return M

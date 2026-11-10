-- Stages and unstages hunks inside a diffview. The index buffer is writable,
-- and writing it updates the index. Moving a hunk into the index buffer with dp
-- or do and writing it stages or unstages the hunk.
local M = {}

local function current_view() return require("diffview.lib").get_current_view() end

local function is_index(file) return file.rev.type == require("diffview.vcs.rev").RevType.STAGE end

local function view_file(view, bufnr)
    for _, win in ipairs(view.cur_layout.windows) do
        if win.file and win.file.bufnr == bufnr then
            return win.file
        end
    end
end

local function write_index_buffers(view)
    for _, win in ipairs(view.cur_layout.windows) do
        local file = win.file
        if file and file.bufnr and is_index(file) and vim.bo[file.bufnr].modified then
            vim.api.nvim_buf_call(file.bufnr, function() vim.cmd.write() end)
        end
    end
end

---@param cmd "diffput" | "diffget"
function M.hunk_to_index(cmd)
    return function()
        local view = current_view()
        if not view then
            return
        end
        local range = ""
        if vim.fn.mode():match("^[vV]") then
            local first, last = require("lib.yank").line_range()
            range = first .. "," .. last
            vim.cmd("normal! \27")
        end
        vim.cmd(("silent! %s%s"):format(range, cmd))
        write_index_buffers(view)
    end
end

function M.stage_hunk()
    local view = current_view()
    if not view then
        return
    end
    local file = view_file(view, vim.api.nvim_get_current_buf())
    M.hunk_to_index(file and is_index(file) and "diffget" or "diffput")()
end

local function set_file_staged(staged)
    return function()
        local view = current_view()
        local item = view and view.infer_cur_file and view:infer_cur_file()
        if not item then
            return
        end
        if (item.kind == "staged") == staged then
            vim.notify(staged and "Already staged" or "Not staged", vim.log.levels.INFO)
            return
        end
        require("diffview.actions").toggle_stage_entry()
    end
end

M.stage_file = set_file_staged(true)
M.unstage_file = set_file_staged(false)

-- gitsigns attaches only to buffers backed by a file on disk, and its <leader>g
-- keys are missing on the index and HEAD sides. These maps replace them there.
function M.map_keys(bufnr)
    local map = require("lib.keymap").buffer(bufnr)
    map({ "n", "x" }, "<leader>gs", M.stage_hunk, "Stage/unstage hunk")
    map("n", "<leader>gS", M.stage_file, "Stage buffer")
    map("n", "<leader>gu", M.unstage_file, "Unstage buffer")
end

return M

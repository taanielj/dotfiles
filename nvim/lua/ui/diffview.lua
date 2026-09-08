local git = require("git")

local M = {}

-- Reads package.loaded so asking never loads the plugin
function M.is_open()
    local lib = package.loaded["diffview.lib"]
    return lib ~= nil and lib.get_current_view() ~= nil
end

function M.close()
    vim.cmd.DiffviewClose()
end

local function toggle(open)
    return function()
        if M.is_open() then
            M.close()
        else
            open()
        end
    end
end

---The ref a branch is measured against: the default branch, or the upstream
---when already on it. Notifies and returns nil when there is neither.
---@return string?
function M.base()
    local default = git.default_branch()
    if default and default:gsub("^origin/", "") ~= git.head() then
        return default
    end
    local upstream = git.upstream()
    if upstream ~= "" then
        return upstream
    end
    vim.notify("No default branch or upstream to compare against", vim.log.levels.WARN)
end

M.uncommitted = toggle(function()
    if not git.is_dirty() then
        vim.notify("Working tree is clean", vim.log.levels.INFO)
        return
    end
    vim.cmd.DiffviewOpen()
end)

-- Three dots: only what the branch added since it left its base
M.branch = toggle(function()
    local base = M.base()
    if base then
        vim.cmd.DiffviewOpen(base .. "...HEAD")
    end
end)

M.branch_log = toggle(function()
    local base = M.base()
    if base then
        vim.cmd.DiffviewFileHistory({ args = { "--range=" .. base .. "...HEAD" } })
    end
end)

M.file_log = toggle(function()
    vim.cmd.DiffviewFileHistory("%")
end)

M.pick_branch = toggle(function()
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    require("telescope.builtin").git_branches({
        prompt_title = "Diff against branch",
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local branch = state.get_selected_entry().value
                actions.close(prompt_bufnr)
                vim.cmd.DiffviewOpen(branch)
            end)
            return true
        end,
    })
end)

local function commit_entry_maker()
    local displayer = require("telescope.pickers.entry_display").create({
        separator = " ",
        items = { { width = 16 }, { width = 8 }, { remaining = true } },
    })
    return function(line)
        local hash, date, msg = line:match("^(%x+)\t([^\t]+)\t(.*)$")
        if not hash then
            return nil
        end
        return {
            value = hash,
            ordinal = date .. " " .. hash .. " " .. msg,
            display = function()
                return displayer({
                    { date, "TelescopeResultsComment" },
                    { hash, "TelescopeResultsIdentifier" },
                    msg,
                })
            end,
        }
    end
end

-- One commit picked in telescope opens it and everything after it against the
-- working tree; two picked (Tab) open the range between them, either order.
M.pick_commits = toggle(function()
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    require("telescope.builtin").git_commits({
        prompt_title = "Diff from commit (Tab selects two)",
        git_command = { "git", "log", "--pretty=%h%x09%ad%x09%s", "--date=format:%Y-%m-%d %H:%M", "--", "." },
        entry_maker = commit_entry_maker(),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local picked = state.get_current_picker(prompt_bufnr):get_multi_selection()
                if #picked == 0 then
                    picked = { state.get_selected_entry() }
                end
                actions.close(prompt_bufnr)
                local from, to = picked[1].value, "HEAD"
                if picked[2] then
                    to = picked[2].value
                    if git.is_ancestor(to, from) then
                        from, to = to, from
                    end
                end
                vim.cmd.DiffviewOpen(from .. "^.." .. to)
            end)
            return true
        end,
    })
end)

-- Directory rows and multi-file log entries fold instead of opening
local function opens_file(view, item)
    if not item then
        return false
    end
    if item.files then
        return view.panel.single_file
    end
    return type(item.collapsed) ~= "boolean"
end

-- gg]c[c lands on the first change whether or not it starts on line 1;
-- a failing ]c or [c leaves the cursor where it should be.
local function jump_to_first_change(view)
    local win = view.cur_layout:get_main_win().id
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, function()
            vim.cmd("silent! normal! gg]c[c")
        end)
    end
end

function M.focus_first_change()
    local view = require("diffview.lib").get_current_view()
    if view and opens_file(view, view.panel:get_item_at_cursor()) then
        view.emitter:once("file_open_post", function()
            vim.schedule(function()
                jump_to_first_change(view)
            end)
        end)
    end
    require("diffview.actions").focus_entry()
end

-- Snapshot per view, so closing drops only the files the view pulled in
local listed_before = {}

local function listed()
    local set = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted then
            set[buf] = true
        end
    end
    return set
end

M.hooks = {
    view_opened = function(view)
        listed_before[view.tabpage] = listed()
    end,
    view_closed = function(view)
        local before = listed_before[view.tabpage] or {}
        listed_before[view.tabpage] = nil
        for buf in pairs(listed()) do
            if not before[buf] and not vim.bo[buf].modified and #vim.fn.win_findbuf(buf) == 0 then
                vim.api.nvim_buf_delete(buf, {})
            end
        end
    end,
}

return M

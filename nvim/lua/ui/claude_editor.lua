-- Claude Code's external editor, run by the nvim in the same herdr tab or Herdr
-- app tab as Claude. herdr/bin/herdr-nvim.sh, the wrapper Claude runs as its
-- editor, calls `edit` for ctrl+g and `view` for ctrl+o v through this nvim's
-- server socket. ctrl+g opens the repo's prompt draft, .scratch/prompt.md.
-- <C-s> in the draft submits it to Claude without a ctrl+g.
local host = require("lib.pane_host")

local M = {}

local HEIGHT = 12

---@class ui.claude_editor.PendingEdit
---@field prompt_file string Claude reads it back once the wrapper exits
---@field done_fifo string
---@field claude_pane string
---@field original_draft string[]

---@type ui.claude_editor.PendingEdit?
local waiting

---@param flag string buffer variable that marks the buffer
---@return integer? the window in this tabpage showing it
local function window(flag)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.b[vim.api.nvim_win_get_buf(win)][flag] then
            return win
        end
    end
    return nil
end

---@param buf integer
---@param flag string
local function show_in_bottom_split(buf, flag)
    local win = window(flag)
    if not win then
        vim.cmd(("botright %dsplit"):format(HEIGHT))
        win = vim.api.nvim_get_current_win()
        vim.wo[win].winfixheight = true
    end
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)
end

---@param flag string
local function hide(flag)
    local win = window(flag)
    if win then
        -- nvim_win_close errors on a tabpage's last window
        pcall(vim.api.nvim_win_close, win, false)
    end
end

---@param fifo string
local function wake(fifo)
    local c = vim.uv.constants
    -- A blocking open hangs nvim when the wrapper already exited and left no reader
    local fd = vim.uv.fs_open(fifo, bit.bor(c.O_WRONLY, c.O_NONBLOCK), 0)
    if fd then
        vim.uv.fs_write(fd, "\n")
        vim.uv.fs_close(fd)
    end
end

---@return integer
local function load_draft()
    local cwd = vim.fn.getcwd()
    local path = vim.fs.joinpath(vim.fs.root(cwd, ".git") or cwd, ".scratch", "prompt.md")
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    return buf
end

---@param buf integer
---@return string[]
local function lines(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end

---@param text string[]
local function blank(text) return vim.trim(table.concat(text, "\n")) == "" end

---@param buf integer
---@param text string[]
local function set_draft(buf, text)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent update") end)
end

---Ends the edit Claude is waiting on and focuses Claude.
---@param text string[]? what Claude's box gets; nil leaves the box as it was
---@return ui.claude_editor.PendingEdit?
local function release(text)
    local edit = waiting
    waiting = nil
    if not edit then
        return nil
    end
    if text then
        vim.fn.writefile(text, edit.prompt_file)
    end
    wake(edit.done_fifo)
    host().focus(edit.claude_pane)
    return edit
end

---@param buf integer
---@return ui.claude_editor.PendingEdit?
local function hand_back(buf)
    local text = lines(buf)
    set_draft(buf, {})
    local edit = release(text)
    hide("claude_draft")
    return edit
end

---@param buf integer
local function close(buf)
    if waiting then
        set_draft(buf, waiting.original_draft)
        release(nil)
    end
    hide("claude_draft")
end

---An Enter sent while Claude is still redrawing is lost.
---@param pane string
---@param text string[]
local function enter_when_shown(pane, text)
    local first = ""
    for _, line in ipairs(text) do
        if vim.trim(line) ~= "" then
            first = vim.trim(line):sub(1, 30)
            break
        end
    end
    host().enter_when_shown(
        pane,
        first,
        function() vim.notify("Claude didn't show the prompt; press Enter there", vim.log.levels.WARN) end
    )
end

---@param buf integer
local function submit(buf)
    local text = lines(buf)
    if blank(text) then
        vim.notify("The prompt draft is empty", vim.log.levels.WARN)
        return
    end
    if waiting then
        -- Until the wrapper exits, a paste into Claude's terminal goes to the
        -- wrapper. The text goes back through Claude's prompt file instead.
        local edit = hand_back(buf)
        enter_when_shown(edit.claude_pane, text)
        return
    end
    require("lib.claude_pane").pick(function(pane)
        host().submit_prompt(pane, table.concat(text, "\n"), function() set_draft(buf, {}) end)
    end)
end

---Sets up a draft buffer opened by this module, `:edit` or a restored session.
---@param buf integer
function M.attach(buf)
    vim.b[buf].claude_draft = true
    vim.bo[buf].buflisted = false
    local map = require("lib.keymap").buffer(buf, "Prompt draft: ")
    map("n", "ZZ", function()
        if waiting then
            hand_back(buf)
        else
            hide("claude_draft")
        end
    end, "hand back to Claude / close")
    map("n", "ZQ", function() close(buf) end, "cancel / close")
    map({ "n", "i" }, "<C-s>", function()
        vim.cmd.stopinsert()
        submit(buf)
    end, "submit to Claude")

    local group = vim.api.nvim_create_augroup("user_claude_draft_" .. buf, { clear = true })
    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufLeave" }, {
        group = group,
        buffer = buf,
        callback = function()
            vim.api.nvim_buf_call(buf, function() vim.cmd("silent update") end)
        end,
    })
    -- Closing the split other than by ZZ or ZQ cancels, keeping the edits
    vim.api.nvim_create_autocmd("BufWinLeave", {
        group = group,
        buffer = buf,
        callback = function() release(nil) end,
    })
end

function M.toggle()
    if window("claude_draft") then
        hide("claude_draft")
    else
        show_in_bottom_split(load_draft(), "claude_draft")
    end
end

---Opens the draft for ctrl+g with the text of Claude's prompt box appended.
---Claude waits until ZZ or ZQ in the draft.
---@param prompt_file string
---@param done_fifo string
---@param claude_pane string
---@return integer 1, which tells the wrapper that nvim took the file
function M.edit(prompt_file, done_fifo, claude_pane)
    -- Cancel the edit another Claude in this tab may still be waiting on
    release(nil)
    local buf = load_draft()
    local before = lines(buf)
    local box = vim.fn.readfile(prompt_file)
    if not blank(box) then
        set_draft(buf, blank(before) and box or vim.list_extend(vim.list_extend(vim.deepcopy(before), { "" }), box))
    end
    waiting = { prompt_file = prompt_file, done_fifo = done_fifo, claude_pane = claude_pane, original_draft = before }
    show_in_bottom_split(buf, "claude_draft")
    host().focus(assert(host().pane_id()))
    return 1
end

---Shows the transcript for ctrl+o v, read-only, in its own split. Claude
---doesn't wait for the split to close. Another ctrl+o v replaces the split's
---transcript with a fresh copy.
---@param path string
---@return integer 1, which tells the wrapper that nvim took the file
function M.view(path)
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    vim.b[buf].claude_transcript = true
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    local map = require("lib.keymap").buffer(buf, "Transcript: ")
    for _, key in ipairs({ "ZZ", "ZQ" }) do
        map("n", key, function() hide("claude_transcript") end, "close")
    end
    show_in_bottom_split(buf, "claude_transcript")
    vim.cmd("normal! G")
    host().focus(assert(host().pane_id()))
    return 1
end

return M

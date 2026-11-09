-- Claude Code's external editor, served by the nvim in Claude's herdr tab:
-- herdr/bin/herdr-nvim.sh calls `edit` for ctrl+g and `view` for ctrl+o v
-- through this nvim's server socket. ctrl+g lands in the repo's prompt draft,
-- .scratch/prompt.md, which also submits to Claude on its own.
local herdr = require("lib.herdr")

local M = {}

local HEIGHT = 12

---A ctrl+g edit Claude is waiting on.
---@class ui.claude_editor.Edit
---@field path string Claude's prompt file, read back once the wrapper exits
---@field done string the fifo the wrapper waits on
---@field claude string Claude's herdr pane
---@field before string[] the draft before Claude's text was joined in

---@type ui.claude_editor.Edit?
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

---Shows the buffer in its bottom split, made on first use, and focuses it.
---@param buf integer
---@param flag string
local function show(buf, flag)
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
        -- The last window of a tabpage stays
        pcall(vim.api.nvim_win_close, win, false)
    end
end

---Wakes the wrapper waiting on `fifo`. A wrapper already gone leaves no
---reader, and the non-blocking open fails instead of hanging nvim.
---@param fifo string
local function wake(fifo)
    local c = vim.uv.constants
    local fd = vim.uv.fs_open(fifo, bit.bor(c.O_WRONLY, c.O_NONBLOCK), 0)
    if fd then
        vim.uv.fs_write(fd, "\n")
        vim.uv.fs_close(fd)
    end
end

---@return integer the draft buffer, loaded
local function draft()
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
---@return ui.claude_editor.Edit?
local function release(text)
    local edit = waiting
    waiting = nil
    if not edit then
        return nil
    end
    if text then
        vim.fn.writefile(text, edit.path)
    end
    wake(edit.done)
    herdr.focus(edit.claude)
    return edit
end

---@param buf integer
---@return ui.claude_editor.Edit?
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
        set_draft(buf, waiting.before)
        release(nil)
    end
    hide("claude_draft")
end

---Presses Enter in Claude once its box shows the handed-back text; an Enter
---sent while Claude is still redrawing is lost.
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
    local wait =
        { herdr.bin(), "pane", "wait-output", pane, "--source", "visible", "--match", first, "--timeout", "3000" }
    vim.system(
        wait,
        { text = true },
        vim.schedule_wrap(function(res)
            if res.code == 0 then
                herdr.run({ "pane", "send-keys", pane, "enter" })
            else
                vim.notify("Claude didn't show the prompt; press Enter there", vim.log.levels.WARN)
            end
        end)
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
        -- A paste would miss Claude's box: its terminal belongs to the
        -- wrapper until the wrapper exits
        local edit = hand_back(buf)
        enter_when_shown(edit.claude, text)
        return
    end
    require("lib.claude_pane").pick(function(pane)
        herdr.run({ "agent", "prompt", pane, table.concat(text, "\n") }, function() set_draft(buf, {}) end)
    end)
end

---Sets up a draft buffer however it was opened: by this module, `:edit`, or
---a restored session.
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

---Toggles the prompt draft's split.
function M.toggle()
    if window("claude_draft") then
        hide("claude_draft")
    else
        show(draft(), "claude_draft")
    end
end

---ctrl+g: Claude's box text joins the draft, and Claude waits for ZZ or ZQ.
---@param path string Claude's prompt file
---@param done string the fifo the wrapper waits on
---@param claude string Claude's herdr pane
---@return integer 1, which the wrapper takes as nvim having it
function M.edit(path, done, claude)
    -- Another Claude in the tab still waiting gives way
    release(nil)
    local buf = draft()
    local before = lines(buf)
    local box = vim.fn.readfile(path)
    if not blank(box) then
        set_draft(buf, blank(before) and box or vim.list_extend(vim.list_extend(vim.deepcopy(before), { "" }), box))
    end
    waiting = { path = path, done = done, claude = claude, before = before }
    show(buf, "claude_draft")
    herdr.focus(assert(herdr.pane_id()))
    return 1
end

---ctrl+o v: the transcript, read-only, in its own split. Claude doesn't wait;
---pressing v again replaces it with a fresh one.
---@param path string
---@return integer 1, which the wrapper takes as nvim having it
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
    show(buf, "claude_transcript")
    vim.cmd("normal! G")
    herdr.focus(assert(herdr.pane_id()))
    return 1
end

return M

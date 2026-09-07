-- Yank Markdown as the HTML that Scoro's description fields want.
--
-- Scoro renders HTML, so Markdown pasted in shows its backticks, ** and fences
-- literally. python-markdown does the conversion and uvx fetches it per run, so
-- there is nothing to install into a project or a global Python.
--
-- Extensions match what the notes actually use:
--   fenced_code  ``` blocks become <pre><code>; plain markdown collapses them to <p>
--   tables       pipe tables become <table>
--   sane_lists   a stray "1." mid-paragraph stays prose
--
-- nl2br stays off: it puts a <br /> at every newline, freezing hard-wrapped
-- prose into mid-sentence breaks that Scoro's editor then keeps. Two trailing
-- spaces still give a hard break where one is wanted.

local M = {}

local INSTALL_URL = "https://docs.astral.sh/uv/getting-started/installation/"

local CMD = {
    "uvx", "--quiet", "--from", "markdown", "markdown_py",
    "-x", "fenced_code",
    "-x", "tables",
    "-x", "sane_lists",
}

-- python-markdown nests a list only when the child is indented a full four
-- spaces; at two or three it emits a sibling, silently flattening the structure.
-- The notes nest at two and three throughout, so rewrite the indentation to four
-- per level first. A stack of the open levels' source indents keeps this
-- independent of the width any one file happens to use.

local function width(ws)
    local n = 0
    for c in ws:gmatch(".") do
        n = c == "\t" and n + 4 or n + 1
    end
    return n
end

local function shift(line, delta)
    if delta == 0 or line:match("^%s*$") then
        return line
    end
    local ws, rest = line:match("^([ \t]*)(.*)$")
    return string.rep(" ", math.max(0, width(ws) + delta)) .. rest
end

-- A line carrying no marker of its own -- wrapped prose, an indented fence --
-- moves with the deepest open level it still clears, which keeps it inside the
-- item it belongs to instead of the one that happens to precede it.
local function delta_for(stack, indent)
    local level = 0
    while level < #stack and stack[level + 1] <= indent do
        level = level + 1
    end
    if level == 0 then
        return 0
    end
    return (level - 1) * 4 - stack[level]
end

local function reindent(lines)
    local out, stack = {}, {}
    local fence, fence_delta = nil, 0

    for _, line in ipairs(lines) do
        local marks = line:match("^[ \t]*([`~][`~][`~]+)")
        if fence then
            if marks and marks:sub(1, 1) == fence:sub(1, 1) and #marks >= #fence then
                fence = nil
            end
            out[#out + 1] = shift(line, fence_delta)
        elseif line:match("^%s*$") then
            out[#out + 1] = line
        else
            local ws, marker, rest = line:match("^([ \t]*)([-+*])(%s.*)$")
            if not marker then
                ws, marker, rest = line:match("^([ \t]*)(%d+[%.%)])(%s.*)$")
            end
            if marker then
                local indent = width(ws)
                while #stack > 0 and indent < stack[#stack] do
                    table.remove(stack)
                end
                if #stack == 0 or indent > stack[#stack] then
                    stack[#stack + 1] = indent
                end
                out[#out + 1] = string.rep(" ", (#stack - 1) * 4) .. marker .. rest
            else
                local indent = width(line:match("^[ \t]*"))
                if indent == 0 then
                    stack = {} -- back at column 0: the list is over
                end
                local delta = delta_for(stack, indent)
                if marks then
                    fence, fence_delta = marks, delta
                end
                out[#out + 1] = shift(line, delta)
            end
        end
    end
    return out
end

local function notify(msg, level)
    vim.notify(msg, level, { title = "md2html" })
end

--- Convert lines to HTML and put the result on the + register.
--- @param first integer|nil 1-indexed first line; nil converts the whole buffer
--- @param last integer|nil 1-indexed last line
function M.yank(first, last)
    if vim.fn.executable("uvx") == 0 then
        notify("uvx not found - install uv: " .. INSTALL_URL, vim.log.levels.ERROR)
        return
    end

    local lines = vim.api.nvim_buf_get_lines(0, first and first - 1 or 0, last or -1, false)
    local markdown = table.concat(reindent(lines), "\n")
    if vim.trim(markdown) == "" then
        notify("nothing to convert", vim.log.levels.WARN)
        return
    end

    vim.system(CMD, { stdin = markdown .. "\n", text = true }, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                local err = vim.trim(res.stderr or "")
                notify(err ~= "" and err or ("markdown_py exited " .. res.code), vim.log.levels.ERROR)
                return
            end
            vim.fn.setreg("+", vim.trim(res.stdout or ""))
            notify(("%d lines as HTML"):format(#lines), vim.log.levels.INFO)
        end)
    end)
end

-- '< and '> still hold the previous selection while visual mode is active.
local function selection()
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
        first, last = last, first
    end
    return first, last
end

vim.keymap.set("n", "<leader>yh", function()
    M.yank()
end, { noremap = true, silent = true, desc = "Yank buffer as HTML" })

vim.keymap.set("v", "<leader>yh", function()
    M.yank(selection())
end, { noremap = true, silent = true, desc = "Yank selection as HTML" })

vim.api.nvim_create_user_command("Md2Html", function(cmd)
    if cmd.range == 0 then
        M.yank()
    else
        M.yank(cmd.line1, cmd.line2)
    end
end, { range = true, desc = "Yank buffer or range as HTML" })

return M

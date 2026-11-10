-- Converts Markdown to HTML on the + register for Scoro's description fields,
-- which render HTML and show pasted Markdown's backticks, ** and fences
-- literally.

local M = {}

local INSTALL_URL = "https://docs.astral.sh/uv/getting-started/installation/"

-- Hard-wrapped prose keeps its newlines. A <br /> at every newline would break
-- sentences mid-way, and Scoro's editor keeps those breaks.
local CMD = {
    "uvx",
    "--quiet",
    "--from",
    "markdown",
    "markdown_py",
    "-x",
    "fenced_code",
    "-x",
    "tables",
    "-x",
    "sane_lists",
}

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

-- A line with no marker of its own takes the shift of the deepest open list level whose indent is at most the line's indent.
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

-- python-markdown reads a child indented less than four spaces as a sibling and
-- flattens the nesting
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
                    stack = {} -- a line at column 0 ends the list
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

local function notify(msg, level) vim.notify(msg, level, { title = "md2html" }) end

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

vim.api.nvim_create_user_command("Md2Html", function(cmd)
    if cmd.range == 0 then
        M.yank()
    else
        M.yank(cmd.line1, cmd.line2)
    end
end, { range = true, desc = "Yank buffer or range as HTML" })

return M

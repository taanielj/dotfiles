-- gitsigns' blame panel is scrollbound to the file, one line per line, so a
-- commit's summary cannot wrap. It is spread over the block's bar-only lines
-- instead, which one-line blocks do not have.
local M = {}

local ns = vim.api.nvim_create_namespace("user_blame_summary")

local function blame_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "gitsigns-blame" then
            return win
        end
    end
end

local function wrap(text, width)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        if line == "" then
            line = word
        elseif vim.fn.strdisplaywidth(line .. " " .. word) <= width then
            line = line .. " " .. word
        else
            lines[#lines + 1] = line
            line = word
        end
    end
    if line ~= "" then
        lines[#lines + 1] = line
    end
    return lines
end

-- Lua character classes are byte-wise, so the glyphs are matched whole.
local function continues_block(line)
    return vim.startswith(line, "│") or vim.startswith(line, "┕")
end

local function summary_of(line)
    return line:match("^│ (.+)$") or line:match("^┕ (.+)$")
end

-- A block is a header line followed by lines that start with a bar glyph;
-- gitsigns puts the summary on the first of those.
local function blocks(lines)
    local result = {}
    local i = 1
    while i <= #lines do
        local last = i
        while lines[last + 1] and continues_block(lines[last + 1]) do
            last = last + 1
        end
        local summary = lines[i + 1] and summary_of(lines[i + 1])
        if summary and last > i + 1 then
            result[#result + 1] = { first = i + 1, last = last, summary = summary }
        end
        i = last + 1
    end
    return result
end

local function spread_summaries(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local width = vim.api.nvim_win_get_width(win) - 2
    vim.bo[buf].modifiable = true
    for _, block in ipairs(blocks(lines)) do
        local pieces = wrap(block.summary, width)
        for row = block.first, block.last do
            local glyph = lines[row]:match("^[%z\1-\127\194-\244][\128-\191]*")
            local piece = pieces[row - block.first + 1]
            vim.api.nvim_buf_set_text(buf, row - 1, #glyph, row - 1, -1, { piece and (" " .. piece) or "" })
            if piece then
                vim.api.nvim_buf_set_extmark(buf, ns, row - 1, #glyph + 1, { end_col = #glyph + 1 + #piece, hl_group = "Comment" })
            end
        end
    end
    vim.bo[buf].modifiable = false
end

function M.toggle_column()
    local open = blame_window()
    if open then
        vim.api.nvim_win_close(open, true)
        return
    end
    local win = vim.api.nvim_get_current_win()
    require("gitsigns").blame(nil, function()
        local blame = blame_window()
        if blame then
            spread_summaries(blame)
        end
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
        end
    end)
end

return M

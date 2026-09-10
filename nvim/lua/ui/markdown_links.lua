-- Marksman resolves the target where it is attached, so anchors and
-- [[wiki links]] land on the right heading.
local M = {}

local INLINE = "%[([^%]]*)%]%(([^)]+)%)"
local DEFINITION = "^%s*%[([^%]]+)%]:%s*<?([^%s>]+)"

---@return { row: integer, label: string, target: string }[]
local function definitions()
    local defs = {}
    for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        local label, target = line:match(DEFINITION)
        if label then
            table.insert(defs, { row = row, label = label, target = target })
        end
    end
    return defs
end

-- Labels match case-insensitively
local function definition(label)
    for _, def in ipairs(definitions()) do
        if def.label:lower() == label:lower() then
            return def.target
        end
    end
    return nil
end

---@return { s: integer, e: integer, text: string, target: string }[]
local function inline_links(line)
    local links = {}
    local from = 1
    while true do
        local s, e, text, target = line:find(INLINE, from)
        if not s then
            return links
        end
        table.insert(links, { s = s, e = e, text = text, target = target })
        from = e + 1
    end
end

local function captures_under_cursor(line, col, pattern)
    local from = 1
    while true do
        local s, e, first, second = line:find(pattern, from)
        if not s then
            return nil
        end
        if col >= s and col <= e then
            return first, second
        end
        from = e + 1
    end
end

-- Inline [text](target), then reference [text][label], [text][] and [text]
local function target_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local _, inline_target = captures_under_cursor(line, col, INLINE)
    if inline_target then
        return inline_target
    end
    local text, label = captures_under_cursor(line, col, "%[([^%]]*)%]%[([^%]]*)%]")
    if not text then
        text = captures_under_cursor(line, col, "%[([^%]]+)%]")
    end
    if not text then
        return nil
    end
    return definition(label ~= nil and label ~= "" and label or text)
end

function M.follow()
    local target = target_under_cursor() or vim.fn.expand("<cfile>")
    if target == "" then
        return
    end
    if target:match("^%a[%w+.-]*:") then -- http:, https:, mailto:
        return vim.ui.open(target)
    end

    local path = vim.uri_decode((target:gsub("#.*$", "")))
    if path ~= "" then
        path = vim.fs.normalize(path:sub(1, 1) == "/" and path or vim.fs.joinpath(vim.fn.expand("%:p:h"), path))
    end

    if path == "" or require("lib.markdown").is_file(path) then
        if next(vim.lsp.get_clients({ bufnr = 0, name = "marksman" })) then
            return vim.lsp.buf.definition()
        end
        if vim.uv.fs_stat(path) then
            return vim.cmd.edit(vim.fn.fnameescape(path))
        end
    elseif vim.uv.fs_stat(path) then
        return vim.ui.open(path)
    end
    vim.notify("No such file: " .. path, vim.log.levels.WARN)
end

-- A target already defined keeps its label; a new one takes the lowest free number
local function label_for(link, defs)
    local taken = {}
    for _, def in ipairs(defs) do
        if def.target == link.target then
            return def.label, true
        end
        taken[def.label:lower()] = true
    end
    local n = 1
    while taken[tostring(n)] do
        n = n + 1
    end
    return tostring(n), false
end

-- Definitions go at the end of the file, joined to a definition block
-- already there and set off by a blank line otherwise
local function define(label, target)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local last = #lines
    while last > 0 and lines[last]:match("^%s*$") do
        last = last - 1
    end
    local def = string.format("[%s]: %s", label, target)
    local new = lines[last] and lines[last]:match(DEFINITION) and { def } or { "", def }
    vim.api.nvim_buf_set_lines(0, last, last, false, new)
end

-- Numbered labels count up in the order their references appear in the
-- file, whatever order they were converted in, with the definitions rewritten
-- in that order where the block already sits. Definitions nothing refers
-- to any more keep their place after the referenced ones.
local function renumber()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local defs, order, seen = {}, {}, {}
    for row, line in ipairs(lines) do
        local label = line:match(DEFINITION)
        if label and label:match("^%d+$") then
            defs[label] = { row = row, line = line }
        else
            for ref in line:gmatch("%]%[(%d+)%]") do
                if not seen[ref] then
                    seen[ref] = true
                    table.insert(order, ref)
                end
            end
        end
    end
    local unreferenced = vim.tbl_filter(function(label) return not seen[label] end, vim.tbl_keys(defs))
    table.sort(unreferenced, function(a, b) return defs[a].row < defs[b].row end)
    local renamed, block = {}, {}
    for _, old in ipairs(vim.list_extend(vim.tbl_filter(function(label) return defs[label] end, order), unreferenced)) do
        renamed[old] = tostring(#block + 1)
        table.insert(block, (defs[old].line:gsub("^(%s*)%[%d+%]", "%1[" .. renamed[old] .. "]", 1)))
    end

    local block_row = math.huge
    for _, def in pairs(defs) do
        block_row = math.min(block_row, def.row)
    end
    local new, changed = {}, false
    for row, line in ipairs(lines) do
        local label = line:match(DEFINITION)
        if label and defs[label] then
            if row == block_row then
                vim.list_extend(new, block)
            end
        else
            local rewritten = line:gsub(
                "%]%[(%d+)%]",
                function(ref) return renamed[ref] and "][" .. renamed[ref] .. "]" or nil end
            )
            table.insert(new, rewritten)
        end
    end
    for row = 1, math.max(#new, #lines) do
        if new[row] ~= lines[row] then
            changed = true
            break
        end
    end
    if changed then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, new)
    end
end

---Turn inline links into references: `[text](target)` becomes
---`[text][label]` with `[label]: target` defined at the end of the file.
---@param first integer 1-based row
---@param last integer 1-based row, inclusive
---@param col? integer 1-based column; only the link under it is converted
local function to_references(first, last, col)
    local defs = definitions()
    local converted = 0
    for row = first, last do
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        local links = inline_links(line)
        if col then
            links = vim.tbl_filter(function(link) return col >= link.s and col <= link.e end, links)
        end
        for _, link in ipairs(links) do
            local label, defined = label_for(link, defs)
            if not defined then
                define(label, link.target)
                table.insert(defs, { label = label, target = link.target })
            end
            link.label = label
        end
        -- Spliced from the right so the earlier spans keep their columns
        for i = #links, 1, -1 do
            local link = links[i]
            line = line:sub(1, link.s - 1) .. string.format("[%s][%s]", link.text, link.label) .. line:sub(link.e + 1)
            converted = converted + 1
        end
        if #links > 0 then
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line })
        end
    end
    if converted > 0 then
        renumber()
    end
    return converted
end

function M.to_reference()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if to_references(row, row, col + 1) == 0 then
        vim.notify("No inline link under cursor", vim.log.levels.WARN)
    end
end

function M.references_in_selection()
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
        first, last = last, first
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    to_references(first, last)
end

return M

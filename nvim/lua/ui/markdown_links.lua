-- Marksman resolves the target where it is attached, so anchors and
-- [[wiki links]] land on the right heading.
local M = {}

local function target_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local from = 1
    while true do
        local s, e, target = line:find("%[[^%]]*%]%(([^)]+)%)", from)
        if not s then
            return nil
        end
        if col >= s and col <= e then
            return target
        end
        from = e + 1
    end
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

return M

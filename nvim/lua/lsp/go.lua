local M = {}

---@param root string? workspace root holding go.mod
---@return string? module path from the module directive
function M.module(root)
    if not root then
        return nil
    end
    local f = io.open(vim.fs.joinpath(root, "go.mod"))
    if not f then
        return nil
    end
    for line in f:lines() do
        local module = line:match("^module%s+(%S+)")
        if module then
            f:close()
            return module
        end
    end
    f:close()
    return nil
end

return M

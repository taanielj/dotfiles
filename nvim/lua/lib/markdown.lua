local M = {}

---@param name string a path or file name
function M.is_file(name)
    return name:match("%.md$") ~= nil or name:match("%.markdown$") ~= nil
end

return M

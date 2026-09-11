local M = {}

local runners = {
    go = {
        is_test = function(name) return name:match("_test%.go$") ~= nil end,
        run = function() require("dap-go").debug_test() end,
    },
    python = {
        is_test = function(name) return name:match("^test_.*%.py$") ~= nil or name:match("_test%.py$") ~= nil end,
        run = function() require("dap-python").test_method() end,
    },
}

---@param bufnr integer
function M.in_test_file(bufnr)
    local runner = runners[vim.bo[bufnr].filetype]
    return runner ~= nil and runner.is_test(vim.fs.basename(vim.api.nvim_buf_get_name(bufnr)))
end

function M.run()
    local runner = runners[vim.bo.filetype]
    if not runner then
        vim.notify("No test debugger for " .. vim.bo.filetype, vim.log.levels.WARN)
        return
    end
    -- Loading a dap-* plugin alone skips nvim-dap's config, which sets them up
    require("dap")
    runner.run()
end

return M

local M = {}

---Rows of `{ modes, lhs, rhs, desc, expr }`, where modes and lhs may be a
---string or a list; every mapping is silent.
function M.rows(mappings)
    for _, m in ipairs(mappings) do
        local modes, keys, cmd, desc, expr = m[1], m[2], m[3], m[4], m[5]
        if type(keys) == "string" then
            keys = { keys }
        end
        for _, key in ipairs(keys) do
            vim.keymap.set(modes, key, cmd, { silent = true, desc = desc, expr = expr })
        end
    end
end

return M

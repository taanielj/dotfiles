-- Git queries against the current working directory.
local M = {}

---Run a git command and return its trimmed stdout, "" on failure.
---@param args string[]
---@return string
function M.run(args)
    local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
    if result.code ~= 0 then
        return ""
    end
    return vim.trim(result.stdout or "")
end

---Short name of the checked-out branch, "HEAD" when detached.
function M.head()
    return M.run({ "rev-parse", "--abbrev-ref", "HEAD" })
end

---Upstream of the checked-out branch, e.g. "origin/main"; "" when unset.
function M.upstream()
    return M.run({ "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}" })
end

---The remote's default branch as "origin/<name>", falling back to a local
---main or master; nil when none of those exist.
---@return string?
function M.default_branch()
    local ref = M.run({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
    if ref ~= "" then
        return ref
    end
    for _, name in ipairs({ "main", "master" }) do
        if M.run({ "rev-parse", "--verify", "--quiet", "refs/heads/" .. name }) ~= "" then
            return name
        end
    end
end

function M.is_dirty()
    return M.run({ "status", "--porcelain" }) ~= ""
end

---True when `ancestor` is reachable from `rev`.
function M.is_ancestor(ancestor, rev)
    return vim.system({ "git", "merge-base", "--is-ancestor", ancestor, rev }):wait().code == 0
end

return M

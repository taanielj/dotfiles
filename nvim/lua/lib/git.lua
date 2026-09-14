-- Git queries against the current working directory.
local M = {}

---Run a git command and return its trimmed stdout; "" on failure.
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
function M.head() return M.run({ "rev-parse", "--abbrev-ref", "HEAD" }) end

---Upstream of the checked-out branch, e.g. "origin/main"; "" when unset.
function M.upstream() return M.run({ "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}" }) end

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

---Top of the repository holding path; nil outside one.
---@param path string
---@return string?
function M.root(path) return vim.fs.root(path, ".git") end

---The ref a web URL hangs off: the checked-out branch, or the commit when
---detached or pinning, since a forge cannot resolve the literal "HEAD" that
---git names a detached checkout by.
---@param root string
---@param permalink boolean?
---@return string
local function web_ref(root, permalink)
    if not permalink then
        local branch = M.run({ "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
        if branch ~= "" and branch ~= "HEAD" then
            return branch
        end
    end
    return M.run({ "-C", root, "rev-parse", "HEAD" })
end

---The origin's web URL for a file, with a line anchor when lines are given;
---nil outside a repository or without origin. Pinning hangs the URL off the
---commit instead of the branch, so it still points at these lines later.
---@param path string
---@param first integer?
---@param last integer?
---@param opts { permalink: boolean? }?
---@return string?
function M.remote_url(path, first, last, opts)
    local root = M.root(path)
    if not root then
        return nil
    end
    local origin = M.run({ "-C", root, "remote", "get-url", "origin" })
    if origin == "" then
        return nil
    end
    origin = origin:gsub("^git@([^:]+):", "https://%1/"):gsub("%.git$", "")
    local ref = web_ref(root, opts and opts.permalink)
    local file = path:sub(#root + 2)

    local blob, anchor = "/blob/%s/%s", { "#L%d", "-L%d" }
    if origin:match("gitlab") then
        blob, anchor = "/-/blob/%s/%s", { "#L%d", "-%d" }
    elseif origin:match("bitbucket") then
        blob, anchor = "/src/%s/%s", { "#lines-%d", ":%d" }
    end
    local url = origin .. blob:format(ref, file)
    if first then
        url = url .. anchor[1]:format(first)
        if last and last ~= first then
            url = url .. anchor[2]:format(last)
        end
    end
    return url
end

---`remote_url`, warning when there is none to give.
---@return string?
function M.web_url(path, first, last, opts)
    local url = M.remote_url(path, first, last, opts)
    if not url then
        vim.notify("No git remote for this file", vim.log.levels.WARN)
    end
    return url
end

function M.is_dirty() return M.run({ "status", "--porcelain" }) ~= "" end

function M.is_ancestor(ancestor, rev)
    return vim.system({ "git", "merge-base", "--is-ancestor", ancestor, rev }):wait().code == 0
end

function M.diff_base(rev)
    if M.run({ "rev-parse", "--verify", "--quiet", rev .. "^" }) ~= "" then
        return rev .. "^"
    end
    return M.run({ "hash-object", "-t", "tree", "/dev/null" })
end

return M

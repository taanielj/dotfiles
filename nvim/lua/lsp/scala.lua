-- With a Scala build at the root, metals owns the project, Java files included.
local M = {}

M.root_markers = { "build.sbt", "build.sc", ".scala-build" }

function M.is_project()
    return vim.fs.root(0, M.root_markers) ~= nil
end

return M

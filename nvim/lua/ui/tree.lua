-- The neo-tree window and its filesystem source.
local M = {}

---@return integer? the tree window in any tabpage
function M.window() return require("lib.win").by_filetype("neo-tree") end

---The name the tree shows for its root; nil when no tree is open.
function M.display_name()
    local win = M.window()
    if not win then
        return nil
    end
    local state = require("neo-tree.sources.manager").get_state_for_window(win)
    return state and state.display_name
end

function M.refresh()
    local state = require("neo-tree.sources.manager").get_state("filesystem")
    require("neo-tree.sources.filesystem.commands").refresh(state)
end

return M

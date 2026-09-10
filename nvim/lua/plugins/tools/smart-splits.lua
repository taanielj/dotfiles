-- Keys are in keybinds/view.lua through lib/splits.lua, which picks this
-- plugin outside herdr.
return {
    "mrjones2014/smart-splits.nvim",
    cond = not require("lib.herdr").inside(),
    opts = {},
}

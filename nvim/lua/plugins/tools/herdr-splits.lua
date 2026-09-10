-- Keys are in keybinds/view.lua through lib/splits.lua, which picks this
-- plugin inside herdr. The herdr half is installed by setup/herdr.sh.
return {
    "lmilojevicc/herdr-splits.nvim",
    cond = require("lib.herdr").inside(),
    event = "VeryLazy",
    opts = {
        at_edge = "wrap",
    },
}

return {
    "rachartier/tiny-cmdline.nvim",
    init = function()
        vim.o.cmdheight = 0
        require("vim._core.ui2").enable({ msg = { targets = "msg" } })
    end,
    opts = function() return { on_reposition = require("tiny-cmdline").adapters.blink } end,
}

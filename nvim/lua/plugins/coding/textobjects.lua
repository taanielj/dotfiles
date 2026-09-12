local function select(query)
    return function() require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects") end
end
local function move(direction, query)
    return function() require("nvim-treesitter-textobjects.move")[direction](query, "textobjects") end
end

return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        select = { lookahead = true },
        move = { set_jumps = true },
    },
    -- stylua: ignore
    keys = {
        { "af", mode = { "x", "o" }, select("@function.outer"),  desc = "Function" },
        { "if", mode = { "x", "o" }, select("@function.inner"),  desc = "Function body" },
        { "ac", mode = { "x", "o" }, select("@class.outer"),     desc = "Class" },
        { "ic", mode = { "x", "o" }, select("@class.inner"),     desc = "Class body" },
        { "aa", mode = { "x", "o" }, select("@parameter.outer"), desc = "Argument" },
        { "ia", mode = { "x", "o" }, select("@parameter.inner"), desc = "Argument value" },
        { "]f", mode = { "n", "x", "o" }, move("goto_next_start", "@function.outer"),     desc = "Next function" },
        { "[f", mode = { "n", "x", "o" }, move("goto_previous_start", "@function.outer"), desc = "Previous function" },
        { "]a", mode = { "n", "x", "o" }, move("goto_next_start", "@parameter.inner"),    desc = "Next argument" },
        { "[a", mode = { "n", "x", "o" }, move("goto_previous_start", "@parameter.inner"), desc = "Previous argument" },
    },
}

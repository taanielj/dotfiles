local function select(query)
    return function() require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects") end
end
local function move(direction, query)
    return function() require("nvim-treesitter-textobjects.move")[direction](query, "textobjects") end
end
local function swap(direction, query)
    return function() require("nvim-treesitter-textobjects.swap")[direction](query, "textobjects") end
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
        -- ab and ib shadow the native synonyms for a( and i(, which stay
        { "ab", mode = { "x", "o" }, select("@block.outer"),       desc = "Block" },
        { "ib", mode = { "x", "o" }, select("@block.inner"),       desc = "Block body" },
        { "ai", mode = { "x", "o" }, select("@conditional.outer"), desc = "Conditional" },
        { "ii", mode = { "x", "o" }, select("@conditional.inner"), desc = "Conditional body" },
        { "al", mode = { "x", "o" }, select("@loop.outer"),        desc = "Loop" },
        { "il", mode = { "x", "o" }, select("@loop.inner"),        desc = "Loop body" },
        { "]f", mode = { "n", "x", "o" }, move("goto_next_start", "@function.outer"),     desc = "Next function" },
        { "[f", mode = { "n", "x", "o" }, move("goto_previous_start", "@function.outer"), desc = "Previous function" },
        { "]a", mode = { "n", "x", "o" }, move("goto_next_start", "@parameter.inner"),    desc = "Next argument" },
        { "[a", mode = { "n", "x", "o" }, move("goto_previous_start", "@parameter.inner"), desc = "Previous argument" },
        { "]A", mode = "n", swap("swap_next", "@parameter.inner"),     desc = "Move argument right" },
        { "[A", mode = "n", swap("swap_previous", "@parameter.inner"), desc = "Move argument left" },
    },
}

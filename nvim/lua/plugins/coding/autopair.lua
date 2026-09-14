local back = vim.api.nvim_replace_termcodes("<Left><Left><Left>", true, true, true)

-- mini.pairs sees one character and its two neighbours, so a third quote or
-- backtick would open another pair
local function complete_triples()
    local pairs = require("mini.pairs")
    local open = pairs.open
    pairs.open = function(pair, neigh_pattern)
        local o = pair:sub(1, 1)
        if (o == '"' or o == "'" or o == "`") and vim.fn.mode():sub(1, 1) == "i" then
            local line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2]
            if line:sub(col - 1, col) == o .. o then
                return o:rep(4) .. back
            end
        end
        return open(pair, neigh_pattern)
    end
end

return {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    config = function()
        require("mini.pairs").setup()
        complete_triples()
    end,
}

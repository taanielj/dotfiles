-- Guide colours cycle per indent level; redefined after :colorscheme clears them
local rainbow = {
    { "RainbowRed", "#E06C75" },
    { "RainbowYellow", "#E5C07B" },
    { "RainbowBlue", "#61AFEF" },
    { "RainbowOrange", "#D19A66" },
    { "RainbowGreen", "#98C379" },
    { "RainbowViolet", "#C678DD" },
    { "RainbowCyan", "#56B6C2" },
}
local rainbow_groups = vim.tbl_map(function(pair) return pair[1] end, rainbow)

-- snacks.indent walks every line from the window's top to its bottom on each redraw, the
-- thousands inside a closed fold too; hand it the visible stretches between closed folds
local function skip_closed_folds()
    local indent = require("snacks.indent")
    local on_win = indent.on_win
    indent.on_win = function(win, buf, top, bottom)
        local stretches = {}
        vim.api.nvim_win_call(win, function()
            local from = top
            while from <= bottom do
                local fold_start = from
                while fold_start <= bottom and vim.fn.foldclosed(fold_start) == -1 do
                    fold_start = fold_start + 1
                end
                if fold_start > from then
                    stretches[#stretches + 1] = { from, fold_start - 1 }
                end
                from = fold_start <= bottom and vim.fn.foldclosedend(fold_start) + 1 or fold_start
            end
        end)
        for _, stretch in ipairs(stretches) do
            on_win(win, buf, stretch[1], stretch[2])
        end
    end
end

local function rainbow_highlights()
    for _, pair in ipairs(rainbow) do
        vim.api.nvim_set_hl(0, pair[1], { fg = pair[2] })
    end
end

local header = [[
                                              
       ████ ██████           █████      ██
      ███████████             █████ 
      █████████ ███████████████████ ███   ███████████
     █████████  ███    █████████████ █████ ██████████████
    █████████ ██████████ █████████ █████ █████ ████ █████
  ███████████ ███    ███ █████████ █████ █████ ████ █████
 ██████  █████████████████████ ████ █████ █████ ████ ██████]]
-- Rows wider than the dashboard are shifted to centre them one by one, skewing the art
local header_width = 0
for _, row in ipairs(vim.split(header, "\n")) do
    header_width = math.max(header_width, vim.api.nvim_strwidth(row))
end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        dashboard = {
            enabled = true,
            width = header_width,
            formats = { header = { "%s", align = "left" } },
            preset = {
                header = header,
                keys = {
                    { icon = " ", key = "e", desc = "New file", action = ":ene | startinsert" },
                    { icon = "󰅚 ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
            sections = {
                { section = "header" },
                { section = "keys", padding = 1 },
                { title = "Recent", padding = 1 },
                { section = "recent_files", limit = 8, padding = 1 },
                { title = "Recent in " .. vim.fn.fnamemodify(".", ":~"), padding = 1 },
                { section = "recent_files", cwd = true, limit = 8, padding = 1 },
                { title = "Projects", padding = 1 },
                { section = "projects", padding = 1 },
                { section = "startup" },
            },
        },
        bigfile = { enabled = true },
        image = { enabled = true },
        indent = {
            enabled = true,
            indent = { char = "▏", hl = rainbow_groups },
            scope = { char = "▎", hl = rainbow_groups },
        },
        input = {
            enabled = true,
            win = { keys = { i_esc = { "<esc>", { "cmp_close", "cancel" }, mode = "i", expr = true } } },
        },
        notifier = { enabled = true, style = "fancy" },
        scroll = { enabled = true },
        -- Outside herdr and the Herdr app; ui/lazygit.lua opens their own popups inside them
        lazygit = {
            win = { on_close = function() require("ui.tree").refresh() end },
        },
    },
    config = function(_, opts)
        rainbow_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("rainbow_highlights", { clear = true }),
            callback = rainbow_highlights,
        })
        require("snacks").setup(opts)
        skip_closed_folds()
    end,
}

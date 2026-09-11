return {
    "smjonas/inc-rename.nvim",
    -- lazy's cmd stub has no preview callback, so a cmd trigger loses the preview on the first rename
    event = "LspAttach",
    opts = {},
}

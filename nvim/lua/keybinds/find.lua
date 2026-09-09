-- <leader>f  Find
local function builtin(picker, opts)
    return function()
        require("telescope.builtin")[picker](opts)
    end
end

require("lib.keymap").rows({
    { "n", "<leader> ",  builtin("find_files"),                                   "Find files" },
    { "n", "<leader>/",  builtin("current_buffer_fuzzy_find"),                    "Find in current buffer" },
    { "n", "<leader>fb", builtin("buffers"),                                      "Find buffers" },
    { "n", "<leader>fg", builtin("live_grep"),                                    "Find in project" },
    { "n", "<leader>fG", builtin("live_grep", { grep_open_files = true }),        "Find in open files" },
    { "n", "<leader>hf", builtin("find_files", { hidden = true, no_ignore = true }), "Find hidden files" },
    { "n", "<leader>hb", builtin("buffers", { show_all_buffers = true, no_ignore = true }), "Find hidden buffers" },
    { "n", "<leader>hg", builtin("live_grep", {
        file_ignore_patterns = { ".venv", ".idea", ".git" },
        additional_args = function()
            return { "--hidden" }
        end,
    }), "Find in hidden files" },
})

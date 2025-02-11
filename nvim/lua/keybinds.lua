-- remap ctrl-q to enter visual block mode in windows, ctrl-q quits on mac anyway
vim.keymap.set("n", "<C-q>", "<C-v>", { noremap = true, silent = true, desc = "Visual block" })

vim.g.mapleader = " "
-- =============================
-- Line movement and indentation
-- =============================

local move_mappings = {
	{ "n", "<C-Up>", ":m .-2<CR>==", "Move line up" },
	{ "n", "<C-Down>", ":m .+1<CR>==", "Move line down" },
	{ "n", "<C-Left>", "<<hhhh", "Unindent line" },
	{ "n", "<C-Right>", ">>llll", "Indent line" },
	{ "v", "<C-Up>", ":m '<-2<CR>gv=gv", "Move line up" },
	{ "v", "<C-Down>", ":m '>+1<CR>gv=gv", "Move line down" },
	{ "v", "<C-Left>", "<gvhhhh", "Unindent line" },
	{ "v", "<C-Right>", ">gvllll", "Indent line" },
}

for _, map in ipairs(move_mappings) do
	vim.keymap.set(map[1], map[2], map[3], { noremap = true, silent = true, desc = map[4] })
end

-- ==============
-- Selecting text
-- ==============

local select_mappings = {
	-- Normal mode
	{ "n", "<S-Up>", "<C-v>k", "Select up" },
	{ "n", "<S-Down>", "<C-v>j", "Select down" },
	{ "n", "<S-Left>", "vh", "Select left" },
	{ "n", "<S-Right>", "vl", "Select right" },
	{ "n", "<S-Home>", "v^", "Select to beginning of line" },
	{ "n", "<S-End>", "v$h", "Select to end of line" }, -- without newline, hit S-End again to include newline
	-- Insert mode
	{ "i", "<S-Up>", "<Esc>vkl", "Select up" },
	{ "i", "<S-Down>", "<Esc>lvjh", "Select down" },
	{ "i", "<S-Left>", "<Esc>v", "Select left" },
	{ "i", "<S-Right>", "<Esc>lv", "Select right" },
	{ "i", "<S-Home>", "<Esc>lv", "Select to beginning of line" },
	{ "i", "<S-End>", "<Esc>lv$h", "Select to end of line" }, -- without newline, hit S-End again to include newline
	-- Ignore Shift key in visual mode
	{ "v", "<S-Up>", "k", "Move up" },
	{ "v", "<S-Down>", "j", "Move down" },
	{ "v", "<S-Left>", "h", "Move left" },
	{ "v", "<S-Right>", "l", "Move right" },
	{ "v", "<S-Home>", "^", "Move to beginning of line" },
	{ "v", "<S-End>", "$", "Move to end of line" }, -- with newline
	{ "v", "<End>", "$h", "Move to end of line" }, -- without newline
	-- Select all with Ctrl + A
	{ "n", "<C-a>", "ggVG", "Select all" },
	{ "v", "<C-a>", "<Esc>ggVG", "Select all" },
	{ "i", "<C-a>", "<Esc>ggVG", "Select all" },
}

for _, map in ipairs(select_mappings) do
	vim.keymap.set(map[1], map[2], map[3], { noremap = true, silent = true, desc = map[4] })
end

-- =============
-- Deleting text
-- =============
-- ctrl backspace in insert delete

vim.keymap.set("i", "<C-H>", function()
	local col = vim.fn.col(".")
	if col == 1 then
		-- Already at start of line, no word to delete
		return ""
	end

	-- Get the character before the cursor
	local prev_char = vim.fn.getline("."):sub(col - 1, col - 1)

	if prev_char:match("%s") then
		-- If previous character is whitespace, delete it and previous word
		return "<C-o>db"
	else
		-- Otherwise, delete the previous word
		return "<C-o>dB"
	end
end, { noremap = true, expr = true, silent = true, desc = "Delete previous word consistently" })

-- ctrl delete in insert mode
vim.keymap.set("i", "<C-Del>", function()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	if col >= #line then
		return "<Del>"
	else
		return "<C-o>dw"
	end
end, { noremap = true, silent = true, expr = true, desc = "Delete next word, <Del> if end of line" })

-- ==============
-- Copy and paste
-- ==============

-- ctrl C copy in visual mode
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true, desc = "Copy" })
-- ctrl X cut in visual mode
vim.keymap.set("v", "<C-x>", '"+x', { noremap = true, silent = true, desc = "Cut" })
-- ctrl V paste in visual mode
vim.keymap.set("x", "<C-v>", '"0dP', { noremap = true, silent = true, desc = "Paste without overwriting unnamed reg" })
vim.keymap.set("i", "<C-v>", "<C-o>P", { noremap = true, silent = true, desc = "Paste" })

vim.keymap.set("n", "<Tab>", "<C-w>w", { noremap = true, silent = true, desc = "Next window" })

-- ==================
-- Search and replace
-- ==================

vim.keymap.set(
	"n",
	"<leader>s",
	":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>",
	{ noremap = true, silent = true, desc = "Search and replace" }
)

-- clear last search highlight
vim.keymap.set("n", "<leader>n", ":let @/=''<CR>", { noremap = true, silent = true, desc = "Clear search highlight" })
-- -- saving
-- quit and save all
vim.keymap.set("n", "<Leader>qq", ":wa<CR>:qa<CR>", { noremap = true, silent = true, desc = "Quit and save all" })
-- quit without saving
vim.keymap.set("n", "<Leader>qfy", ":qa!<CR>", { noremap = true, silent = true, desc = "Quit without saving?" })
-- home and end in insert mode
vim.keymap.set("i", "<Home>", "<Esc>0i", { noremap = true, silent = true, desc = "Move to beginning of line" })
vim.keymap.set("i", "<End>", "<Esc>$a", { noremap = true, silent = true, desc = "Move to end of line" })

-- ===============
-- Wrap and unwrap
-- ===============

-- turn on wrap and linebreak for current window
vim.keymap.set("n", "<leader>ww", function()
	vim.wo.wrap = true
	vim.wo.linebreak = true
	return '<Cmd>vertical rightbelow new | set winbar="" nonumber norelativenumber<CR><C-w>h<C-w>'
		.. (vim.v.count ~= 0 and vim.v.count or 125) -- linewidth is 120, add 5 to account for line numbers
		.. "|"
end, { expr = true, noremap = true, silent = true, desc = "Wrap current window" })
-- function to close no name buffers
function _G.close_no_name_buffers()
	local bufnr_list = vim.api.nvim_list_bufs()
	for _, bufnr in ipairs(bufnr_list) do
		if vim.api.nvim_buf_get_name(bufnr) == "" then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end
end

-- turn off wrap and linebreak for current window, close no name buffers
vim.keymap.set("n", "<leader>wu", function()
	vim.wo.wrap = false
	vim.wo.linebreak = false
	vim.cmd("lua close_no_name_buffers()")
end, { noremap = true, silent = true, desc = "Unwrap current window" })

-- Navigation with wrap enabled:
-- remap j and k to move visual line by line
vim.keymap.set("n", "j", 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set("n", "k", 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap gj and gk to move visual line by line
vim.keymap.set("x", "j", 'v:count ? "j" : "gj"', { noremap = true, expr = true })
vim.keymap.set("x", "k", 'v:count ? "k" : "gk"', { noremap = true, expr = true })
-- remap arrow keys in all modes to move visual line by line
vim.keymap.set("n", "<Up>", "gk", { noremap = true })
vim.keymap.set("n", "<Down>", "gj", { noremap = true })
vim.keymap.set("x", "<Up>", "gk", { noremap = true })
vim.keymap.set("x", "<Down>", "gj", { noremap = true })
vim.keymap.set("i", "<Up>", "<C-o>gk", { noremap = true })
vim.keymap.set("i", "<Down>", "<C-o>gj", { noremap = true })

-- ===========================
-- Surround plugin replacement
-- ===========================

-- surround with quotes, '''''', brackets, etc. in visual mode (non block, only regular)
vim.keymap.set("v", "'", "c''<Esc>P", { noremap = true, silent = true, desc = "Add single quotes" })
vim.keymap.set("v", '"', 'c""<Esc>P', { noremap = true, silent = true, desc = "Add double quotes" })
vim.keymap.set("v", "`", "c``<Esc>P", { noremap = true, silent = true, desc = "Add backticks" })
vim.keymap.set("v", "(", "c()<Esc>P", { noremap = true, silent = true, desc = "Add parentheses" })
vim.keymap.set("v", ")", "c()<Esc>P", { noremap = true, silent = true, desc = "Add parentheses" })
vim.keymap.set("v", "[", "c[]<Esc>P", { noremap = true, silent = true, desc = "Add brackets" })
vim.keymap.set("v", "]", "c[]<Esc>P", { noremap = true, silent = true, desc = "Add brackets" })
vim.keymap.set("v", "{", "c{}<Esc>P", { noremap = true, silent = true, desc = "Add curly braces" })
vim.keymap.set("v", "}", "c{}<Esc>P", { noremap = true, silent = true, desc = "Add curly braces" })
vim.keymap.set("v", "<", "c<><Esc>P", { noremap = true, silent = true, desc = "Add angle brackets" })
vim.keymap.set("v", ">", "c<><Esc>P", { noremap = true, silent = true, desc = "Add angle brackets" })

-- surround with triple quotes ('''''', """""", ``````, etc.) in visual mode (non block, only regular)
vim.keymap.set("v", "<Leader>'", "c''''''<Esc>3hp", { noremap = true, silent = true, desc = "Add triple quotes" })
vim.keymap.set("v", '<Leader>"', 'c""""""<Esc>3hp', { noremap = true, silent = true, desc = "Add triple quotes" })
vim.keymap.set("v", "<Leader>`", "c``````<Esc>3hp", { noremap = true, silent = true, desc = "Add triple backticks" })

-- surround with double brackets, double parentheses, double curly braces, etc. in visual mode (non block, only regular)
vim.keymap.set("v", "<Leader>(", "c(()))<Esc>2hp", { noremap = true, silent = true, desc = "Add double parentheses" })
vim.keymap.set("v", "<Leader>)", "c(()))<Esc>2hp", { noremap = true, silent = true, desc = "Add double parentheses" })
vim.keymap.set("v", "<Leader>[", "c[[]]<Esc>2hp", { noremap = true, silent = true, desc = "Add double brackets" })
vim.keymap.set("v", "<Leader>]", "c[[]]<Esc>2hp", { noremap = true, silent = true, desc = "Add double brackets" })
vim.keymap.set("v", "<Leader>{", "c{{}}<Esc>2hp", { noremap = true, silent = true, desc = "Add double curly braces" })
vim.keymap.set("v", "<Leader>}", "c{{}}<Esc>2hp", { noremap = true, silent = true, desc = "Add double curly braces" })
vim.keymap.set("v", "<Leader><", "c<<>><Esc>2hp", { noremap = true, silent = true, desc = "Add double angle brackets" })
vim.keymap.set("v", "<Leader>>", "c<<>><Esc>2hp", { noremap = true, silent = true, desc = "Add double angle brackets" })

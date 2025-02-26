return {
	"soulis-1256/eagle.nvim",
	opts = {
		border = "rounded",
		mouse_mode = true,
		keyboard_mode = true,
		title = "",
		improved_markdown = true,
	},
	vim.keymap.set("n", "K", function()
		local winid = require("ufo").peekFoldedLinesUnderCursor()
		if not winid then
			vim.cmd("EagleWin")
		end
	end, { noremap = true, silent = true }),
}

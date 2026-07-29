return {
    "nvzone/menu",
    dependencies = { "nvzone/volt" },

    config = function()
        local menu = require("menu")
        local menu_utils = require("menu.utils")

        local M = {}

        -- Leader-based default menu
        vim.keymap.set("n", "<leader>.", function()
            vim.g.menu_context = nil
            menu.open("default")
        end, {})

        -- Global right-click (in buffer windows)
        vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
            vim.cmd.exec('"normal! \\<RightMouse>"')
            local mouse = vim.fn.getmousepos()
            if mouse.screenrow == 1 then
                -- Prevent menu from opening in the command line area
                return
            end

            menu_utils.delete_old_menus()

            local winid = mouse.winid
            local bufnr = vim.api.nvim_win_get_buf(winid)
            local ft = vim.bo[bufnr].filetype
            local bufname = vim.api.nvim_buf_get_name(bufnr)

            vim.g.menu_context = {
                bufnr = bufnr,
                bufname = bufname,
                filetype = ft,
            }

            local options = (ft == "neo-tree") and "neotree" or "default"
            menu.open(options, { mouse = true })
        end, {})

        -- 🔧 BufferLine-specific menu entry point
        function M.open_buffer_menu(bufnr)
            vim.g.menu_context = {
                bufnr = bufnr,
                bufname = vim.api.nvim_buf_get_name(bufnr),
                filetype = vim.bo[bufnr].filetype,
            }

            menu_utils.delete_old_menus()
            menu.open("bufferline", { mouse = true })
        end

        -- Expose the helper
        package.loaded["menu"] = M -- override original module with our augmented one
    end,
}

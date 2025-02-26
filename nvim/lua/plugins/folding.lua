return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        config = function()
            local handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                -- local suffix = (" 󰁂 %d "):format(endLnum - lnum)
                local suffix = (" ... %d lines "):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end
            vim.o.foldlevel = 99
            vim.o.foldcolumn = "1"
            vim.wo.foldnestmax = 1
            vim.wo.foldminlines = 1
            vim.o.foldenable = true
            vim.o.foldlevelstart = 99
            vim.o.foldtext = table.concat({
                "substitute(getline(v:foldstart), '\\t', repeat(' ', &tabstop), 'g')",
                ".. ' ... '",
                ".. '(' . (v:foldend - v:foldstart + 1) . ' lines)'",
            }, ".")
            vim.o.foldmethod = "manual"
            vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
            vim.o.fillchars = table.concat({
                "eob:" .. " ",
                "fold:" .. ".",
                "foldopen:" .. "",
                "foldsep:" .. " ",
                "foldclose:" .. "",
            }, ",")

            vim.cmd("highlight Folded ctermbg=NONE guibg=NONE")
            vim.cmd("highlight FoldColumn ctermfg=NONE guifg=NONE")

            vim.api.nvim_create_autocmd("BufWritePre", {
                desc = "Save Folds",
                group = vim.api.nvim_create_augroup("save_folds_view", { clear = true }),

                callback = function()
                    vim.cmd("mkview")
                end,
            })
            vim.api.nvim_create_autocmd("BufReadPost", {
                desc = "Restore Folds",
                group = vim.api.nvim_create_augroup("restore_folds_view", { clear = true }),

                callback = function()
                    vim.cmd("silent! loadview")
                end,
            })

            vim.keymap.set("n", "zR", require("ufo").openAllFolds, { silent = true, desc = "Open all folds" })
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { silent = true, desc = "Close all folds" })

            -- lsp -> indent
            ---@diagnostic disable-next-line
            require("ufo").setup({
                fold_virt_text_handler = handler,
            })
        end,
    },
    {
        "luukvbaal/statuscol.nvim",
        opts = function()
            local builtin = require("statuscol.builtin")
            return {
                setopt = true,
                -- override the default list of segments with:
                -- number-less fold indicator, then signs, then line number & separator
                segments = {
                    { text = { "%s" }, click = "v:lua.ScSa" },
                    {
                        text = { builtin.lnumfunc, " " },
                        condition = { true, builtin.not_empty },
                        click = "v:lua.ScLa",
                    },
                    { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
                },
            }
        end,
    },
}

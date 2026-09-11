return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        config = function()
            local handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
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
                        -- truncate() may return fewer columns than asked, so pad the suffix
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
            vim.api.nvim_create_autocmd("BufWritePre", {
                desc = "Save Folds",
                group = vim.api.nvim_create_augroup("save_folds_view", { clear = true }),

                -- :wa writes a hidden buffer from the autocmd window, which has no folds
                callback = function()
                    if vim.fn.win_gettype() ~= "autocmd" then
                        vim.cmd("mkview")
                    end
                end,
            })
            vim.api.nvim_create_autocmd("BufReadPost", {
                desc = "Restore Folds",
                group = vim.api.nvim_create_augroup("restore_folds_view", { clear = true }),

                callback = function() require("lib.view").load() end,
            })

            ---@diagnostic disable-next-line
            require("ufo").setup({
                fold_virt_text_handler = handler,
                provider_selector = function(bufnr, filetype, buftype)
                    if filetype == "markdown" then
                        return { "treesitter", "indent" }
                    end
                    return { "lsp", "indent" }
                end,
            })
        end,
    },
    {
        "luukvbaal/statuscol.nvim",
        opts = function()
            local builtin = require("statuscol.builtin")
            return {
                setopt = true,
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

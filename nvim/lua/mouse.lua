local function setup_popup_menu()
    vim.cmd([[
            aunmenu PopUp
            anoremenu PopUp.Inspect     <cmd>Inspect<CR>
        ]])

    -- Add menu items based on filetype
    if vim.bo.filetype ~= "neo-tree" then
        vim.cmd([[
                anoremenu PopUp.Open\ URL gx
            ]])
        if vim.lsp.get_clients({ bufnr = 0 })[1] then
            vim.cmd([[
                anoremenu PopUp.Definition  <cmd>lua vim.lsp.buf.definition()<CR>
                anoremenu PopUp.References  <cmd>Telescope lsp_references<CR>
                anoremenu PopUp.Back        <C-t>
                anoremenu PopUp.Rename\ Symbol <cmd>lua vim.lsp.buf.rename()<CR>
            ]])
        end

        vim.cmd([[
                amenu PopUp.-3-         <NOP>
                vnoremenu PopUp.Cut                     "+x
                vnoremenu PopUp.Copy                    "+y
                anoremenu PopUp.Paste                   "+gP
                vnoremenu PopUp.Paste                   "+P
                vnoremenu PopUp.Delete                  "_x
                nnoremenu PopUp.Select\ All             ggVG
                vnoremenu PopUp.Select\ All             gg0oG$
                inoremenu PopUp.Select\ All             <C-Home><C-O>VG
            ]])
        if vim.bo.filetype == "lua" then
            vim.cmd([[
                    amenu PopUp.-2-         <NOP>
                    anoremenu PopUp.LoadLua     <cmd>%lua<CR>
                ]])
        end
    end
end
local popup_group = vim.api.nvim_create_augroup("nvim_popupmenu", { clear = true })
vim.api.nvim_create_autocmd("MenuPopup", {
    pattern = "*",
    group = popup_group,
    desc = "Custom Popup Setup",
    callback = setup_popup_menu,
})

vim.keymap.set("n", "<leader>.", function()
    setup_popup_menu()
    vim.cmd("popup PopUp")
end, { noremap = true, silent = true, desc = "Open right click menu" })

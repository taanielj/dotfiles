local neo_tree_open = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    if node.type == "directory" then
        if not node:is_expanded() then
            require("neo-tree.sources.filesystem").toggle_directory(state, node)
        elseif node:has_children() then
            require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
        end
    end
    if node.type == "file" then
        require("neo-tree.utils").open_file(state, path)
    end
end

local popup_group = vim.api.nvim_create_augroup("nvim_popupmenu", { clear = true })
vim.api.nvim_create_autocmd("MenuPopup", {
    pattern = "*",
    group = popup_group,
    desc = "Custom Popup Setup",
    callback = function()
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
    end,
})

return {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    event = "BufReadPost",
    config = function()
        -- folding settings
        vim.o.foldcolumn = "1" -- '0' is not bad
        vim.o.foldlevel = 99 -- ufo needs a large value
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true

        -- keymaps
        vim.keymap.set("n", "zR", require("ufo").openAllFolds)
        vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

        -- setup LSP capabilities for folding
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
        }

        local lspconfig = require("lspconfig")
        local servers = { "lua_ls", "basedpyright" }
        for _, server in ipairs(servers) do
            lspconfig[server].setup({
                capabilities = capabilities,
            })
        end

        -- finally setup ufo
        require("ufo").setup()
    end,
}

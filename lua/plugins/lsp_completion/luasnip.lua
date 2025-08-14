return {
    "L3MON4D3/LuaSnip",
    -- enable = false,
    event = { "InsertEnter", "CmdlineEnter" },
    version = "2.*",
    build = (function()
        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
        end
        return "make install_jsregexp"
    end)(),
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
        require("luasnip").setup({ enable_autosnippets = true })
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").load({
            paths = { "./lua/plugins/lsp_completion/snippets" },
        })
    end,
}

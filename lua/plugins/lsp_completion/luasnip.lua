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
        -- keymaps
        -- stylua: ignore start
        vim.keymap.set({ "i", "s" }, "<Tab>", function() if require("luasnip").expand_or_jumpable() then require("luasnip").expand_or_jump() else vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false) end end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<S-Tab>", function() if require("luasnip").jumpable(-1) then require("luasnip").jump(-1) else vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false) end end, { silent = true })
        -- stylua: ignore end

        require("luasnip").setup({ enable_autosnippets = true })
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").load({
            paths = { "./lua/plugins/lsp_completion/snippets" },
        })
    end,
}

return {
    "williamboman/mason.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    opts = {
        ui = {
            border = "rounded",
            backdrop = 100,
        },
    },
    config = function(_, opts)
        require("mason").setup(opts)

        local servers = {
            "lua_ls", -- lua lsp
            "basedpyright", -- python lsp
        }

        ---@type MasonLspconfigSettings
        ---@diagnostic disable-next-line: missing-fields
        require("mason-lspconfig").setup({
            automatic_enable = servers,
        })

        local ensure_installed = vim.list_extend(servers, {
            "luacheck", -- lua linter
            "stylua", -- lua formatter
            "ruff", -- python linter
            "black", -- python formatter
        })
        require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
    end,
}

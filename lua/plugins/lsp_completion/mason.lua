return {
    "williamboman/mason.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        -- Mason
        require("mason").setup({
            ui = {
                border = "rounded",
                backdrop = 100,
            },
        })

        -- Mason lsp config
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls", -- lua lsp
                "basedpyright", -- python lsp
                "bashls", -- bash lsp
            },
            automatic_enable = true,
        })

        -- Custom tool installation using Mason registry directly
        local tools = {
            "luacheck", -- lua linter
            "stylua", -- lua formatter
            "ruff", -- python linter/formatter
            "shellcheck", -- bash linter
            "shfmt", -- bash formatter
        }

        local registry = require("mason-registry")
        registry.refresh(function()
            for _, name in ipairs(tools) do
                if not registry.is_installed(name) then
                    local package = registry.get_package(name)

                    vim.notify(name .. ": installing", vim.log.levels.INFO)

                    package:install():once("closed", function()
                        if package:is_installed() then
                            vim.notify(name .. ": successfully installed", vim.log.levels.INFO)
                        else
                            vim.notify(name .. ": installation failed", vim.log.levels.ERROR)
                        end
                    end)
                end
            end
        end)
    end,
}

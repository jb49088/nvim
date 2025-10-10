return {
    "williamboman/mason.nvim",
    -- enabled = false,
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
                "powershell_es", -- powershell lsp (includes formatter and linter)
                "html", -- html lsp
                "cssls", -- css lsp
            },
            automatic_enable = true,
        })

        -- Custom tool installation using Mason registry directly
        -- mason-tool-installer.nvim added too much startup time
        local tools = {
            "luacheck", -- lua linter
            "stylua", -- lua formatter
            "ruff", -- python linter/formatter
            "shellcheck", -- bash linter
            "shfmt", -- bash formatter
            "htmlhint", -- html linter
            "prettier", -- js, ts, css, html, md, yaml etc formatter
            "djlint", -- html linter/formatter designed for django
            "stylelint", -- css linter
            "sqruff", -- sql linter/formatter
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

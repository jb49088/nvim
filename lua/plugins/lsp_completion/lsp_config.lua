return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { "williamboman/mason.nvim", opts = {} },
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "saghen/blink.cmp",
    },
    config = function()
        -- lsp attach autocommand
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
            callback = function(event)
                -- -- Disable semantic tokens
                -- local client = vim.lsp.get_client_by_id(event.data.client_id)
                -- if client and client.server_capabilities.semanticTokensProvider then
                --     client.server_capabilities.semanticTokensProvider = nil
                -- end

                local map = function(keys, func, desc, mode)
                    mode = mode or "n"
                    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
                end

                -- lsp keymaps
                -- stylua: ignore start
                map("<leader>ch", vim.diagnostic.open_float, "Hover Diagnostics")
                map("<leader>cH", vim.lsp.buf.hover, "Hover Info")
                map("<leader>cR", vim.lsp.buf.rename, "Rename")
                map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "v" })
                map("<leader>cA", function() vim.lsp.buf.code_action({ context = { only = { "source" } } }) end, "Source Action")
                map("<leader>cc", vim.lsp.codelens.run, "Run Codelens", { "n", "v" })
                map("<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens", { "n" })
                map("<leader>cI", function() Snacks.picker.lsp_config() end, "LSP Info")
                map("<leader>cr", function() Snacks.picker.lsp_references() end, "Goto References")
                map("<leader>ci", function() Snacks.picker.lsp_implementations() end, "Goto Implementation")
                map("<leader>cd", function() Snacks.picker.lsp_definitions() end, "Goto Definition")
                map("<leader>cD", function() Snacks.picker.lsp_declarations() end, "Goto Declaration")
                map("<leader>cM", function() Snacks.picker.lsp_symbols() end, "Document Symbols")
                map("<leader>cW", function() Snacks.picker.lsp_workspace_symbols() end, "Workspace Symbols")
                map("<leader>ct", function() Snacks.picker.lsp_type_definitions() end, "Goto Type Definition")
                -- stylua: ignore end
            end,
        })

        local servers = {
            lua_ls = { -- lua lsp
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = "Replace",
                        },
                        hint = {
                            enable = true,
                            setType = false,
                            paramType = true,
                            paramName = "Disable",
                            semicolon = "Disable",
                            arrayIndex = "Disable",
                        },
                        diagnostics = {
                            globals = {
                                "Snacks",
                            },
                        },
                    },
                },
            },
            basedpyright = { -- python lsp
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = "basic",
                            extraPaths = { "." },
                        },
                    },
                },
            },
            -- pyright = { -- python lsp
            --     settings = {
            --         python = {
            --             analysis = {
            --                 typeCheckingMode = "standard",
            --                 autoSearchPaths = true,
            --                 useLibraryCodeForTypes = true,
            --                 extraPaths = { "." },
            --             },
            --         },
            --     },
            -- },
        }

        ---@type MasonLspconfigSettings
        ---@diagnostic disable-next-line: missing-fields
        require("mason-lspconfig").setup({
            automatic_enable = vim.tbl_keys(servers or {}),
        })

        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
            "luacheck", -- lua linter
            "stylua", -- lua formatter
            "ruff", -- python linter
            "black", -- python formatter
        })
        require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

        for server_name, config in pairs(servers) do
            vim.lsp.config(server_name, config)
        end
    end,
}

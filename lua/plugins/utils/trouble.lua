return {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = function()
        -- Get MiniIcons LSP configuration if available
        local has_miniicons, miniicons = pcall(require, "mini.icons")
        local kinds = {}
        local highlight_links = {}

        if has_miniicons then
            -- Map MiniIcons LSP kind names to Trouble's expected names
            local kind_mapping = {
                array = "Array",
                boolean = "Boolean",
                class = "Class",
                constant = "Constant",
                constructor = "Constructor",
                enum = "Enum",
                enummember = "EnumMember",
                event = "Event",
                field = "Field",
                file = "File",
                ["function"] = "Function",
                interface = "Interface",
                key = "Key",
                method = "Method",
                module = "Module",
                namespace = "Namespace",
                null = "Null",
                number = "Number",
                object = "Object",
                operator = "Operator",
                package = "Package",
                property = "Property",
                string = "String",
                struct = "Struct",
                typeparameter = "TypeParameter",
                variable = "Variable",
            }

            -- Extract icons and highlight groups from MiniIcons using correct API
            for mini_kind, trouble_kind in pairs(kind_mapping) do
                local icon, hl = miniicons.get("lsp", mini_kind)
                if icon then
                    kinds[trouble_kind] = icon
                    highlight_links["TroubleIcon" .. trouble_kind] = hl
                end
            end
        end

        return {
            modes = {
                lsp = {
                    win = { position = "right" },
                },
            },
            icons = {
                kinds = kinds, -- Will use MiniIcons glyphs or fall back to defaults
            },
            _miniicons_highlights = highlight_links, -- Store for use in config function
        }
    end,
    config = function(_, opts)
        -- Set up the plugin with the options
        require("trouble").setup(opts)

        -- Apply MiniIcons highlight links if available
        if opts._miniicons_highlights then
            for trouble_hl, miniicons_hl in pairs(opts._miniicons_highlights) do
                vim.api.nvim_set_hl(0, trouble_hl, { link = miniicons_hl })
            end
        end
    end,
    keys = {
        { "<leader>xx", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
        { "<leader>xX", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics (Trouble)" },
        -- { "<leader>cs", "<Cmd>Trouble lsp_document_symbols toggle<CR>", desc = "Symbols (Trouble)" },
        -- { "<leader>cS", "<Cmd>Trouble lsp toggle<CR>", desc = "LSP References/Definitions/... (Trouble)" },
        { "<leader>xL", "<Cmd>Trouble loclist toggle<CR>", desc = "Location List (Trouble)" },
        { "<leader>xQ", "<Cmd>Trouble qflist toggle<CR>", desc = "Quickfix List (Trouble)" },
        {
            "[q",
            function()
                if require("trouble").is_open() then
                    require("trouble").prev({ skip_groups = true, jump = true })
                else
                    local ok, err = pcall(vim.cmd.cprev)
                    if not ok then
                        vim.notify(err, vim.log.levels.ERROR)
                    end
                end
            end,
            desc = "Previous Trouble/Quickfix Item",
        },
        {
            "]q",
            function()
                if require("trouble").is_open() then
                    require("trouble").next({ skip_groups = true, jump = true })
                else
                    local ok, err = pcall(vim.cmd.cnext)
                    if not ok then
                        vim.notify(err, vim.log.levels.ERROR)
                    end
                end
            end,
            desc = "Next Trouble/Quickfix Item",
        },
    },
}

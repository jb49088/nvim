-- ================================================================================
-- =                                  NOICE.NVIM                                  =
-- ================================================================================

return {
    "folke/noice.nvim",
    -- enabled = false,
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    opts = {
        lsp = {
            documentation = {
                opts = {
                    scrollbar = true,
                },
            },
            signature = {
                enabled = false, -- using blinkcmp signatures
            },
            hover = {
                enabled = false, -- using default vim.lsp.buf.hover()
            },
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
        },
        cmdline = {
            -- view = "cmdline",
            format = {
                lua = false,
                filter = false,
                help = false,
            },
        },
        presets = {
            -- command_palette = true,
            -- bottom_search = true,
            long_message_to_split = true,
            lsp_doc_border = true,
        },
        routes = {
            {
                filter = {
                    event = "msg_show",
                    any = {
                        { find = "%d+L, %d+B" },
                        { find = "; after #%d+" },
                        { find = "; before #%d+" },
                    },
                },
                view = "mini",
            },
        },
    },
    config = function(_, opts)
        -- HACK: noice shows messages from before it was enabled,
        -- but this is not ideal when Lazy is installing plugins,
        -- so clear the messages in this case.
        if vim.o.filetype == "lazy" then
            vim.cmd([[messages clear]])
        end
        require("noice").setup(opts)
    end,
}

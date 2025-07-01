return {
    "folke/noice.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    event = "VeryLazy",
    opts = {
        lsp = {
            signature = {
                enabled = false,
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
            lsp_doc_border = true,
        },
    },
}

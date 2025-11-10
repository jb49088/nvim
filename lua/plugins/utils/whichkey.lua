-- ================================================================================
-- =                                WHICH-KEY.NVIM                                =
-- ================================================================================

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "helix",
        delay = 200,
        icons = { mappings = false, breadcrumb = "", group = "" },
        defaults = {},
        show_help = true,
        spec = {
            -- Groups
            { "<leader>b", group = " Buffer" },
            { "<leader>c", group = " Code" },
            { "<leader>d", group = " Debug" },
            { "<leader>D", group = " Divider" },
            { "<leader>f", group = " File/Find" },
            { "<leader>g", group = "󰊢 Git" },
            { "<leader>gh", group = "󰊢 Hunks" },
            { "<leader>n", group = "󰈸 Noice" },
            { "<leader>r", group = " Run" },
            { "<leader>s", group = " Search" },
            { "<leader>t", group = " Test" },
            { "<leader>u", group = "󱕷 UI/UX" },
            { "<leader>w", group = "󰕰 Window" },
            { "<leader>x", group = " Diagnostics/Quickfix" },
            { "<leader>T", group = "󰓩 Tab" },
        },
    },
    config = function(_, opts)
        require("which-key").setup(opts)
    end,
}

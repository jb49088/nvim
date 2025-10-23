return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "helix",
        delay = 0,
        defaults = {},
        show_help = true,
        spec = {
            -- individual keymaps
            { "<leader>K", icon = { icon = "󰋽", hl = "MiniIconsBlue" } },
            { "<leader>cm", icon = { icon = "󱁤", hl = "MiniIconsGrey" } },
            -- groups
            { "<leader>b", group = "Buffer" },
            { "<leader>c", group = "Code" },
            { "<leader>d", group = "Divider", icon = { icon = "", hl = "MiniIconsGrey" } },
            { "<leader>f", group = "File/Find" },
            { "<leader>g", group = "Git" },
            { "<leader>gh", group = "Hunks" },
            { "<leader>n", group = "Noice" },
            { "<leader>r", group = "Run", icon = { icon = "", hl = "MiniIconsRed" } },
            { "<leader>s", group = "Search" },
            { "<leader>S", group = "Session" },
            { "<leader>t", group = "Test", icon = { icon = "󰱑", hl = "MiniIconsGreen" } },
            { "<leader>T", group = "Terminal" },
            { "<leader>u", group = "UI" },
            { "<leader>w", group = "Window" },
            { "<leader>x", group = "Diagnostics/Quickfix" },
            { "<leader><Tab>", group = "Tab" },
        },
    },
    config = function(_, opts)
        require("which-key").setup(opts)
    end,
}

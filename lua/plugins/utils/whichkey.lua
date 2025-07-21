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
            { "<leader>r", icon = { icon = "", hl = "MiniIconsRed" } },
            { "<leader>R", icon = { icon = "", hl = "MiniIconsRed" } },
            { "<leader>K", icon = { icon = "󰋽", hl = "MiniIconsBlue" } },
            { "<leader>v", icon = { icon = "", hl = "MiniIconsYellow" } },
            -- groups
            { "<leader>b", group = "Buffer" },
            { "<leader>c", group = "Code" },
            { "<leader>f", group = "File/Find" },
            { "<leader>g", group = "Git" },
            { "<leader>gh", group = "Hunks" },
            { "<leader>n", group = "Noice" },
            { "<leader>s", group = "Search" },
            { "<leader>S", group = "Session" },
            { "<leader>u", group = "UI" },
            { "<leader>w", group = "Window" },
            { "<leader>x", group = "Diagnostics/Quickfix" },
            { "<leader>t", group = "Tab" },
            { "<leader>T", group = "Terminal" },
        },
    },
    config = function(_, opts)
        require("which-key").setup(opts)
    end,
}

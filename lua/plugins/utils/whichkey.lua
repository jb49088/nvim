return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "helix",
        delay = 0,
        defaults = {},
        show_help = false,
        spec = {
            { "<leader>c", group = "Code" },
            { "<leader><Tab>", group = "Tab" },
            { "<leader>u", group = "UI" },
            { "<leader>f", group = "File/Find" },
            { "<leader>g", group = "Git" },
            { "<leader>h", group = "Harpoon" },
            { "<leader>s", group = "Search" },
            { "<leader>w", group = "Window" },
            { "<leader>b", group = "Buffer" },
            { "<leader>x", group = "Diagnostics/Quickfix" },
        },
    },
    config = function(_, opts)
        require("which-key").setup(opts)
    end,
}

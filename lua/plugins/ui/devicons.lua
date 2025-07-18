return {
    "nvim-tree/nvim-web-devicons",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
        config = function(_, opts)
            require("nvim-web-devicons").setup(opts)
        end,
    },
}

return {
    "windwp/nvim-ts-autotag",
    -- enabled = false,
    after = "nvim-treesitter",
    config = function()
        require("nvim-ts-autotag").setup()
    end,
}

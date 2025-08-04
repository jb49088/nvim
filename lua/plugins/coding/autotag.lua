return {
    "windwp/nvim-ts-autotag",
    -- enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("nvim-ts-autotag").setup()
    end,
}

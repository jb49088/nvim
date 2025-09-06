return {
    "Mr-LLLLL/cool-chunk.nvim",
    enabled = false,
    event = { "CursorHold", "CursorHoldI" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("cool-chunk").setup({
            chunk = {
                animate_duration = 200,
            },
        })
    end,
}

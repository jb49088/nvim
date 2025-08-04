return {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    version = "*",
    config = function()
        require("mini.ai").setup({ n_lines = 500 })
    end,
}

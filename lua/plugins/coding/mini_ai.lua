return {
    "echasnovski/mini.ai",
    -- enabled = false,
    event = "VeryLazy",
    version = "*",
    config = function()
        require("mini.ai").setup({ n_lines = 500 })
    end,
}

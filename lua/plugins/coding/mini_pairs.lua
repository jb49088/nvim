return {
    "echasnovski/mini.pairs",
    version = "*",
    config = function()
        require("mini.pairs").setup({
            modes = {
                insert = true,
                command = true,
                terminal = false,
            },
        })
    end,
}

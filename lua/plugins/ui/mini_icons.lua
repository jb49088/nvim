return {
    "echasnovski/mini.icons",
    version = "*",
    config = function()
        require("mini.icons").setup()
        MiniIcons.mock_nvim_web_devicons()
    end,
}

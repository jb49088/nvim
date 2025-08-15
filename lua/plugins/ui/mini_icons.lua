return {
    "echasnovski/mini.icons",
    -- enabled = false,
    lazy = true,
    opts = {
        file = {
            [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
            ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        },
        filetype = {
            terminal = { glyph = "", hl = "MiniIconsRed" },
            dotenv = { glyph = "", hl = "MiniIconsYellow" },
        },
        lsp = {},
    },
    init = function()
        package.preload["nvim-web-devicons"] = function()
            require("mini.icons").mock_nvim_web_devicons()
            return package.loaded["nvim-web-devicons"]
        end
    end,
}

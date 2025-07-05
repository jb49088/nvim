return {
    "sethen/line-number-change-mode.nvim",
    config = function()
        local c = require("astrotheme.lib.util").set_palettes(require("astrotheme").config)

        require("line-number-change-mode").setup({
            mode = {
                n = { fg = c.ui.blue, bold = true },
                i = { fg = c.ui.green, bold = true },
                v = { fg = c.ui.purple, bold = true },
                V = { fg = c.ui.purple, bold = true },
                c = { fg = c.ui.yellow, bold = true },
                t = { fg = c.ui.orange, bold = true },
                R = { fg = c.ui.red, bold = true },
            },
        })
    end,
}

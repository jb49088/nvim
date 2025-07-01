local hl = vim.api.nvim_set_hl
local c = require("astrotheme.lib.util").set_palettes(require("astrotheme").config)

-- Title
hl(0, "FloatTitle", { fg = c.ui.blue, bg = c.ui.base })

-- Floating windows
hl(0, "NormalFloat", { fg = c.ui.text_active, bg = c.ui.base })
hl(0, "FloatBorder", { fg = c.ui.border, bg = c.ui.base })
hl(0, "Pmenu", { fg = c.ui.text_active, bg = c.ui.base })

-- Statusline
hl(0, "StatusLine", { bg = c.ui.base })

-- Gutter
hl(0, "EndOfBuffer", { fg = c.ui.base })

-- Blink cmp
hl(0, "BlinkCmpMenuBorder", { fg = c.ui.border, bg = c.ui.base })
hl(0, "BlinkCmpDocBorder", { fg = c.ui.border, bg = c.ui.base })
hl(0, "BlinkCmpLabelMatch", { fg = c.ui.blue, bold = true })

-- Pretty-path
hl(0, "PrettyPathDir", { fg = c.syntax.comment })
hl(0, "PrettyPathModified", { fg = c.ui.yellow, bold = true })

-- Snacks picker
hl(0, "SnacksPickerDir", { fg = c.syntax.comment })
hl(0, "SnacksPickerBufFlags", { fg = c.syntax.comment })
hl(0, "SnacksPickerCol", { fg = c.syntax.comment })

-- Noice
hl(0, "NoiceCmdlineIcon", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopupBorderCmdline", { fg = c.ui.yellow })

-- Illuminate
hl(0, "IlluminatedWordText", { underline = true })
hl(0, "IlluminatedWordRead", { underline = true })
hl(0, "IlluminatedWordWrite", { underline = true })

-- Rainbow delimiters
hl(0, "RainbowDelimiters1", { fg = c.ui.red })
hl(0, "RainbowDelimiters2", { fg = c.ui.yellow })
hl(0, "RainbowDelimiters3", { fg = c.ui.blue })
hl(0, "RainbowDelimiters4", { fg = c.ui.orange })
hl(0, "RainbowDelimiters5", { fg = c.ui.green })
hl(0, "RainbowDelimiters6", { fg = c.ui.purple })
hl(0, "RainbowDelimiters7", { fg = c.ui.cyan })

-- Lualine
LualineTheme = {
    normal = {
        a = { fg = c.ui.base, bg = c.syntax.blue, gui = "bold" },
        b = { fg = c.ui.text_active, bg = c.ui.base },
        c = { fg = c.ui.text_active, bg = c.ui.base },
    },
    insert = { a = { fg = c.ui.base, bg = c.ui.green, gui = "bold" } },
    visual = { a = { fg = c.ui.base, bg = c.ui.purple, gui = "bold" } },
    replace = { a = { fg = c.ui.base, bg = c.ui.red, gui = "bold" } },
    command = { a = { fg = c.ui.base, bg = c.ui.yellow, gui = "bold" } },
    terminal = { a = { fg = c.ui.base, bg = c.ui.orange, gui = "bold" } },
    inactive = {
        a = { fg = c.ui.text_inactive, bg = c.ui.base, gui = "bold" },
        b = { fg = c.ui.text_inactive, bg = c.ui.base, gui = "bold" },
        c = { fg = c.ui.text_inactive, bg = c.ui.base, gui = "bold" },
    },
}

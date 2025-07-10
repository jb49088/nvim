local hl = vim.api.nvim_set_hl
local c = require("astrotheme.lib.util").set_palettes(require("astrotheme").config)

-- Titles
hl(0, "FloatTitle", { fg = c.ui.blue })

-- Floating windows
hl(0, "NormalFloat", { fg = c.ui.text_active })
hl(0, "FloatBorder", { fg = c.ui.border })
hl(0, "Pmenu", { fg = c.ui.text_active })

-- Cursorline
hl(0, "CursorLine", { bg = nil })

-- Statusline
hl(0, "StatusLine", { fg = c.ui.text })

-- Window separator
hl(0, "WinSeparator", { fg = c.ui.border })

-- Blink cmp
hl(0, "BlinkCmpMenuBorder", { fg = c.ui.border })
hl(0, "BlinkCmpDocBorder", { fg = c.ui.border })
hl(0, "BlinkCmpLabelMatch", { fg = c.ui.blue, bold = true })
hl(0, "BlinkCmpSignatureHelpBorder", { fg = c.ui.border })

-- Snacks picker
hl(0, "SnacksPickerDir", { fg = c.syntax.comment })
hl(0, "SnacksPickerBufFlags", { fg = c.syntax.comment })
hl(0, "SnacksPickerCol", { fg = c.syntax.comment })

-- Noice
hl(0, "NoiceCmdline", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopup", { fg = c.ui.yellow })
hl(0, "NoiceCmdlineIcon", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePrompt", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopupBorderCmdline", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopupTitle", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopupBorder", { fg = c.ui.yellow })
hl(0, "NoiceCmdlinePopupPrompt", { fg = c.ui.yellow })

hl(0, "NoiceFormatProgressDone", { bg = c.ui.blue, default = true })
hl(0, "NoiceLspProgressClient", { fg = c.ui.blue })
hl(0, "NoiceLspProgressSpinner", { fg = c.ui.blue })
hl(0, "NoiceLspProgressTitle", { fg = c.syntax.text })

-- Whichkey
hl(0, "WhichKeySeparator", { fg = c.syntax.comment })

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

-- Venv select
hl(0, "VenvSelectActive", { fg = c.ui.yellow })

-- Lualine path
hl(0, "LualinePathDir", { fg = c.syntax.comment })
hl(0, "LualinePathFile", { fg = c.syntax.text })
hl(0, "LualinePathModified", { fg = c.ui.orange, bold = true })
hl(0, "LualinePathOilDir", { fg = c.syntax.comment })
hl(0, "LualinePathOilCurrent", { fg = c.syntax.text })
hl(0, "LualinePathTerminal", { fg = c.syntax.text })
hl(0, "LualinePathTerminalPID", { fg = c.syntax.comment })
hl(0, "LualinePathLock", { fg = c.ui.orange })
hl(0, "LualinePathHealth", { fg = c.syntax.text })

-- Mode number color
hl(0, "ModeNumberNormal", { fg = c.ui.blue, bold = true })
hl(0, "ModeNumberInsert", { fg = c.ui.green, bold = true })
hl(0, "ModeNumberVisual", { fg = c.ui.purple, bold = true })
hl(0, "ModeNumberVLine", { fg = c.ui.purple, bold = true })
hl(0, "ModeNumberCommand", { fg = c.ui.yellow, bold = true })
hl(0, "ModeNumberTerminal", { fg = c.ui.orange, bold = true })
hl(0, "ModeNumberReplace", { fg = c.ui.red, bold = true })

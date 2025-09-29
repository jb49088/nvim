local M = {}
local colors = {
    bg = "NONE",
    fg = "#ffffff",
    red = "#af0000",
    green = "#afff00",
    yellow = "#ffff00",
    cyan = "#00ffff",
    purple = "#ff00ff",
    orange = "#d75f00",
    blue = "#00d7ff",
    gray = "#444444",
    light_gray = "#8a8a8a",
}

local highlights = {
    -- Base highlights
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.bg },
    NormalNC = { fg = colors.fg, bg = colors.bg },

    -- UI Elements
    CursorLine = { bg = colors.bg },
    LineNr = { fg = colors.light_gray },
    CursorLineNr = { fg = colors.green },
    SignColumn = { bg = colors.bg },
    NonText = { fg = colors.light_gray },
    Folded = { fg = colors.light_gray, bg = colors.bg },
    FoldColumn = { fg = colors.light_gray, bg = colors.bg },
    WinBar = { fg = colors.fg },

    -- Search and Visual
    Visual = { bg = colors.gray, fg = colors.bg },
    Search = { bg = colors.yellow, fg = colors.bg },
    IncSearch = { bg = colors.purple, fg = colors.bg },

    -- Syntax highlighting
    Constant = { fg = colors.purple },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.cyan },
    Boolean = { fg = colors.purple },
    Float = { fg = colors.cyan },

    Identifier = { fg = colors.blue },
    Function = { fg = colors.cyan },

    Statement = { fg = colors.blue },
    Conditional = { fg = colors.blue },
    Repeat = { fg = colors.blue },
    Label = { fg = colors.purple },
    Operator = { fg = colors.orange },
    Keyword = { fg = colors.blue },
    Exception = { fg = colors.purple },

    PreProc = { fg = colors.cyan },
    Include = { fg = colors.cyan },
    Define = { fg = colors.cyan },
    Macro = { fg = colors.cyan },
    PreCondit = { fg = colors.cyan },

    Type = { fg = colors.yellow },
    StorageClass = { fg = colors.blue },
    Structure = { fg = colors.purple },
    Typedef = { fg = colors.purple },

    Special = { fg = colors.purple },
    SpecialChar = { fg = colors.purple },
    Tag = { fg = colors.cyan },
    Delimiter = { fg = colors.purple },
    Comment = { fg = colors.light_gray },
    Debug = { fg = colors.red },

    -- Diagnostic groups
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue },
    DiagnosticHint = { fg = colors.cyan },
    DiagnosticOk = { fg = colors.green },

    -- Diagnostic underlines
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineOk = { undercurl = true, sp = colors.green },

    -- Added/Removed/Changed highlight groups
    Added = { fg = colors.green },
    Removed = { fg = colors.red },
    Changed = { fg = colors.orange },

    -- Status line
    StatusLine = { fg = colors.fg, bg = colors.bg },

    -- Completion menu
    Pmenu = { fg = colors.fg, bg = colors.bg },
    PmenuSel = { fg = colors.bg, bg = colors.gray },
    PmenuSbar = { bg = colors.gray },
    PmenuThumb = { bg = colors.green },

    -- Mode colors
    ModeColorNormal = { fg = colors.green },
    ModeColorInsert = { fg = colors.blue },
    ModeColorVisual = { fg = colors.purple },
    ModeColorCommand = { fg = colors.orange },
    ModeColorTerminal = { fg = colors.yellow },
    ModeColorReplace = { fg = colors.red },

    -- Indent guides
    IndentGuidesChar = { fg = colors.light_gray },

    -- Noice
    NoiceCmdline = { fg = colors.orange },
    NoiceCmdlinePopup = { fg = colors.orange },
    NoiceCmdlineIcon = { fg = colors.orange },
    NoiceCmdlinePrompt = { fg = colors.orange },
    NoiceCmdlinePopupBorderCmdline = { fg = colors.orange },
    NoiceCmdlinePopupTitle = { fg = colors.orange },
    NoiceCmdlinePopupBorder = { fg = colors.orange },
    NoiceCmdlinePopupPrompt = { fg = colors.orange },
    NoiceLspProgressClient = { fg = colors.blue },
    NoiceLspProgressSpinner = { fg = colors.cyan },
    NoiceLspProgressTitle = { fg = colors.fg },

    -- Rainbow delimiters
    RainbowDelimiters1 = { fg = colors.red },
    RainbowDelimiters2 = { fg = colors.yellow },
    RainbowDelimiters3 = { fg = colors.blue },
    RainbowDelimiters4 = { fg = colors.orange },
    RainbowDelimiters5 = { fg = colors.green },
    RainbowDelimiters6 = { fg = colors.purple },
    RainbowDelimiters7 = { fg = colors.blue },

    -- Heirline path
    HeirlinePathDir = { fg = colors.light_gray },
    HeirlinePathFile = { fg = colors.fg },
    HeirlinePathModified = { fg = colors.orange },
    HeirlinePathOilDir = { fg = colors.light_gray },
    HeirlinePathOilCurrent = { fg = colors.fg },
    HeirlinePathTerminal = { fg = colors.fg },
    HeirlinePathTerminalPID = { fg = colors.light_gray },
    HeirlinePathLock = { fg = colors.orange },
    HeirlinePathHealth = { fg = colors.cyan },

    -- Mini icons
    MiniIconsGrey = { fg = colors.light_gray },
    MiniIconsRed = { fg = colors.red },
    MiniIconsOrange = { fg = colors.orange },
    MiniIconsYellow = { fg = colors.yellow },
    MiniIconsPurple = { fg = colors.purple },
    MiniIconsBlue = { fg = colors.blue },
    MiniIconsCyan = { fg = colors.cyan },
    MiniIconsAzure = { fg = colors.cyan },
    MiniIconsGreen = { fg = colors.green },

    -- Venv picker
    VenvPickerActive = { fg = colors.yellow },

    -- Session picker
    SessionPickerActive = { fg = colors.cyan },

    -- Treesitter
    ["@variable"] = { fg = colors.fg },
    ["@variable.builtin"] = { fg = colors.purple },
    ["@variable.parameter"] = { fg = colors.orange },
    ["@variable.member"] = { fg = colors.blue },

    ["@function"] = { fg = colors.cyan },
    ["@function.builtin"] = { fg = colors.blue },
    ["@function.method"] = { fg = colors.cyan },
    ["@function.macro"] = { fg = colors.purple },

    ["@keyword"] = { fg = colors.blue },
    ["@keyword.function"] = { fg = colors.blue },
    ["@keyword.operator"] = { fg = colors.purple },
    ["@keyword.return"] = { fg = colors.red },
    ["@keyword.conditional"] = { fg = colors.blue },
    ["@keyword.repeat"] = { fg = colors.blue },
    ["@keyword.import"] = { fg = colors.cyan },

    ["@string"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.orange },
    ["@string.special"] = { fg = colors.purple },
    ["@string.regex"] = { fg = colors.orange },

    ["@character"] = { fg = colors.green },
    ["@character.special"] = { fg = colors.orange },

    ["@number"] = { fg = colors.cyan },
    ["@number.float"] = { fg = colors.cyan },

    ["@boolean"] = { fg = colors.purple },

    ["@type"] = { fg = colors.yellow },
    ["@type.builtin"] = { fg = colors.yellow },
    ["@type.definition"] = { fg = colors.yellow },

    ["@attribute"] = { fg = colors.purple },
    ["@property"] = { fg = colors.blue },

    ["@constant"] = { fg = colors.purple },
    ["@constant.builtin"] = { fg = colors.purple },
    ["@constant.macro"] = { fg = colors.purple },

    ["@constructor"] = { fg = colors.yellow },

    ["@operator"] = { fg = colors.orange },

    ["@punctuation.delimiter"] = { fg = colors.purple },
    ["@punctuation.bracket"] = { fg = colors.purple },
    ["@punctuation.special"] = { fg = colors.purple },

    ["@comment"] = { fg = colors.light_gray },
    ["@comment.todo"] = { fg = colors.yellow, bold = true },
    ["@comment.note"] = { fg = colors.blue, bold = true },
    ["@comment.warning"] = { fg = colors.orange, bold = true },
    ["@comment.error"] = { fg = colors.red, bold = true },

    ["@tag"] = { fg = colors.cyan },
    ["@tag.attribute"] = { fg = colors.orange },
    ["@tag.delimiter"] = { fg = colors.purple },

    -- Language-specific highlights
    ["@field"] = { fg = colors.blue },
    ["@namespace"] = { fg = colors.blue },
    ["@symbol"] = { fg = colors.purple },

    -- Markup (for markdown, etc.)
    ["@markup.heading"] = { fg = colors.blue, bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.link"] = { fg = colors.cyan },
    ["@markup.link.url"] = { fg = colors.green, underline = true },
    ["@markup.raw"] = { fg = colors.green },
    ["@markup.list"] = { fg = colors.purple },

    -- LSP Semantic tokens
    ["@lsp.type.class"] = { fg = colors.yellow },
    ["@lsp.type.decorator"] = { fg = colors.purple },
    ["@lsp.type.enum"] = { fg = colors.yellow },
    ["@lsp.type.enumMember"] = { fg = colors.purple },
    ["@lsp.type.function"] = { fg = colors.cyan },
    ["@lsp.type.interface"] = { fg = colors.yellow },
    ["@lsp.type.macro"] = { fg = colors.purple },
    ["@lsp.type.method"] = { fg = colors.cyan },
    ["@lsp.type.namespace"] = { fg = colors.blue },
    ["@lsp.type.parameter"] = { fg = colors.orange },
    ["@lsp.type.property"] = { fg = colors.blue },
    ["@lsp.type.struct"] = { fg = colors.yellow },
    ["@lsp.type.type"] = { fg = colors.yellow },
    ["@lsp.type.typeParameter"] = { fg = colors.orange },
    ["@lsp.type.variable"] = { fg = colors.fg },

    -- Modifiers (these combine with the above)
    ["@lsp.mod.declaration"] = {},
    ["@lsp.mod.definition"] = {},
    ["@lsp.mod.readonly"] = {},
    ["@lsp.mod.static"] = {},
    ["@lsp.mod.deprecated"] = { fg = colors.light_gray },
    ["@lsp.mod.abstract"] = {},
    ["@lsp.mod.async"] = {},
    ["@lsp.mod.modification"] = { underline = true },
    ["@lsp.mod.documentation"] = { fg = colors.light_gray },

    -- Type-specific modifiers (examples)
    ["@lsp.typemod.function.declaration"] = { fg = colors.cyan },
    ["@lsp.typemod.function.readonly"] = { fg = colors.cyan },
    ["@lsp.typemod.variable.readonly"] = { fg = colors.purple },
    ["@lsp.typemod.variable.constant"] = { fg = colors.purple },
    ["@lsp.typemod.variable.static"] = { fg = colors.purple },
    ["@lsp.typemod.property.readonly"] = { fg = colors.blue },
    ["@lsp.typemod.class.declaration"] = { fg = colors.yellow },

    -- Language-specific semantic tokens
    -- Python
    ["@lsp.type.selfParameter.python"] = { fg = colors.purple },
    ["@lsp.type.clsParameter.python"] = { fg = colors.purple },

    -- Rust
    ["@lsp.type.lifetime.rust"] = { fg = colors.orange },
    ["@lsp.type.builtinType.rust"] = { fg = colors.yellow },
    ["@lsp.typemod.lifetime.static.rust"] = { fg = colors.red },

    -- TypeScript/JavaScript
    ["@lsp.type.interface.typescript"] = { fg = colors.yellow },
    ["@lsp.type.interface.typescriptreact"] = { fg = colors.yellow },
}

function M.colorscheme()
    vim.cmd("highlight clear")
    vim.cmd("syntax reset")
    vim.o.background = "dark"
    vim.g.colors_name = "colorscheme"

    for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
    end
end

M.colorscheme()

return M

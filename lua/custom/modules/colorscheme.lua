local M = {}
local colors = {
    white = "#ffffff",
    black = "#000000",
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
    ------------
    --- BASE ---
    ------------
    ColorColumn = {},
    Conceal = { bg = colors.gray },
    Cursor = {},
    CurSearch = { bg = colors.purple, fg = colors.black },
    lCursor = {},
    CursorIM = {},
    CursorColumn = {},
    CursorLine = {},
    Directory = { fg = colors.blue },
    DiffAdd = { fg = colors.black, bg = colors.green },
    DiffChange = { fg = colors.black, bg = colors.orange },
    DiffDelete = { fg = colors.black, bg = colors.red },
    DiffText = { fg = colors.black, bg = colors.yellow },
    EndOfBuffer = {},
    TermCursor = {},
    TermCursorNC = {},
    ErrorMsg = { fg = colors.red },
    VertSplit = {},
    Folded = { fg = colors.light_gray },
    FoldColumn = { fg = colors.light_gray },
    SignColumn = {},
    IncSearch = { bg = colors.purple, fg = colors.black },
    Substitute = { bg = colors.orange, fg = colors.black },
    LineNr = { fg = colors.light_gray },
    LineNrAbove = { fg = colors.light_gray },
    LineNrBelow = { fg = colors.light_gray },
    CursorLineNr = { fg = colors.green },
    CursorLineFold = {},
    CursorLineSign = {},
    MatchParen = { fg = colors.orange, bold = true },
    ModeMsg = { fg = colors.white, bold = true },
    MsgArea = {},
    MsgSeparator = {},
    MoreMsg = {},
    NonText = { fg = colors.light_gray },
    Normal = { fg = colors.white },
    NormalFloat = {},
    FloatBorder = {},
    FloatTitle = { fg = colors.purple, bold = true },
    NormalNC = {},
    Pmenu = {},
    PmenuSel = { bg = colors.gray },
    PmenuKind = {},
    PmenuKindSel = {},
    PmenuExtra = {},
    PmenuExtraSel = {},
    PmenuSbar = {},
    PmenuThumb = { bg = colors.green },
    Question = { fg = colors.purple },
    QuickFixLine = { bg = colors.orange, fg = colors.black },
    Search = { fg = colors.black, bg = colors.yellow },
    SpecialKey = {},
    SpellBad = { sp = colors.red, undercurl = true },
    SpellCap = { sp = colors.yellow, undercurl = true },
    SpellLocal = { sp = colors.blue, undercurl = true },
    SpellRare = { sp = colors.green, undercurl = true },
    StatusLine = {},
    StatusLineNC = {},
    TabLine = {},
    TabLineFill = {},
    TabLineSel = {},
    Title = { fg = colors.purple, bold = true },
    Visual = { bg = colors.gray },
    VisualNOS = { bg = colors.gray },
    WarningMsg = { fg = colors.yellow },
    Whitespace = {},
    Winseparator = {},
    WildMenu = {},
    WinBar = {},
    WinBarNC = {},

    --------------
    --- SYNTAX ---
    --------------
    Comment = { fg = colors.light_gray },

    Constant = { fg = colors.yellow },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.yellow },
    Boolean = { fg = colors.orange },
    Float = { fg = colors.yellow },

    Identifier = {},
    Function = { fg = colors.blue },

    Statement = { fg = colors.purple },
    Conditional = { fg = colors.purple },
    Repeat = { fg = colors.purple },
    Label = { fg = colors.blue },
    Operator = {},
    Keyword = { fg = colors.purple },
    Exception = { fg = colors.purple },

    PreProc = { fg = colors.yellow },
    Include = { fg = colors.purple },
    Define = { fg = colors.purple },
    Macro = { fg = colors.orange },
    PreCondit = { fg = colors.blue },

    Type = { fg = colors.blue },
    StorageClass = { fg = colors.blue },
    Structure = { fg = colors.yellow },
    Typedef = { fg = colors.yellow },

    Special = { fg = colors.blue },
    SpecialChar = { fg = colors.blue },
    Tag = { fg = colors.blue },
    Delimiter = { fg = colors.blue },
    SpecialComment = { fg = colors.light_gray },
    Debug = { fg = colors.blue },

    Underlined = { fg = colors.cyan, underline = true },
    Ignore = {},
    Error = { fg = colors.red },
    Todo = { fg = colors.yellow },

    ------------
    --- LSP  ---
    ------------
    LspReferenceText = {},
    LspReferenceRead = {},
    LspReferenceWrite = {},
    LspCodeLens = { fg = colors.light_gray },
    LspCodeLensSeparator = { fg = colors.light_gray },
    LspSignatureActiveParameter = { bg = colors.gray },

    -------------------
    --- DIAGNOSTIC  ---
    -------------------
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue },
    DiagnosticHint = { fg = colors.cyan },
    DiagnosticOk = { fg = colors.green },
    DiagnosticVirtualTextError = { fg = colors.red },
    DiagnosticVirtualTextWarn = { fg = colors.yellow },
    DiagnosticVirtualTextInfo = { fg = colors.blue },
    DiagnosticVirtualTextHint = { fg = colors.cyan },
    DiagnosticVirtualTextOk = { fg = colors.green },
    DiagnosticUnderlineError = { sp = colors.red, undercurl = true },
    DiagnosticUnderlineWarn = { sp = colors.yellow, undercurl = true },
    DiagnosticUnderlineInfo = { sp = colors.blue, undercurl = true },
    DiagnosticUnderlineHint = { sp = colors.cyan, undercurl = true },
    DiagnosticUnderlineOk = { sp = colors.green, undercurl = true },
    DiagnosticFloatingError = { fg = colors.red },
    DiagnosticFloatingWarn = { fg = colors.yellow },
    DiagnosticFloatingInfo = { fg = colors.blue },
    DiagnosticFloatingHint = { fg = colors.cyan },
    DiagnosticFloatingOk = { fg = colors.green },
    DiagnosticSignError = { fg = colors.red },
    DiagnosticSignWarn = { fg = colors.yellow },
    DiagnosticSignInfo = { fg = colors.blue },
    DiagnosticSignHint = { fg = colors.cyan },
    DiagnosticSignOk = { fg = colors.green },

    -------------------
    --- TREESITTER  ---
    -------------------
    ["@text.literal"] = { fg = colors.red },
    ["@text.reference"] = { fg = colors.yellow },
    ["@text.title"] = { fg = colors.white },
    ["@text.uri"] = { fg = colors.blue, underline = true, italic = true },
    ["@text.underline"] = { fg = colors.white, underline = true },
    ["@text.todo"] = { fg = colors.yellow },
    ["@comment"] = { fg = colors.light_gray },
    ["@punctuation"] = { fg = colors.blue },
    ["@constant"] = { fg = colors.yellow },
    ["@constant.builtin"] = { fg = colors.yellow },
    ["@constant.macro"] = { fg = colors.yellow },
    ["@define"] = { fg = colors.purple },
    ["@macro"] = { fg = colors.orange },
    ["@string"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.red },
    ["@string.special"] = { fg = colors.green },
    ["@character"] = { fg = colors.green },
    ["@character.special"] = { fg = colors.blue },
    ["@number"] = { fg = colors.yellow },
    ["@boolean"] = { fg = colors.orange },
    ["@float"] = { fg = colors.yellow },
    ["@function"] = { fg = colors.blue },
    ["@function.builtin"] = { fg = colors.cyan },
    ["@function.macro"] = { fg = colors.orange },
    ["@parameter"] = { fg = colors.orange },
    ["@method"] = { fg = colors.blue },
    ["@field"] = { fg = colors.red },
    ["@property"] = { fg = colors.orange },
    ["@constructor"] = { fg = colors.blue },
    ["@conditional"] = { fg = colors.purple },
    ["@repeat"] = { fg = colors.purple },
    ["@label"] = { fg = colors.blue },
    ["@operator"] = { fg = colors.white },
    ["@keyword"] = { fg = colors.purple },
    ["@exception"] = { fg = colors.purple },
    ["@variable"] = { fg = colors.white },
    ["@type"] = { fg = colors.blue },
    ["@type.definition"] = { fg = colors.blue },
    ["@storageclass"] = { fg = colors.blue },
    ["@structure"] = { fg = colors.yellow },
    ["@namespace"] = { fg = colors.purple },
    ["@include"] = { fg = colors.purple },
    ["@preproc"] = { fg = colors.yellow },
    ["@debug"] = { fg = colors.blue },
    ["@tag"] = { fg = colors.blue },

    ---------------
    --- PLUGINS ---
    ---------------
    -- Git signs
    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.orange },
    GitSignsDelete = { fg = colors.red },

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

    -- Mode colors
    ModeColorNormal = { fg = colors.green },
    ModeColorInsert = { fg = colors.blue },
    ModeColorVisual = { fg = colors.purple },
    ModeColorCommand = { fg = colors.orange },
    ModeColorTerminal = { fg = colors.yellow },
    ModeColorReplace = { fg = colors.red },

    -- Blink cmp
    BlinkCmpLabelMatch = { fg = colors.green, bold = true },

    -- Snacks
    SnacksPickerMatch = { fg = colors.green, bold = true },
    SnacksPickerPrompt = { fg = colors.purple },

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
    NoiceLspProgressTitle = { fg = colors.white },

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
    HeirlinePathFile = { fg = colors.white },
    HeirlinePathModified = { fg = colors.orange },
    HeirlinePathOilDir = { fg = colors.light_gray },
    HeirlinePathOilCurrent = { fg = colors.white },
    HeirlinePathTerminal = { fg = colors.white },
    HeirlinePathTerminalPID = { fg = colors.light_gray },
    HeirlinePathLock = { fg = colors.orange },
    HeirlinePathHealth = { fg = colors.cyan },
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

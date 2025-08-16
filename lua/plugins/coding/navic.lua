-- return {
--     "SmiteshP/nvim-navic",
-- enabled = false,
-- event = "VeryLazy", -- This is a lazy.nvim event, not part of navic's default
-- requires = "neovim/nvim-lspconfig",
-- config = function()
-- Function to get mini.icons for LSP kinds
-- local function get_mini_icon(kind)
--     local icon, _, _ = require("mini.icons").get("lsp", kind)
--     return icon .. " "
-- end

-- require("nvim-navic").setup({
-- icons = {
--     File = get_mini_icon("File"),
--     Module = get_mini_icon("Module"),
--     Namespace = get_mini_icon("Namespace"),
--     Package = get_mini_icon("Package"),
--     Class = get_mini_icon("Class"),
--     Method = get_mini_icon("Method"),
--     Property = get_mini_icon("Property"),
--     Field = get_mini_icon("Field"),
--     Constructor = get_mini_icon("Constructor"),
--     Enum = get_mini_icon("Enum"),
--     Interface = get_mini_icon("Interface"),
--     Function = get_mini_icon("Function"),
--     Variable = get_mini_icon("Variable"),
--     Constant = get_mini_icon("Constant"),
--     String = get_mini_icon("String"),
--     Number = get_mini_icon("Number"),
--     Boolean = get_mini_icon("Boolean"),
--     Array = get_mini_icon("Array"),
--     Object = get_mini_icon("Object"),
--     Key = get_mini_icon("Key"),
--     Null = get_mini_icon("Null"),
--     EnumMember = get_mini_icon("EnumMember"),
--     Struct = get_mini_icon("Struct"),
--     Event = get_mini_icon("Event"),
--     Operator = get_mini_icon("Operator"),
--     TypeParameter = get_mini_icon("TypeParameter"),
-- },
-- lsp = {
--     auto_attach = true,
-- },
-- highlight = true,
-- separator = "  ",
-- lazy_update_context = true,
-- })

-- Link navic highlight groups to mini.icons color groups
-- local lsp_kinds = {
--     "File",
--     "Module",
--     "Namespace",
--     "Package",
--     "Class",
--     "Method",
--     "Property",
--     "Field",
--     "Constructor",
--     "Enum",
--     "Interface",
--     "Function",
--     "Variable",
--     "Constant",
--     "String",
--     "Number",
--     "Boolean",
--     "Array",
--     "Object",
--     "Key",
--     "Null",
--     "EnumMember",
--     "Struct",
--     "Event",
--     "Operator",
--     "TypeParameter",
-- }

-- for _, kind in ipairs(lsp_kinds) do
--     local _, mini_hl, _ = require("mini.icons").get("lsp", kind)
--     local navic_hl = "NavicIcons" .. kind
--     if mini_hl then
--         vim.api.nvim_set_hl(0, navic_hl, { link = mini_hl })
--     end
-- end

-- Set up winbar to show navic breadcrumbs
--         vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
--     end,
-- }

return {
    "SmiteshP/nvim-navic",
    enabled = false,
    dependencies = "neovim/nvim-lspconfig", -- navic requires lspconfig
    config = function()
        require("nvim-navic").setup({
            -- To auto-attach to all LSP servers (convenient for LazyVim):
            lsp = {
                auto_attach = true,
            },
        })
        -- Set winbar after navic is set up
        vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
    end,
}

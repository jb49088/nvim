return {
    "Bekaboo/dropbar.nvim",
    enabled = false,
    dependencies = {},
    config = function()
        require("dropbar").setup({
            -- icons = {
            --     ui = {
            --         bar = {
            --             separator = "  ",
            --         },
            --     },
            --     kinds = {
            --         -- Overide to mini.icons when available
            --         symbols = {
            --             Array = " ",
            --             Boolean = " ",
            --             Class = " ",
            --             Color = " ",
            --             Constant = " ",
            --             Constructor = " ",
            --             Enum = " ",
            --             EnumMember = " ",
            --             Event = " ",
            --             Field = " ",
            --             File = " ",
            --             Folder = " ",
            --             Function = " ",
            --             Interface = " ",
            --             Keyword = " ",
            --             Method = " ",
            --             Module = " ",
            --             Namespace = "󰅩 ",
            --             Null = " ",
            --             Number = " ",
            --             Object = " ",
            --             Operator = " ",
            --             Package = " ",
            --             Property = " ",
            --             Reference = " ",
            --             Snippet = " ",
            --             String = " ",
            --             Struct = " ",
            --             Text = " ",
            --             TypeParameter = " ",
            --             Unit = " ",
            --             Value = " ",
            --             Variable = " ",
            --         },
            --     },
            -- },
            -- bar = {
            --     sources = function(buf, _)
            --         local sources = require("dropbar.sources")
            --         local utils = require("dropbar.utils")
            --         -- Custom path source that only shows filename
            --         local custom_path = {
            --             get_symbols = function(buf, win, cursor)
            --                 local symbols = sources.path.get_symbols(buf, win, cursor)
            --                 return symbols and #symbols > 0 and { symbols[#symbols] } or {}
            --             end,
            --         }
            --         if vim.bo[buf].ft == "markdown" then
            --             return { custom_path, sources.markdown }
            --         end
            --         if vim.bo[buf].buftype == "terminal" then
            --             return { sources.terminal }
            --         end
            --         return {
            --             custom_path,
            --             utils.source.fallback({
            --                 sources.lsp,
            --                 sources.treesitter,
            --             }),
            --         }
            --     end,
            -- },
        })
    end,
}

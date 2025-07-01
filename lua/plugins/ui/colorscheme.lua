-- return {
--     "navarasu/onedark.nvim",
--     priority = 1000,
--     config = function()
--         require("onedark").setup({
--             style = "dark",
--             code_style = {
--                 comments = "none",
--             },
--             diagnostics = {
--                 darker = false,
--             },
--         })
--         require("onedark").load()
--         require("core.highlights")
--     end,
-- }

-- return {
--     "olimorris/onedarkpro.nvim",
--     priority = 1000,
--     config = function()
--         vim.cmd("colorscheme onedark_vivid")
--         require("core.highlights")
--     end,
-- }

return {
    "AstroNvim/astrotheme",
    priority = 1000,
    config = function()
        require("astrotheme").setup({
            palette = "astrodark",
            style = {
                inactive = false,
                italic_comments = false,
            },
        })
        vim.cmd("colorscheme astrotheme")
        require("core.highlights")
    end,
}

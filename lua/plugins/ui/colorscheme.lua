-- ================================================================================
-- =                                  ASTROTHEME                                  =
-- ================================================================================

return {
    "AstroNvim/astrotheme",
    -- enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
        require("astrotheme").setup({
            palette = "astrodark",
            style = {
                -- transparent = true,
                inactive = false,
                italic_comments = false,
            },
        })
        vim.cmd("colorscheme astrotheme")

        vim.schedule(function()
            require("custom.extensions.highlights")
        end)
    end,
}

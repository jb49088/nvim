return {
    "AstroNvim/astrotheme",
    priority = 1000,
    config = function()
        require("astrotheme").setup({
            palette = "astrodark",
            style = {
                transparent = true,
                inactive = false,
                italic_comments = false,
            },
        })
        vim.cmd("colorscheme astrotheme")
        require("custom.integrations.highlights")
    end,
}

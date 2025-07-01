return {
    "Aasim-A/scrollEOF.nvim",
    event = { "CursorMoved", "WinScrolled" },
    config = function()
        require("scrollEOF").setup({
            insert_mode = true,
            disabled_modes = { "t", "nt" },
        })
    end,
}

-- ================================================================================
-- =                            NVIM-HIGHLIGHT-COLORS                             =
-- ================================================================================

return {
    "brenoprata10/nvim-highlight-colors",
    enabled = false, -- https://github.com/brenoprata10/nvim-highlight-colors/issues/170
    event = "VeryLazy",
    config = function()
        require("nvim-highlight-colors").setup({})
    end,
}

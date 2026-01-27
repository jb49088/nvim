-- ================================================================================
-- =                                   OIL.NVIM                                   =
-- ================================================================================

return {
    "stevearc/oil.nvim",
    cmd = "Oil",
    opts = {
        keymaps = {
            ["+"] = "actions.select",
        },
        delete_to_trash = true,
        watch_for_changes = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
            show_hidden = true,
        },
        float = {
            max_width = 0.8,
            max_height = 0.8,
        },
    },
    -- stylua: ignore
    keys = { { "<leader>o", function() vim.cmd("Oil --float") end, desc = "Oil", mode = "n" } },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}

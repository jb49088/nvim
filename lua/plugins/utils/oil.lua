-- ================================================================================
-- =                                   OIL.NVIM                                   =
-- ================================================================================

return {
    "stevearc/oil.nvim",
    -- enabled = false,
    cmd = "Oil",
    opts = {
        keymaps = {
            ["+"] = "actions.select",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
            show_hidden = true,
        },
        win_options = {
            winbar = "",
        },
    },
    -- stylua: ignore
    keys = {
        {
            "<leader>o",
            function()
                vim.cmd("vsplit")
                vim.cmd("wincmd H")
                vim.cmd("vertical resize 30")
                vim.wo.winfixwidth = true
                require("oil").open()
            end,
            desc = "Oil",
            mode = "n"
        }
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}

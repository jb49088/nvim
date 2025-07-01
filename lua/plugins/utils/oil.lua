return {
    "stevearc/oil.nvim",
    opts = {
        keymaps = {
            ["_"] = "actions.select",
            ["g_"] = "actions.open_cwd",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
            show_hidden = true,
        },
        float = {
            max_width = 135,
            max_height = 29,
        },
    },
    lazy = false, -- recommended for oil
    keys = {
        {
            "<leader>o",
            function()
                if vim.bo.filetype == "oil" then
                    vim.cmd("close")
                else
                    require("oil").open_float()
                end
            end,
            desc = "Oil",
            mode = "n",
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}

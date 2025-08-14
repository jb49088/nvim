return {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    opts = {
        indent = {
            char = "│",
        },
        scope = {
            enabled = false,
            show_start = false,
            show_end = false,
        },
    },
    config = function(_, opts)
        local ibl = require("ibl")
        ibl.setup(opts)

        Snacks.toggle({
            name = "Indent Guides",
            get = function()
                return require("ibl.config").get_config(0).enabled
            end,
            set = function(enabled)
                local config = vim.tbl_deep_extend("force", opts, { enabled = enabled })
                ibl.setup(config)
            end,
        }):map("<leader>ug")
    end,
}

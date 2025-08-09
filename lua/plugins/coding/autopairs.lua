return {
    "windwp/nvim-autopairs",
    -- enabled = false,
    event = "VeryLazy",
    config = function()
        local autopairs = require("nvim-autopairs")
        autopairs.setup({})
        -- Create toggle for nvim-autopairs
        Snacks.toggle({
            name = "Auto Pairing",
            get = function()
                return not vim.g.autopairs_disable
            end,
            set = function(state)
                if state then
                    autopairs.enable()
                    vim.g.autopairs_disable = false
                else
                    autopairs.disable()
                    vim.g.autopairs_disable = true
                end
            end,
        }):map("<leader>ua")
    end,
}

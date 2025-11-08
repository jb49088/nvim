-- ================================================================================
-- =                                NVIM-AUTOPAIRS                                =
-- ================================================================================

return {
    "windwp/nvim-autopairs",
    -- enabled = false,
    event = "VeryLazy",
    config = function()
        local autopairs = require("nvim-autopairs")
        local Rule = require("nvim-autopairs.rule")
        local cond = require("nvim-autopairs.conds")
        autopairs.setup({})

        -- -- Add custom rules for Python quotes inside brackets, braces, and parentheses
        -- autopairs.add_rules({
        --     Rule("'", "'", "python"):with_pair(cond.before_regex("[%[%{%(]")),
        --     Rule('"', '"', "python"):with_pair(cond.before_regex("[%[%{%(]")),
        -- })

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

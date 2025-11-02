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

        -- Add custom rules for Python f-strings
        autopairs.add_rules({
            -- Single quotes in Python, specifically inside brackets
            Rule("'", "'", "python")
                :with_pair(cond.before_regex("[%[%{].*")) -- if there's a [ or { before
                :with_pair(cond.after_regex(".*[%]%}]")), -- and a ] or } after

            -- Double quotes in Python, specifically inside brackets
            Rule('"', '"', "python")
                :with_pair(cond.before_regex("[%[%{].*")) -- if there's a [ or { before
                :with_pair(cond.after_regex(".*[%]%}]")), -- and a ] or } after
        })

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

return {
    "echasnovski/mini.pairs",
    -- enabled = false,
    event = "VeryLazy",
    config = function()
        local pairs = require("mini.pairs")
        local opts = {
            modes = {
                insert = true,
                command = true,
                terminal = false,
            },
            -- skip autopair when next character is one of these
            skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
            -- skip autopair when the cursor is inside these treesitter nodes
            skip_ts = { "string" },
            -- skip autopair when next character is closing pair
            -- and there are more closing pairs than opening pairs
            skip_unbalanced = true,
            -- better deal with markdown code blocks
            markdown = true,
        }
        pairs.setup(opts)
        -- Create toggle for mini.pairs
        Snacks.toggle({
            name = "Auto Pairing",
            get = function()
                return not vim.g.minipairs_disable
            end,
            set = function(state)
                vim.g.minipairs_disable = not state
            end,
        }):map("<leader>ua")
    end,
}

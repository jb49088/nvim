return {
    "mrjones2014/smart-splits.nvim",
    lazy = true,
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
        { "<C-h>", function() require("smart-splits").move_cursor_left() end, { silent = true, desc = "navigate left" } },
        { "<C-j>", function() require("smart-splits").move_cursor_down() end, { silent = true, desc = "navigate down" } },
        { "<C-k>", function() require("smart-splits").move_cursor_up() end, { silent = true, desc = "navigate up" } },
        { "<C-l>", function() require("smart-splits").move_cursor_right() end, { silent = true, desc = "navigate right" } },

        { "<A-h>", function() require("smart-splits").resize_left() end, { silent = true, desc = "resize left" } },
        { "<A-j>", function() require("smart-splits").resize_down() end, { silent = true, desc = "resize down" } },
        { "<A-k>", function() require("smart-splits").resize_up() end, { silent = true, desc = "resize up" } },
        { "<A-l>", function() require("smart-splits").resize_right() end, { silent = true, desc = "resize right" } },
    },
    opts = {
        -- Enable Zellij integration
        multiplexer_integration = "zellij",
    },
}

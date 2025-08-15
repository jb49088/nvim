return {
    "rcarriga/nvim-notify",
    -- enabled = false,
    opts = {
        icons = {
            DEBUG = "",
            ERROR = "󰅚",
            INFO = "󰋽",
            TRACE = "",
            WARN = "󰀪",
        },
        stages = "static",
    },
    -- stylua: ignore
    keys = {
        { "<leader>un", function() require("notify").dismiss({ silent = true, pending = true }) end, desc = "Dismiss All Notifications" },
    },
}

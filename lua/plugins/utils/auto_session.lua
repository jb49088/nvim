local session_picker = require("custom.integrations.session_picker")

return {
    "rmagatti/auto-session",
    lazy = false,
    keys = {
        { "<leader>Sr", "<cmd>SessionRestore<CR>", desc = "Restore Session" },
        -- { "<leader>SS", "<cmd>Autosession search<CR>", desc = "Search Session" },
        { "<leader>SS", session_picker, desc = "Search Session" },
        {
            "<leader>Ss",
            function()
                vim.ui.input({ prompt = "Session Name: " }, function(input)
                    if input and input ~= "" then
                        vim.cmd("SessionSave " .. input)
                    end
                end)
            end,
            desc = "Save Session",
        },
    },
    opts = {
        show_auto_restore_notif = true,
    },
    config = function(_, opts)
        require("auto-session").setup(opts)

        Snacks.toggle({
            name = "Session Autosave",
            get = function()
                return require("auto-session.config").auto_save
            end,
            set = function()
                local config = require("auto-session.config")
                config.auto_save = not config.auto_save
            end,
        }):map("<leader>Sa")
    end,
}

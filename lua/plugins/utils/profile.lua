return {
    "stevearc/profile.nvim",
    enabled = false,
    config = function()
        local function profile_session_manager()
            local prof = require("profile")
            if prof.is_recording() then
                prof.stop()
                prof.export("session_profile.json")
                vim.notify("Session profile saved")
            else
                prof.start("custom.modules.session_manager")
                vim.notify("Profiling session manager only")
            end
        end

        vim.keymap.set("", "<F1>", profile_session_manager)
    end,
}

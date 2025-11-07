-- ================================================================================
-- =                            ULTIMATE-AUTOPAIR.NVIM                            =
-- ================================================================================

return {
    "altermo/ultimate-autopair.nvim",
    event = { "InsertEnter", "CmdlineEnter" },
    branch = "v0.6",
    opts = {},
    config = function()
        local ua = require("ultimate-autopair")
        ua.setup({})

        -- Create toggle for ultimate-autopair
        Snacks.toggle({
            name = "Auto Pairing",
            get = function()
                return ua.isenabled()
            end,
            set = function(state)
                if state then
                    ua.enable()
                else
                    ua.disable()
                end
            end,
        }):map("<leader>ua")
    end,
}

-- ================================================================================
-- =                            ULTIMATE-AUTOPAIR.NVIM                            =
-- ================================================================================

return {
    "altermo/ultimate-autopair.nvim",
    event = { "InsertEnter", "CmdlineEnter" },
    branch = "v0.6",
    config = function()
        local ua = require("ultimate-autopair")

        ua.setup({
            extensions = {
                cmdtype = {
                    skip = { "@", "-" }, -- removed '/' and '?' to enable search autopair
                },
            },
            -- Add cmdline-specific quote pairs with high priority
            { '"', '"', imap = false, cmap = true, p = 200 },
            { "'", "'", imap = false, cmap = true, p = 200 },
        })

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

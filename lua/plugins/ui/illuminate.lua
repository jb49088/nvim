-- ================================================================================
-- =                                VIM-ILLUMINATE                                =
-- ================================================================================

return {
    "RRethy/vim-illuminate",
    -- enabled = false,
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        delay = 200,
        providers = { "lsp", "treesitter", "regex" },
        filetypes_denylist = {
            "bigfile",
            "snacks_picker_list",
            "snacks_picker_preview",
            "snacks_picker_input",
            "oil",
            "noice",
        },
    },
    config = function(_, opts)
        local illuminate = require("illuminate")
        illuminate.configure(opts)

        Snacks.toggle({
            name = "Illuminate",
            get = function()
                return not require("illuminate.engine").is_paused()
            end,
            set = function(enabled)
                if enabled then
                    illuminate.resume()
                else
                    illuminate.pause()
                end
            end,
        }):map("<leader>ui")

        -- turn off in inactive windows
        vim.api.nvim_create_autocmd("WinLeave", {
            callback = function()
                illuminate.pause()
            end,
        })

        vim.api.nvim_create_autocmd("WinEnter", {
            callback = function()
                illuminate.resume()
            end,
        })
    end,
}

return {
    {
        "RRethy/vim-illuminate",
        opts = {
            delay = 300,
            providers = { "lsp", "treesitter", "regex" },
            filetypes_denylist = {
                "snacks_picker_list",
                "snacks_picker_preview",
                "snacks_picker_input",
                "oil",
            },
        },
        config = function(_, opts)
            require("illuminate").configure(opts)

            Snacks.toggle({
                name = "Illuminate",
                get = function()
                    return not require("illuminate.engine").is_paused()
                end,
                set = function(enabled)
                    local m = require("illuminate")
                    if enabled then
                        m.resume()
                    else
                        m.pause()
                    end
                end,
            }):map("<leader>ux")
        end,
    },
}

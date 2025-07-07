local lualine_path = require("custom.integrations.lualine_path")

return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = {
        "bwpge/lualine-pretty-path",
    },

    config = function()
        local c = require("astrotheme.lib.util").set_palettes(require("astrotheme").config)

        local LualineTheme = {
            normal = {
                a = { fg = c.ui.base, bg = c.syntax.blue, gui = "bold" },
                b = { fg = c.ui.text_active, bg = c.ui.statusline },
                c = { fg = c.ui.text_active, bg = c.ui.statusline },
            },
            insert = { a = { fg = c.ui.base, bg = c.ui.green, gui = "bold" } },
            visual = { a = { fg = c.ui.base, bg = c.ui.purple, gui = "bold" } },
            replace = { a = { fg = c.ui.base, bg = c.ui.red, gui = "bold" } },
            command = { a = { fg = c.ui.base, bg = c.ui.yellow, gui = "bold" } },
            terminal = { a = { fg = c.ui.base, bg = c.ui.orange, gui = "bold" } },
            inactive = {
                a = { fg = c.ui.text_inactive, bg = c.ui.statusline, gui = "bold" },
                b = { fg = c.ui.text_inactive, bg = c.ui.statusline, gui = "bold" },
                c = { fg = c.ui.text_inactive, bg = c.ui.statusline, gui = "bold" },
            },
        }

        require("lualine").setup({
            options = {
                theme = LualineTheme,
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                globalstatus = true,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    {
                        "branch",
                        icon = "󰘬",
                    },
                    {
                        "diff",
                        symbols = {
                            added = " ",
                            modified = " ",
                            removed = " ",
                        },
                        source = function()
                            local gitsigns = vim.b.gitsigns_status_dict
                            if gitsigns then
                                return {
                                    added = gitsigns.added,
                                    modified = gitsigns.changed,
                                    removed = gitsigns.removed,
                                }
                            end
                        end,
                    },
                    "diagnostics",
                },
                lualine_c = { { lualine_path.component } },
                -- lualine_c = {
                --     {
                --         "pretty_path",
                --         highlights = {
                --             directory = "LualinePathDir",
                --             filename = "LualinePathFile",
                --             modified = "LualinePathModified",
                --         },
                --     },
                -- },
                lualine_x = { "encoding", "fileformat" },
                lualine_y = {
                    { "progress", separator = " ", padding = { left = 1, right = 0 } },
                    { "location", padding = { left = 0, right = 1 } },
                },
                lualine_z = {
                    function()
                        return " " .. os.date("%R")
                    end,
                },
            },
        })
    end,
}

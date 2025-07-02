return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = {
        "bwpge/lualine-pretty-path",
    },
    config = function()
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
                lualine_c = {
                    {
                        "pretty_path",
                        highlights = {
                            directory = "PrettyPathDir",
                            filename = "PrettyPathFile",
                            modified = "PrettyPathModified",
                        },
                    },
                },
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

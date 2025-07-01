return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    -- test
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
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    {
                        "pretty_path",
                        highlights = {
                            directory = "PrettyPathDir",
                            modified = "PrettyPathModified",
                        },
                    },
                },
                lualine_x = { "encoding", "fileformat" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        })
    end,
}

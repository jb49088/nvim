local tabs_picker = require("custom.extensions.tabs_picker")

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        --- BUFDELETE ---
        bufdelete = { enabled = true },

        --- INDENT ---
        indent = {
            enabled = false,
            scope = {
                enabled = true,
            },
            chunk = {
                enabled = true,
                only_current = true,
                char = {
                    corner_top = "╭",
                    corner_bottom = "╰",
                    arrow = "",
                },
            },
        },

        --- NOTIFY ---
        notifier = { enabled = true },

        --- PICKER ---
        picker = {
            enabled = true,
            layouts = {
                default = {
                    layout = {
                        -- backdrop = false,
                    },
                },
                select = {},
            },
            win = {
                preview = {
                    wo = {
                        wrap = false,
                    },
                },
                input = {
                    keys = {
                        ["<Esc>"] = { "close", mode = { "i", "n" } },
                    },
                },
            },
            sources = {
                buffers = {
                    sort_lastused = false,
                },
                command_history = {
                    layout = { preset = "select" },
                },
                search_history = {
                    layout = { preset = "select" },
                },
                icons = {
                    layout = { preset = "select" },
                },
                tabs = tabs_picker,
            },
        },

        --- SCROLL ---
        scroll = { enabled = true },
    },
    -- stylua: ignore
    keys = {
        -- Top Pickers & Explorer
        { "<leader><leader>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
        { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
        { "<leader>/", function() Snacks.picker.lines({ layout = "select", on_show = function() end, title = "Current Buffer Search" }) end, desc = "Search Current Buffer"},
        { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
        -- buffer
        { "<leader>bc", function() Snacks.bufdelete() end, desc = "Close Buffer" },
        { "<leader>bo", function() local visible_bufs = {} for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local buf = vim.api.nvim_win_get_buf(win) visible_bufs[buf] = true end Snacks.bufdelete.delete({ filter = function(buf) return not visible_bufs[buf] end }) end, desc = "Close Other Buffers" },
        -- find
        { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Config Files" }) end, desc = "Find Config Files" },
        { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
        { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
        { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
        { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
        -- git
        { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
        { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
        { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
        { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
        { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
        { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
        { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
        -- Grep
        { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
        { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
        { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
        -- search
        { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
        { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
        { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
        { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
        { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
        { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
        { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
        { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
        { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
        { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
        { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
        { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
        { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
        { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
        { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
        { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
        { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification History" },
        { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
        { "<leader>sP", function() Snacks.picker.pickers() end, desc = "Pickers"},
        { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
        { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
        { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
        { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
        { "<leader>ts", function() Snacks.picker.pick("tabs") end, desc = "Search Tabs" },
        -- other
        { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    },
    config = function(_, opts)
        require("snacks").setup(opts)

        vim.g.snacks_animate = false -- Disable snacks animations by default
        vim.opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]] -- Custom status column

        -- toggles
        -- stylua: ignore start
        Snacks.toggle.animate():map("<leader>uA")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.option("wrap", { name = "Line Wrapping" }):map("<leader>uw")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.option("spell", { name = "Spell Check" }):map("<leader>us")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        -- stylua: ignore end
    end,
}

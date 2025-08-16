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
                enabled = false,
            },
            chunk = {
                enabled = true,
                only_current = true,
                char = {
                    corner_top = "╭",
                    corner_bottom = "╰",
                    arrow = "─",
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
        { "<leader>/", function() Snacks.picker.lines({ layout = "select", on_show = function() end, title = "Current Buffer Search" }) end, desc = "Search Current Buffer" },
        { "<leader>e",  function() Snacks.explorer() end, desc = "File Explorer" },
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
        { "<leader>sP", function() Snacks.picker.pickers() end, desc = "Pickers" },
        { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
        { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
        { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
        { "<leader>ts", function() Snacks.picker.pick("tabs") end, desc = "Search Tabs" },
    },
    config = function(_, opts)
        require("snacks").setup(opts)

        vim.g.snacks_animate = false -- Disable snacks animations by default

        -- Advanced LSP Progress Notifications
        ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
        local progress = vim.defaulttable()
        vim.api.nvim_create_autocmd("LspProgress", {
            ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
                if not client or type(value) ~= "table" then
                    return
                end
                local p = progress[client.id]
                for i = 1, #p + 1 do
                    if i == #p + 1 or p[i].token == ev.data.params.token then
                        p[i] = {
                            token = ev.data.params.token,
                            msg = ("[%3d%%] %s%s"):format(
                                value.kind == "end" and 100 or value.percentage or 100,
                                value.title or "",
                                value.message and (" **%s**"):format(value.message) or ""
                            ),
                            done = value.kind == "end",
                        }
                        break
                    end
                end
                local msg = {} ---@type string[]
                progress[client.id] = vim.tbl_filter(function(v)
                    return table.insert(msg, v.msg) or not v.done
                end, p)
                local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
                vim.notify(table.concat(msg, "\n"), "info", {
                    id = "lsp_progress",
                    title = client.name,
                    opts = function(notif)
                        notif.icon = #progress[client.id] == 0 and " "
                            or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                    end,
                })
            end,
        })

        -- toggles
        -- stylua: ignore start
        Snacks.toggle.animate():map("<leader>uA")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map( "<leader>uc")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.option("wrap", { name = "Line Wrapping" }):map("<leader>uw")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.option("spell", { name = "Spell Check" }):map("<leader>us")
        Snacks.toggle.treesitter({ name = "Treesitter Highlighting" }):map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        -- stylua: ignore end
    end,
}

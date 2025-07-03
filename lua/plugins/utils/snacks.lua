return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        --- BUFDELETE ---
        bufdelete = { enabled = true },

        --- INDENT ---
        indent = {
            enabled = true,
            scope = {
                enabled = false,
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
                        backdrop = false,
                    },
                },
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
                tabs = {
                    name = "Tabs",
                    finder = function(opts, ctx)
                        local items = {} ---@type snacks.picker.finder.Item[]
                        local current_buf = vim.api.nvim_get_current_buf()
                        local alternate_buf = vim.fn.bufnr("#")
                        local current_tabpage = vim.api.nvim_get_current_tabpage()

                        local tabpages = vim.api.nvim_list_tabpages()
                        -- Sort tabpages by number to ensure consistent ordering
                        table.sort(tabpages, function(a, b)
                            return vim.api.nvim_tabpage_get_number(a) < vim.api.nvim_tabpage_get_number(b)
                        end)

                        for _, tabpage_id in ipairs(tabpages) do
                            local tab_num = vim.api.nvim_tabpage_get_number(tabpage_id)
                            local is_current_tab = tabpage_id == current_tabpage

                            -- Add tabpage header
                            -- Make the 'text' field highly matchable by including just the number
                            table.insert(items, {
                                type = "tab_header",
                                text = "Tab #" .. tab_num .. " " .. tostring(tab_num), -- Enhanced 'text' for searching
                                tabpage_id = tabpage_id,
                                is_current = is_current_tab,
                            })

                            local tab_buffers_to_display = {}
                            local buffers_seen_in_tab = {} -- To avoid duplicate buffers if multiple windows show the same buffer

                            -- Iterate through windows in the tabpage to get the actual visible buffers
                            local windows_in_tab = vim.api.nvim_tabpage_list_wins(tabpage_id)
                            for _, win_id in ipairs(windows_in_tab) do
                                local buf = vim.api.nvim_win_get_buf(win_id)

                                -- Skip if this buffer has already been added from another window in the same tab
                                if buffers_seen_in_tab[buf] then
                                    goto continue_window_loop
                                end
                                buffers_seen_in_tab[buf] = true

                                -- Existing filtering logic for buffers
                                local keep = vim.api.nvim_buf_is_loaded(buf)
                                    and vim.bo[buf].buftype ~= "prompt" -- Still exclude prompt buffers (e.g., from `:!` commands)
                                    -- Allow terminal and help buffers now
                                    and (
                                        vim.bo[buf].buflisted
                                        or vim.bo[buf].buftype == "terminal"
                                        or vim.bo[buf].buftype == "help"
                                    )

                                if vim.bo[buf].buftype == "nofile" and opts.show_nofile_in_tabs then
                                    keep = true
                                end

                                -- Filter out specific nofile types but keep help and man pages
                                if keep and vim.bo[buf].buftype == "nofile" then
                                    local filetype = vim.bo[buf].filetype
                                    if
                                        filetype == "noice"
                                        or filetype == "fidget"
                                        or filetype == "qf"
                                        -- Removed "help" and "man" from exclusion list
                                    then
                                        keep = false
                                    end
                                end

                                if keep then
                                    local name = vim.api.nvim_buf_get_name(buf)
                                    if name == "" then
                                        name = "[No Name]"
                                        if vim.bo[buf].filetype ~= "" then
                                            name = name .. " " .. vim.bo[buf].filetype
                                        end
                                    end

                                    local info = vim.fn.getbufinfo(buf)[1] or {} -- Ensure info is a table
                                    local mark = vim.api.nvim_buf_get_mark(buf, '"') -- Use mark for cursor position
                                    local flags = {
                                        buf == current_buf and "%" or (buf == alternate_buf and "#" or ""),
                                        (info.hidden == 1 or not vim.api.nvim_buf_is_loaded(buf)) and "h"
                                            or (#(info.windows or {}) > 0) and "a"
                                            or "",
                                        vim.bo[buf].readonly and "=" or "",
                                        info.changed == 1 and "+" or "",
                                    }

                                    -- Concatenate the buffer number and name for searching
                                    local item_searchable_text = tostring(buf) .. " " .. name

                                    table.insert(tab_buffers_to_display, {
                                        type = "buffer_entry",
                                        flags = table.concat(flags),
                                        buf = buf,
                                        file = name, -- This is for display purposes
                                        text = item_searchable_text, -- Includes buffer number and name for searching
                                        info = info,
                                        filetype = vim.bo[buf].filetype, -- Keep filetype for potential direct use or fallback
                                        tabpage_id = tabpage_id,
                                        is_current = (buf == current_buf and is_current_tab),
                                        pos = mark[1] ~= 0 and mark or { info.lnum, 0 }, -- Use mark as in the original buffers source
                                        win_id = win_id, -- Store window ID for confirming
                                    })
                                end
                                ::continue_window_loop::
                            end

                            -- Sort buffers within the tab (you can change this sort logic if needed)
                            table.sort(tab_buffers_to_display, function(a, b)
                                return a.buf < b.buf -- Sort by buffer number
                            end)

                            -- Add sorted buffers to the main items list
                            for _, buffer_item in ipairs(tab_buffers_to_display) do
                                table.insert(items, buffer_item)
                            end
                        end
                        return ctx.filter:filter(items) -- Apply the picker's filter
                    end,
                    format = function(item, picker)
                        local ret = {}
                        if item.type == "tab_header" then
                            local hl = "SnacksPickerDirectory"
                            -- Display only "Tab #N" for clarity in the picker window
                            ret[#ret + 1] = { "Tab #" .. vim.api.nvim_tabpage_get_number(item.tabpage_id), hl }
                            if item.is_current then
                                ret[#ret + 1] = { " ", "SnacksPickerBufNr" }
                            end
                        elseif item.type == "buffer_entry" then
                            -- Basic icon lookup, similar to M.filename
                            local icon, icon_hl = Snacks.util.icon(item.file, "file", {
                                fallback = picker.opts.icons.files,
                            })
                            -- Optionally align the icon
                            icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)

                            ret[#ret + 1] = { "  " } -- Indent buffers under tab header

                            ret[#ret + 1] = { Snacks.picker.util.align(tostring(item.buf), 3), "SnacksPickerBufNr" }
                            ret[#ret + 1] = { " " } -- Space after buffer number

                            ret[#ret + 1] = {
                                Snacks.picker.util.align(item.flags or "", 2, { align = "right" }),
                                "SnacksPickerBufFlags",
                            }
                            ret[#ret + 1] = { " " } -- Space after flags

                            ret[#ret + 1] = { icon, icon_hl } -- Add the icon (no extra space here, let align handle it)

                            local full_path = Snacks.picker.util.path(item) or item.file
                            local truncated_path = Snacks.picker.util.truncpath(
                                full_path,
                                picker.opts.formatters.file.truncate or 40,
                                { cwd = picker:cwd() }
                            )

                            local dir, base = truncated_path:match("^(.*)/(.+)$")
                            if base and dir then
                                ret[#ret + 1] = { dir .. "/", "SnacksPickerDir" }
                                ret[#ret + 1] = { base, "SnacksPickerFile" }
                            else
                                ret[#ret + 1] = { truncated_path, "SnacksPickerFile" }
                            end

                            if item.pos and item.pos[1] and item.pos[1] > 0 then
                                ret[#ret + 1] = { ":", "SnacksPickerDelim" }
                                ret[#ret + 1] = { tostring(item.pos[1]), "SnacksPickerRow" }
                                if item.pos[2] and item.pos[2] > 0 then
                                    ret[#ret + 1] = { ":", "SnacksPickerDelim" }
                                    ret[#ret + 1] = { tostring(item.pos[2]), "SnacksPickerCol" }
                                end
                            end
                        end
                        return ret
                    end,
                    confirm = function(picker, item)
                        picker:close()
                        if item.type == "tab_header" then
                            if item.tabpage_id then
                                vim.api.nvim_set_current_tabpage(item.tabpage_id)
                            end
                        elseif item.type == "buffer_entry" then
                            if item.tabpage_id then
                                vim.api.nvim_set_current_tabpage(item.tabpage_id)
                                if item.win_id and vim.api.nvim_win_is_valid(item.win_id) then
                                    vim.api.nvim_set_current_win(item.win_id)
                                else
                                    -- Fallback: if the specific window is no longer valid,
                                    -- just set the buffer in the current window of that tab.
                                    -- This might change the window layout if the buffer wasn't displayed.
                                    vim.api.nvim_set_current_buf(item.buf)
                                end
                            end
                        end
                    end,
                    actions = {},
                    win = {
                        input = {
                            keys = {},
                        },
                    },
                    layout = {
                        preset = "default",
                    },
                },
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
        { "<leader>t", function() Snacks.picker.pick("tabs") end, desc = "Tabs" },
        -- buffer
        { "<leader>bc", function() Snacks.bufdelete() end, desc = "Close Buffer" },
        { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Close Other Buffers" },
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
        { "<leader>sb", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
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
    },
    config = function(_, opts)
        require("snacks").setup(opts)
        vim.g.snacks_animate = false

        -- stylua: ignore start
        Snacks.toggle.animate():map("<leader>ua")
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

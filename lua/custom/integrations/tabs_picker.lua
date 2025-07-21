-- TODO: fix help page bugs on the picker
-- add keymap to delete tabs
-- do something about preview window for tabs

return {
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
                    and (vim.bo[buf].buflisted or vim.bo[buf].buftype == "terminal" or vim.bo[buf].buftype == "help")

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
            -- Fixed icon logic to match Snacks' approach
            local icon, icon_hl = "", ""
            local name, cat = item.file, "file"

            -- For loaded buffers, use filetype as name and "filetype" as category
            if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
                name = vim.bo[item.buf].filetype
                cat = "filetype"
            end

            -- Get the icon using the corrected name and category
            local new_icon, new_icon_hl = Snacks.util.icon(name, cat, {
                fallback = picker.opts.icons.files,
            })
            icon = new_icon or icon
            icon_hl = new_icon_hl or icon_hl

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

                -- When selecting a tab, also restore cursor position for the current buffer
                local current_buf = vim.api.nvim_get_current_buf()
                local mark = vim.api.nvim_buf_get_mark(current_buf, '"')
                if mark[1] > 0 then
                    pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
            end
        elseif item.type == "buffer_entry" then
            if item.tabpage_id then
                vim.api.nvim_set_current_tabpage(item.tabpage_id)
                if item.win_id and vim.api.nvim_win_is_valid(item.win_id) then
                    vim.api.nvim_set_current_win(item.win_id)
                else
                    -- Fallback: if the specific window is no longer valid,
                    -- just set the buffer in the current window of that tab.
                    vim.api.nvim_set_current_buf(item.buf)
                end

                -- Set cursor position to match what's shown in the picker
                if item.pos and item.pos[1] and item.pos[1] > 0 then
                    -- Use pcall to safely set cursor position
                    pcall(vim.api.nvim_win_set_cursor, 0, item.pos)
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
}

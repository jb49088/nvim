return function(session_manager)
    -- Helper function to extract session name from path
    local function extract_session_name(path)
        local filename = path:match("([^/]+)$") or path
        local session_name = filename:gsub("%.vim$", "")
        -- Decode URL encoding
        return session_name:gsub("%%(%x%x)", function(hex)
            return string.char(tonumber(hex, 16))
        end)
    end

    -- Get the currently active session name using session manager
    local function get_active_session()
        -- Use the session manager's tracking instead of vim.v.this_session
        return session_manager.get_current_session()
    end

    -- Get list of available sessions (excluding "last" session)
    local function get_sessions()
        -- Use the session directory from our config
        local session_dir = vim.fn.stdpath("data") .. "/sessions/"
        local sessions = {}
        local session_files = vim.fn.glob(session_dir .. "*.vim", false, true)

        for _, file in ipairs(session_files) do
            local name = extract_session_name(file)
            -- Exclude the "last" session from the picker - it's only accessible via <leader>Sr
            if name ~= "last" then
                table.insert(sessions, {
                    name = name,
                    path = file,
                    text = name,
                })
            end
        end

        table.sort(sessions, function(a, b)
            return a.name < b.name
        end)

        return sessions
    end

    local sessions = get_sessions()

    -- Check if there are no saved sessions
    if #sessions == 0 then
        vim.notify("No saved sessions", vim.log.levels.WARN)
        return
    end

    local current_session = get_active_session()

    return Snacks.picker.pick({
        title = "Sessions",
        finder = function()
            return sessions
        end,
        matcher = {
            fields = { "text" }, -- Search the text field (which contains the name)
        },
        layout = { preset = "select" },
        format = function(item)
            -- Get fresh active session state for each format call
            local active_session = get_active_session()
            local is_active = active_session and item.name == active_session
            return {
                { " ", is_active and "SessionPickerActive" or "SnacksPickerDir" }, -- Session icon
                { item.name, "SnacksPickerFile" },
            }
        end,
        confirm = function(picker, item)
            if item then
                picker:close()
                vim.schedule(function()
                    -- Use the passed session manager to load the session
                    session_manager.load_session(item.name)
                end)
            end
        end,
        actions = {
            delete_session = function(picker, item)
                -- Prevent deletion of the "last" session (though it shouldn't appear anyway)
                if item.name == "last" then
                    vim.notify('Cannot delete "last" session', vim.log.levels.WARN)
                    return
                end

                -- Use session manager's delete function instead of direct file deletion
                if session_manager.delete_session(item.name) then
                    sessions = get_sessions()
                    picker:find()
                end
            end,
        },
        win = {
            input = { keys = { ["<C-x>"] = { "delete_session", mode = "i" } } },
            list = { keys = { ["<C-x>"] = { "delete_session", mode = "n" } } },
        },
    })
end

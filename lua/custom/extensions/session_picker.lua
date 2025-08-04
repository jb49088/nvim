-- TODO: fix search function throwing error - FIXED

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
    -- Get the currently active session name
    local function get_active_session()
        -- Check if we have a current session loaded
        local this_session = vim.v.this_session
        return this_session and this_session ~= "" and extract_session_name(this_session) or nil
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
            local is_active = current_session and item.name == current_session
            return {
                { " ", is_active and "AutoSessionActive" or "SnacksPickerDir" }, -- Session icon
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
                vim.fn.delete(item.path)
                sessions = get_sessions()
                picker:find()
            end,
        },
        win = {
            input = { keys = { ["<C-x>"] = { "delete_session", mode = "i" } } },
            list = { keys = { ["<C-x>"] = { "delete_session", mode = "n" } } },
        },
    })
end

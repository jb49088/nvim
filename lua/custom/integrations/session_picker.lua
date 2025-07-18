return function()
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
        local ok, auto_session = pcall(require, "auto-session")
        if ok and auto_session.current_session_name and auto_session.current_session_name ~= "" then
            return auto_session.current_session_name
        end

        local this_session = vim.v.this_session
        return this_session and this_session ~= "" and extract_session_name(this_session) or nil
    end

    -- Get list of available sessions
    local function get_sessions()
        -- Try to get session directory from auto-session, fallback to default
        local session_dir = vim.fn.stdpath("data") .. "/sessions"
        local ok, auto_session = pcall(require, "auto-session")
        if ok then
            local config = require("auto-session.config")
            session_dir = config.session_dir or config.auto_session_root_dir or session_dir
        end

        local sessions = {}
        local session_files = vim.fn.glob(session_dir .. "/*.vim", false, true)

        for _, file in ipairs(session_files) do
            table.insert(sessions, {
                name = extract_session_name(file),
                path = file,
                icon = "",
                source = "autosession",
            })
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
        layout = { preset = "select" },
        format = function(item)
            local is_active = current_session and item.name == current_session
            return {
                { item.icon, is_active and "AutoSessionActive" or "SnacksPickerDir" },
                { " " },
                { item.name, "SnacksPickerFile" },
            }
        end,
        confirm = function(picker, item)
            if item then
                picker:close()
                vim.schedule(function()
                    vim.cmd("SessionRestore " .. vim.fn.fnameescape(item.name))
                end)
            end
        end,
        actions = {
            delete_session = function(picker, item)
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

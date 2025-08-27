local session_picker = require("custom.extensions.session_picker")

local M = {}

-- Flag to control autosave
local auto_save = true

-- Flag to control auto-restore on startup
local auto_restore = false

-- Track the currently active session
local current_session = nil

-- Configuration
local config = {
    session_dir = vim.fn.stdpath("data") .. "/sessions/",
    last_session = "last",
}

-- Venv manager reference (will be set in setup)
local venv_manager = nil

-- Ensure session directory exists
local function ensure_session_dir()
    if vim.fn.isdirectory(config.session_dir) == 0 then
        vim.fn.mkdir(config.session_dir, "p")
    end
end

-- Get full path to session file
local function get_session_path(name)
    name = name or config.last_session
    if not name:match("%.vim$") then
        name = name .. ".vim"
    end
    return config.session_dir .. name
end

-- Get venv info file path
local function get_venv_info_path(name)
    name = name or config.last_session
    if name:match("%.vim$") then
        name = name:gsub("%.vim$", "")
    end
    return config.session_dir .. name .. ".venv"
end

-- Save venv info to file (enhanced to track activation state)
local function save_venv_info(name)
    if not venv_manager then
        return
    end

    local current_venv = venv_manager.current_venv()
    local current_python = venv_manager.current_python()

    local venv_info_path = get_venv_info_path(name)

    if current_venv and current_python then
        -- Venv is currently active - save it with active state
        local venv_data = {
            venv_path = current_venv,
            python_path = current_python,
            was_active = true,
        }

        local file = io.open(venv_info_path, "w")
        if file then
            file:write(vim.json.encode(venv_data))
            file:close()
        end
    else
        -- No venv active - but check if we had venv info from a previous session
        if vim.fn.filereadable(venv_info_path) == 1 then
            local file = io.open(venv_info_path, "r")
            if file then
                local content = file:read("*all")
                file:close()

                local success, existing_data = pcall(vim.json.decode, content)
                if success and existing_data.venv_path and existing_data.python_path then
                    -- Update existing data to reflect that venv is now inactive
                    existing_data.was_active = false

                    file = io.open(venv_info_path, "w")
                    if file then
                        file:write(vim.json.encode(existing_data))
                        file:close()
                    end
                end
            end
        end
    end
end

-- Load and apply venv info from file (respects activation state)
local function load_venv_info(name)
    if not venv_manager then
        return
    end

    local venv_info_path = get_venv_info_path(name)

    if vim.fn.filereadable(venv_info_path) == 1 then
        local file = io.open(venv_info_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            local success, venv_data = pcall(vim.json.decode, content)
            if success and venv_data.venv_path and venv_data.python_path then
                -- Verify the venv still exists
                if vim.fn.executable(venv_data.python_path) == 1 then
                    -- Only activate if it was active when the session was saved
                    if venv_data.was_active then
                        local venv_name = vim.fn.fnamemodify(venv_data.venv_path, ":t")

                        local venv_info = {
                            python_path = venv_data.python_path,
                            venv_path = venv_data.venv_path,
                            name = venv_name,
                        }

                        venv_manager.activate(venv_info)

                        -- Force LSP refresh after venv activation
                        vim.defer_fn(function()
                            -- Restart LSP clients to ensure they pick up the new Python path
                            local clients = vim.lsp.get_clients and vim.lsp.get_clients()
                                or vim.lsp.get_active_clients()
                            for _, client in pairs(clients) do
                                if client.name == "basedpyright" then
                                    -- Force a workspace refresh using notify instead of request
                                    client.notify(
                                        "workspace/didChangeConfiguration",
                                        { settings = client.config.settings }
                                    )

                                    -- Clear diagnostics for all buffers attached to this client
                                    local buffers = vim.lsp.get_buffers_by_client_id(client.id)
                                    for _, buf in ipairs(buffers) do
                                        if vim.api.nvim_buf_is_valid(buf) then
                                            vim.diagnostic.reset(nil, buf)
                                        end
                                    end
                                end
                            end
                        end, 100)

                        return true
                    else
                        -- Venv info exists but was deactivated when session was saved
                        return false
                    end
                else
                    -- Clean up invalid venv info file
                    vim.fn.delete(venv_info_path)
                end
            end
        end
    end
    return false
end

-- Clear everything to return to a clean Neovim state
local function clear_session()
    current_session = nil

    if venv_manager and venv_manager.deactivate then
        venv_manager.deactivate()
    end

    vim.v.this_session = ""
    vim.cmd("clearjumps")
    vim.cmd("delmarks!")
    vim.cmd("nohlsearch")
    vim.cmd("cd ~")

    vim.schedule(function()
        vim.cmd("silent! %bdelete!")
        vim.cmd("silent! tabonly!")
        vim.cmd("silent! only!")
        vim.cmd("enew")
    end)
end

-- Get list of available sessions (for internal use)
local function get_available_sessions()
    ensure_session_dir()
    local sessions = {}
    local files = vim.fn.glob(config.session_dir .. "*.vim", false, true)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r") -- Get just the filename without extension
        -- Exclude the "last" session from the picker - it's only accessible via <leader>Sr
        if name ~= config.last_session then
            table.insert(sessions, name)
        end
    end

    -- Sort sessions alphabetically
    table.sort(sessions)
    return sessions
end

-- Use the custom session picker
function M.session_picker()
    session_picker(M)
end

-- Save session
function M.save_session(name)
    ensure_session_dir()
    local session_path = get_session_path(name)

    -- Only save if we have buffers with actual files
    local has_files = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
                has_files = true
                break
            end
        end
    end

    if has_files then
        vim.cmd("mksession! " .. vim.fn.fnameescape(session_path))

        -- Save venv info along with the session
        save_venv_info(name)

        -- Update current session tracking
        current_session = name or config.last_session

        local display_name = name or config.last_session
        print('Saved session "' .. display_name .. '"')
    end
end

-- Load session with toggle behavior for same session
function M.load_session(name)
    local session_name = name or config.last_session

    -- If trying to load the same session that's currently active, clear instead
    if current_session == session_name then
        clear_session()
        return
    end

    local session_path = get_session_path(name)
    if vim.fn.filereadable(session_path) == 1 then
        -- Close all current buffers without prompting
        vim.cmd("silent! %bdelete!")
        vim.cmd("source " .. vim.fn.fnameescape(session_path))

        -- Update current session tracking
        current_session = session_name

        -- Load and apply venv info after a longer delay to ensure session and LSP are fully loaded
        vim.defer_fn(function()
            load_venv_info(name)
        end, 1000)

        -- Different message for last session vs named sessions
        if name == nil or name == config.last_session then
            print("Loaded last session")
        else
            print('Loaded session "' .. name .. '"')
        end
    else
        print("No session found: " .. session_path)
    end
end

-- Check if session exists
function M.session_exists(name)
    local session_path = get_session_path(name)
    return vim.fn.filereadable(session_path) == 1
end

-- Get current session name (for external use)
function M.get_current_session()
    return current_session
end

-- Check if a session is currently active
function M.is_session_active(name)
    return current_session == (name or config.last_session)
end

-- Toggle autosave
function M.toggle_autosave()
    auto_save = not auto_save
    print("Autosave " .. (auto_save and "enabled" or "disabled"))
end

-- Delete session and its venv info
function M.delete_session(name)
    if not name or name == config.last_session then
        print("Cannot delete the last session")
        return false
    end

    local session_path = get_session_path(name)
    local venv_info_path = get_venv_info_path(name)

    local deleted = false

    -- Delete session file
    if vim.fn.filereadable(session_path) == 1 then
        vim.fn.delete(session_path)
        deleted = true
    end

    -- Delete venv info file if it exists
    if vim.fn.filereadable(venv_info_path) == 1 then
        vim.fn.delete(venv_info_path)
    end

    -- Clear current session tracking if we deleted the active session
    if current_session == name then
        current_session = nil
    end

    if deleted then
        print('Deleted session "' .. name .. '"')
        return true
    else
        print('Session "' .. name .. '" not found')
        return false
    end
end

-- Manual clear session function (exposed for session picker highlight updates)
function M.clear_session()
    clear_session()
end

-- Setup function to initialize the session manager
function M.setup(opts)
    -- Merge user options with defaults
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end

    -- Try to get venv manager reference
    local ok, venv_mod = pcall(require, "custom.modules.venv_manager")
    if ok then
        venv_manager = venv_mod
    else
        vim.notify("Venv manager not found. Session-venv integration disabled.", vim.log.levels.WARN)
    end

    -- Set up keymaps
    vim.keymap.set("n", "<leader>SS", M.session_picker, { desc = "Search Sessions", silent = true })
    vim.keymap.set("n", "<leader>Sr", function()
        M.load_session()
    end, { desc = "Restore Last Session", silent = true })
    vim.keymap.set("n", "<leader>Ss", function()
        vim.ui.input({ prompt = "Session Name: " }, function(input)
            if input and input ~= "" then
                -- Prevent naming a session "last" to avoid conflicts
                if input == config.last_session then
                    print('Cannot name session "' .. config.last_session .. '" - this name is reserved')
                    return
                end
                M.save_session(input)
            end
        end)
    end, { desc = "Save Session", silent = true })

    -- Snacks toggle for autosave
    require("snacks")
        .toggle({
            name = "Session Autosave",
            get = function()
                return auto_save
            end,
            set = function()
                auto_save = not auto_save
            end,
        })
        :map("<leader>Sa")

    -- Auto-save on exit - save to current active session or fallback to "last"
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if auto_save then
                -- If we have an active session, update it; otherwise save to "last"
                M.save_session(current_session)
            end
        end,
    })

    -- Auto-restore on startup (if enabled)
    if auto_restore then
        vim.api.nvim_create_autocmd("VimEnter", {
            nested = true,
            callback = function()
                -- Only load if no files were passed as arguments
                if vim.fn.argc(-1) == 0 then
                    if M.session_exists() then
                        M.load_session()
                        -- Set current session after auto-restore
                        current_session = config.last_session
                    end
                end
            end,
        })
    end
end

-- Auto-setup with default configuration
M.setup()

return M

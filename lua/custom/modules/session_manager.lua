-- TODO: figure out inconsistently long startup times

local session_picker = require("custom.extensions.session_picker")

local M = {}

-- Flag to control autosave
local autosave_enabled = true

-- Configuration
local config = {
    session_dir = vim.fn.stdpath("data") .. "/sessions/",
    last_session = "last",
}

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

-- Get list of available sessions (for internal use)
local function get_available_sessions()
    ensure_session_dir()
    local sessions = {}
    local files = vim.fn.glob(config.session_dir .. "*.vim", false, true)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r") -- Get just the filename without extension
        table.insert(sessions, name)
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
        local display_name = name or config.last_session
        print('Saved session "' .. display_name .. '"')
    end
end

-- Load session
function M.load_session(name)
    local session_path = get_session_path(name)
    if vim.fn.filereadable(session_path) == 1 then
        -- Close all current buffers without prompting
        vim.cmd("silent! %bdelete!")
        vim.cmd("source " .. vim.fn.fnameescape(session_path))
        local display_name = name or config.last_session
        print('Loaded session "' .. display_name .. '"')
    else
        print("No session found: " .. session_path)
    end
end

-- Check if session exists
function M.session_exists(name)
    local session_path = get_session_path(name)
    return vim.fn.filereadable(session_path) == 1
end

-- Toggle autosave
function M.toggle_autosave()
    autosave_enabled = not autosave_enabled
    print("Autosave " .. (autosave_enabled and "enabled" or "disabled"))
end

-- Setup function to initialize the session manager
function M.setup(opts)
    -- Merge user options with defaults
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end

    -- Set up keymaps
    vim.keymap.set("n", "<leader>SS", M.session_picker, { desc = "Search Sessions", silent = true })
    vim.keymap.set("n", "<leader>Sr", function()
        M.load_session()
    end, { desc = "Restore Last Session", silent = true })
    vim.keymap.set("n", "<leader>Ss", function()
        vim.ui.input({ prompt = "Session Name: " }, function(input)
            if input and input ~= "" then
                M.save_session(input)
            end
        end)
    end, { desc = "Save Session", silent = true })

    -- Snacks toggle for autosave
    require("snacks")
        .toggle({
            name = "Session Autosave",
            get = function()
                return autosave_enabled
            end,
            set = function()
                autosave_enabled = not autosave_enabled
            end,
        })
        :map("<leader>Sa")

    -- Auto-save on exit and auto-restore on startup
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if autosave_enabled then
                M.save_session()
            end
        end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
        nested = true,
        callback = function()
            -- Only load if no files were passed as arguments
            if vim.fn.argc(-1) == 0 then
                if M.session_exists() then
                    M.load_session()
                end
            end
        end,
    })
end

-- Auto-setup with default configuration
M.setup()

return M

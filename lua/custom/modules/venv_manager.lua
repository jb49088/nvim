local venv_picker = require("custom.extensions.venv_picker")

local M = {}

local VENV_SEARCH_PATH = "~/venvs" -- Change this to your venvs directory
local FD_PATTERN = "/bin/python$" -- Pattern to find Python executables

-- State tracking
local current_python = nil
local current_venv = nil

-- Helper function to expand path
local function expand_path(path)
    return vim.fn.expand(path)
end

-- Helper function to extract venv name from python path (simple version for state tracking)
local function extract_venv_name(python_path)
    local parts = {}
    for part in string.gmatch(python_path, "[^/]+") do
        table.insert(parts, part)
    end

    -- Look for common venv directory patterns
    for i = 1, #parts - 1 do
        if parts[i] == "venvs" or parts[i] == "envs" or parts[i] == ".venv" or parts[i] == "virtualenvs" then
            if parts[i + 1] and parts[i + 1] ~= "bin" then
                return parts[i + 1]
            end
        end
    end

    -- Fallback: look for pattern where second-to-last directory might be venv name
    if #parts >= 3 and parts[#parts] == "python" and parts[#parts - 1] == "bin" then
        return parts[#parts - 2]
    end

    return python_path
end

-- Update Python path for LSP servers (basedpyright only)
local function update_lsp_servers(python_path)
    local clients = vim.lsp.get_clients and vim.lsp.get_clients() or vim.lsp.get_active_clients()
    local updated_count = 0

    for _, client in pairs(clients) do
        if client.name == "basedpyright" then
            -- Update basedpyright
            local settings = client.config.settings or {}
            settings.python = settings.python or {}
            settings.python.pythonPath = python_path

            client.notify("workspace/didChangeConfiguration", { settings = settings })
            updated_count = updated_count + 1
        end
    end

    return updated_count
end

-- Set environment variables for new terminals
local function set_env_vars(venv_path, venv_name)
    if venv_path then
        local venv_bin_path = venv_path .. "/bin"

        -- Store original PATH if not already stored
        local original_path = vim.fn.getenv("_NVIM_ORIGINAL_PATH")
        if original_path == vim.NIL or not original_path then
            original_path = vim.fn.getenv("PATH")
            -- Handle case where PATH might be nil/userdata
            if original_path == vim.NIL then
                original_path = "/usr/local/bin:/usr/bin:/bin"
            end
            vim.fn.setenv("_NVIM_ORIGINAL_PATH", original_path)
        end

        -- Prepend venv bin path to PATH
        local new_path = venv_bin_path .. ":" .. original_path
        vim.fn.setenv("PATH", new_path)
        vim.fn.setenv("VIRTUAL_ENV", venv_path)
        vim.fn.setenv("CONDA_PREFIX", nil) -- Clear conda prefix

        -- Set PROMPT_COMMAND to dynamically update PS1 based on VIRTUAL_ENV
        local prompt_cmd =
            'if [[ -n "$VIRTUAL_ENV" ]]; then venv_name=$(basename "$VIRTUAL_ENV"); if [[ "$PS1" != *"($venv_name)"* ]]; then if [[ -z "$_NVIM_ORIGINAL_PS1" ]]; then export _NVIM_ORIGINAL_PS1="$PS1"; fi; PS1="($venv_name) $_NVIM_ORIGINAL_PS1"; fi; elif [[ -n "$_NVIM_ORIGINAL_PS1" ]]; then PS1="$_NVIM_ORIGINAL_PS1"; fi'
        vim.fn.setenv("PROMPT_COMMAND", prompt_cmd)
    end
end

-- Clear environment variables
local function clear_env_vars()
    -- Restore original PATH
    local original_path = vim.fn.getenv("_NVIM_ORIGINAL_PATH")
    if original_path ~= vim.NIL and original_path then
        vim.fn.setenv("PATH", original_path)
        vim.fn.setenv("_NVIM_ORIGINAL_PATH", nil)
    end

    vim.fn.setenv("VIRTUAL_ENV", nil)
    vim.fn.setenv("PROMPT_COMMAND", nil)
end

-- Send activation command to all terminal buffers
local function activate_in_terminals(venv_path, venv_name)
    local activation_script = venv_path .. "/bin/activate"
    local activation_cmd = "source " .. activation_script

    local term_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local ok, buf_type = pcall(vim.api.nvim_buf_get_option, buf, "buftype")
            if ok and buf_type == "terminal" then
                table.insert(term_buffers, buf)
            end
        end
    end

    for _, buf in ipairs(term_buffers) do
        local ok, chan = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
        if ok and chan then
            vim.api.nvim_chan_send(chan, activation_cmd .. "\n")
        end
    end

    return #term_buffers
end

-- Send deactivation command to all terminal buffers
local function deactivate_in_terminals()
    local term_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local ok, buf_type = pcall(vim.api.nvim_buf_get_option, buf, "buftype")
            if ok and buf_type == "terminal" then
                table.insert(term_buffers, buf)
            end
        end
    end

    for _, buf in ipairs(term_buffers) do
        local ok, chan = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
        if ok and chan then
            vim.api.nvim_chan_send(chan, "deactivate\n")
        end
    end

    return #term_buffers
end

-- Find all Python executables in the venv directory
function M.find_venvs()
    local search_path = expand_path(VENV_SEARCH_PATH)

    if vim.fn.isdirectory(search_path) == 0 then
        vim.notify("Venv search path does not exist: " .. search_path, vim.log.levels.ERROR)
        return {}
    end

    -- Use fd to find python executables
    local fd_cmd = { "fd", FD_PATTERN, search_path, "--full-path", "-E", "/proc" }
    local results = {}

    local handle = io.popen(table.concat(fd_cmd, " "))
    if handle then
        for line in handle:lines() do
            if line and line ~= "" then
                -- Verify it's actually a python executable
                if vim.fn.executable(line) == 1 then
                    table.insert(results, {
                        python_path = line,
                        venv_path = vim.fn.fnamemodify(line, ":h:h"), -- Remove /bin/python
                        name = extract_venv_name(line),
                    })
                end
            end
        end
        handle:close()
    end

    -- Sort by name
    table.sort(results, function(a, b)
        return a.name < b.name
    end)

    return results
end

-- Activate a virtual environment
function M.activate(venv_info)
    if not venv_info then
        return false
    end

    local python_path = venv_info.python_path
    local venv_path = venv_info.venv_path

    -- Verify python executable exists
    if vim.fn.executable(python_path) ~= 1 then
        vim.notify("Python executable not found: " .. python_path, vim.log.levels.ERROR)
        return false
    end

    -- Update LSP servers
    local lsp_count = update_lsp_servers(python_path)

    -- Set environment variables for new terminals
    set_env_vars(venv_path, venv_info.name)

    -- Send activation commands to existing terminals
    local term_count = activate_in_terminals(venv_path, venv_info.name)

    -- Update state
    current_python = python_path
    current_venv = venv_path

    -- Fire custom event for venv activation
    vim.api.nvim_exec_autocmds("User", {
        pattern = "VenvActivated",
        data = { venv_path = venv_path, venv_name = venv_info.name },
    })

    local message = string.format("Activated venv: %s", venv_info.name)

    vim.notify(message, vim.log.levels.INFO)
    return true
end

-- Deactivate current virtual environment
function M.deactivate()
    if not current_venv then
        vim.notify("No virtual environment is tracked as active", vim.log.levels.INFO)
        return
    end

    local old_name = extract_venv_name(current_python or "")

    -- Clear environment variables for new terminals
    clear_env_vars()

    -- Send deactivation commands to existing terminals
    local term_count = deactivate_in_terminals()

    -- Clear state
    current_python = nil
    current_venv = nil

    -- Fire custom event for venv deactivation
    vim.api.nvim_exec_autocmds("User", {
        pattern = "VenvDeactivated",
        data = {},
    })

    local message = "Deactivated venv: " .. old_name

    vim.notify(message, vim.log.levels.INFO)
end

-- Show venv picker using external picker module
function M.show_picker()
    venv_picker(M)
end

-- Expose current state (these are the key functions for session integration)
function M.current_python()
    return current_python
end

function M.current_venv()
    return current_venv
end

-- Create user command
vim.api.nvim_create_user_command("VenvSelect", function()
    M.show_picker()
end, { desc = "Select virtual environment" })

-- Create keymap
vim.keymap.set("n", "<leader>v", M.show_picker, { desc = "Virtual Environments" })

return M

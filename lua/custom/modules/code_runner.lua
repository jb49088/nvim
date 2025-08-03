-- Unified Code Runner for Neovim
-- Supports running files in terminal or background
local M = {}

-- Configuration
local config = {
    interpreters = {
        py = "python3",
        lua = "lua",
    },
    no_term_runners = {
        py = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B pythonw.exe "' .. filepath .. '"'
                or 'nohup python3 "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
        lua = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B lua.exe "' .. filepath .. '"'
                or 'nohup lua "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
    },
}
-- Helper function to check if buffer is valid for execution
local function is_valid_buffer()
    return vim.bo.buftype == ""
end
-- Helper function to get file extension and interpreter
local function get_interpreter(filename)
    local extension = vim.fn.fnamemodify(filename, ":e")
    local interpreter = config.interpreters[extension]
    if not interpreter then
        print("Unsupported file type: " .. extension)
        return nil, extension
    end
    return interpreter, extension
end
-- Helper function to get current filename with validation
local function get_current_filename()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" then
        print("No filename available")
        return nil
    end
    return filename
end
-- Run entire file in terminal
function M.run_file()
    if not is_valid_buffer() then
        return
    end
    vim.cmd("write")
    local filename = get_current_filename()
    if not filename then
        return
    end
    local interpreter = get_interpreter(filename)
    if not interpreter then
        return
    end

    -- Get just the filename without path for display
    local display_name = vim.fn.fnamemodify(filename, ":t")
    print("Running " .. display_name)

    local cmd = interpreter .. " " .. filename
    require("custom.modules.floating_terminal").toggle_terminal()
    vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd .. "\r")
    end, 10)
end
-- Run file in background (no terminal)
function M.run_background()
    if not is_valid_buffer() then
        return
    end
    vim.cmd("write")
    local filename = get_current_filename()
    if not filename then
        return
    end
    local extension = vim.fn.fnamemodify(filename, ":e")
    local runner_function = config.no_term_runners[extension]
    if runner_function then
        -- Get just the filename without path for display
        local display_name = vim.fn.fnamemodify(filename, ":t")
        print("Running " .. display_name .. " silently")

        local cmd = runner_function(filename)
        vim.cmd("silent !" .. cmd)
    else
        print("No no-terminal runner configured for file type: " .. extension)
    end
end
-- Run selected text/lines in terminal
function M.run_selection()
    if not is_valid_buffer() then
        return
    end

    -- Get current filename first for proper extension detection
    local filename = get_current_filename()
    if not filename then
        print("No filename available for selection running")
        return
    end

    -- Get extension from actual filename, not filetype
    local extension = vim.fn.fnamemodify(filename, ":e")
    local interpreter = config.interpreters[extension]

    if not interpreter then
        print("Unsupported file type for selection running: " .. extension)
        return
    end

    -- Get selected text
    local mode = vim.fn.mode()
    ---@type string[]
    local lines = {}

    -- Check if we're in visual mode or have a previous selection
    if mode:match("[vV]") then
        -- Currently in visual mode - get current selection
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")

        -- Ensure start comes before end
        if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
            start_pos, end_pos = end_pos, start_pos
        end

        -- For Python and Lua, always use complete lines to avoid syntax errors
        if extension == "py" or extension == "lua" then
            local result = vim.fn.getline(start_pos[2], end_pos[2])
            lines = type(result) == "table" and result or { result }
        else
            local result = vim.fn.getline(start_pos[2], end_pos[2])
            lines = type(result) == "table" and result or { result }

            -- Handle partial line selection for other languages
            if #lines == 1 then
                local first_line = lines[1] --[[@as string]]
                lines[1] = string.sub(first_line, start_pos[3], end_pos[3])
            else
                local first_line = lines[1] --[[@as string]]
                local last_line = lines[#lines] --[[@as string]]
                lines[1] = string.sub(first_line, start_pos[3])
                lines[#lines] = string.sub(last_line, 1, end_pos[3])
            end
        end
    else
        -- Not in visual mode - try to get last visual selection
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        -- Check if we have valid selection markers
        if start_pos[2] == 0 or end_pos[2] == 0 then
            print("No selection found - make a visual selection first")
            return
        end

        -- For Python and Lua, always use complete lines to avoid syntax errors
        if extension == "py" or extension == "lua" then
            local result = vim.fn.getline(start_pos[2], end_pos[2])
            lines = type(result) == "table" and result or { result }
        else
            local result = vim.fn.getline(start_pos[2], end_pos[2])
            lines = type(result) == "table" and result or { result }

            -- Handle partial line selection for other languages
            if #lines == 1 then
                local first_line = lines[1] --[[@as string]]
                lines[1] = string.sub(first_line, start_pos[3], end_pos[3])
            else
                local first_line = lines[1] --[[@as string]]
                local last_line = lines[#lines] --[[@as string]]
                lines[1] = string.sub(first_line, start_pos[3])
                lines[#lines] = string.sub(last_line, 1, end_pos[3])
            end
        end
    end

    if #lines == 0 or (lines[1] == "" and #lines == 1) then
        print("No selection found")
        return
    end

    local code = table.concat(lines, "\n")

    -- Check if floating terminal module exists
    local ok, floating_terminal = pcall(require, "custom.modules.floating_terminal")
    if not ok then
        print("Floating terminal module not found")
        return
    end

    floating_terminal.toggle_terminal()

    vim.defer_fn(function()
        local job_id = vim.b.terminal_job_id
        if job_id then
            -- Create temp file using Neovim's built-in temp file function
            local temp_file = vim.fn.tempname() .. "." .. extension
            local file = io.open(temp_file, "w")
            if file then
                file:write(code)
                file:close()

                -- Get current filename for display
                local display_name = vim.fn.fnamemodify(filename, ":t")
                print("Running selection from " .. display_name)

                -- Execute the file (no cleanup - let system handle it)
                local cmd = interpreter .. " " .. temp_file
                vim.api.nvim_chan_send(job_id, cmd .. "\r")
            else
                print("Failed to create temporary file")
            end
        else
            print("Failed to get terminal job ID")
        end
    end, 10)
end
-- Setup keymaps
function M.setup_keymaps()
    vim.keymap.set("n", "<leader>r", M.run_file, { desc = "Run" })
    vim.keymap.set("v", "<leader>r", M.run_selection, { desc = "Run Selection" })
    vim.keymap.set("n", "<leader>R", M.run_background, { desc = "Run Silently" })
end
-- Setup function to configure and initialize
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
    M.setup_keymaps()
end
-- Auto-setup with default configuration
M.setup()
return M

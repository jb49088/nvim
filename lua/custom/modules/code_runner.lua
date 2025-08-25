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
        print("Running " .. display_name .. " detached")

        local cmd = runner_function(filename)
        vim.cmd("silent !" .. cmd)
    else
        print("No no-terminal runner configured for file type: " .. extension)
    end
end

-- Setup keymaps
function M.setup_keymaps()
    vim.keymap.set("n", "<leader>rt", M.run_file, { desc = "Run in Terminal" })
    vim.keymap.set("n", "<leader>rd", M.run_background, { desc = "Run Detached" })
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

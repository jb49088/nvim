-- Unified Code Runner for Neovim
-- Supports running files and selections in terminal or background

local M = {}

-- Configuration
local config = {
    interpreters = {
        py = "python3",
        lua = "lua",
    },
    no_term_runners = {
        py = function(filepath)
            if vim.fn.has("win32") == 1 then
                return 'start /B pythonw.exe "' .. filepath .. '"'
            else
                return 'nohup python3 "' .. filepath .. '" > /dev/null 2>&1 &'
            end
        end,
        lua = function(filepath)
            if vim.fn.has("win32") == 1 then
                return 'start /B lua.exe "' .. filepath .. '"'
            else
                return 'nohup lua "' .. filepath .. '" > /dev/null 2>&1 &'
            end
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

-- Helper function to get visual selection
local function get_visual_selection()
    local mode = vim.fn.mode()
    if mode ~= "v" and mode ~= "V" then
        return nil
    end

    local start_pos = vim.fn.getpos(".")
    local end_pos = vim.fn.getpos("v")
    local start_line = math.min(start_pos[2], end_pos[2])
    local end_line = math.max(start_pos[2], end_pos[2])
    local start_col = math.min(start_pos[3], end_pos[3])
    local end_col = math.max(start_pos[3], end_pos[3])

    local lines = vim.fn.getline(start_line, end_line)

    -- Ensure lines is always a table
    if type(lines) == "string" then
        lines = { lines }
    end

    if #lines == 0 then
        return nil
    end

    -- Handle partial line selections only in character visual mode
    if mode == "v" then
        if #lines == 1 then
            lines[1] = string.sub(lines[1], start_col, end_col)
        else
            lines[1] = string.sub(lines[1], start_col)
            lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end
    end

    return table.concat(lines, "\n")
end

-- Run entire file in terminal
function M.run_file()
    if not is_valid_buffer() then
        return
    end

    vim.cmd("write")
    local filename = vim.api.nvim_buf_get_name(0)

    if filename == "" then
        print("No filename available")
        return
    end

    local interpreter, extension = get_interpreter(filename)
    if not interpreter then
        return
    end

    local cmd = interpreter .. " " .. filename
    require("custom.modules.floating_terminal").toggle_terminal()

    vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd .. "\r")
    end, 10)
end

-- Run selection in REPL
function M.run_selection()
    if not is_valid_buffer() then
        return
    end

    local selected_text = get_visual_selection()
    if not selected_text then
        return
    end

    local filename = vim.api.nvim_buf_get_name(0)
    local interpreter, extension = get_interpreter(filename)
    if not interpreter then
        return
    end

    require("custom.modules.floating_terminal").toggle_terminal()

    vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, interpreter .. "\r")
        vim.defer_fn(function()
            local escaped_text = selected_text:gsub("'", "'\"'\"'")
            vim.api.nvim_chan_send(vim.b.terminal_job_id, escaped_text .. "\r")
        end, 50)
    end, 10)
end

-- Run file in background (no terminal)
function M.run_background()
    if not is_valid_buffer() then
        return
    end

    vim.cmd("write")
    local filename = vim.api.nvim_buf_get_name(0)

    if filename == "" then
        print("No filename available")
        return
    end

    local extension = vim.fn.fnamemodify(filename, ":e")
    local runner_function = config.no_term_runners[extension]

    if runner_function then
        local cmd = runner_function(filename)
        vim.cmd("!" .. cmd)
        print("Running: " .. filename .. " (in background, no terminal)")
    else
        print("No no-terminal runner configured for file type: " .. extension)
    end
end

-- Setup keymaps
function M.setup_keymaps()
    -- Normal mode: run entire file
    vim.keymap.set("n", "<leader>r", M.run_file, { desc = "Run" })

    -- Visual mode: run selection in REPL
    vim.keymap.set({ "v", "x" }, "<leader>r", M.run_selection, { desc = "Run" })

    -- Normal mode: run in background (no terminal)
    vim.keymap.set("n", "<leader>R", M.run_background, { desc = "Run (No Terminal)" })
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

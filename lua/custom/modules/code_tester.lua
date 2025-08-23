-- Unified Code Tester for Neovim
-- Supports running tests for different languages
local M = {}

-- Configuration
local config = {
    test_runners = {
        py = {
            all = "pytest",
            file = "pytest %",
        },
        lua = {
            all = "busted",
            file = "busted %",
        },
    },
}

-- Helper function to check if buffer is valid for testing
local function is_valid_buffer()
    return vim.bo.buftype == ""
end

-- Helper function to get file extension and test runner
local function get_test_runner(filename)
    local extension = vim.fn.fnamemodify(filename, ":e")
    local runner = config.test_runners[extension]
    if not runner then
        print("No test runner configured for file type: " .. extension)
        return nil, extension
    end
    return runner, extension
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

-- Run all tests
function M.run_all_tests()
    if not is_valid_buffer() then
        return
    end

    local filename = get_current_filename()
    if not filename then
        return
    end

    local runner, extension = get_test_runner(filename)
    if not runner then
        return
    end

    print("Running all " .. extension .. " tests")
    local cmd = runner.all

    require("custom.modules.floating_terminal").toggle_terminal()
    vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd .. "\r")
    end, 10)
end

-- Run current file tests
function M.run_file_tests()
    if not is_valid_buffer() then
        return
    end

    vim.cmd("write")
    local filename = get_current_filename()
    if not filename then
        return
    end

    local runner, extension = get_test_runner(filename)
    if not runner then
        return
    end

    -- Get just the filename without path for display
    local display_name = vim.fn.fnamemodify(filename, ":t")
    print("Running tests for " .. display_name)

    -- Replace % with actual filename in the command
    local cmd = runner.file:gsub("%%", filename)

    require("custom.modules.floating_terminal").toggle_terminal()
    vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd .. "\r")
    end, 10)
end

-- Setup keymaps
function M.setup_keymaps()
    vim.keymap.set("n", "<leader>ta", M.run_all_tests, { desc = "Test all" })
    vim.keymap.set("n", "<leader>tf", M.run_file_tests, { desc = "Test current file" })
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

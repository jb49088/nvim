local M = {}

-- Configuration
local config = {
    interpreters = {
        py = "python3",
        lua = "lua",
        sh = "bash",
        ps1 = "pwsh",
    },
    -- Zellij floating pane options
    zellij_opts = {
        width = "80%",
        height = "80%",
        x = "10%",
        y = "15%",
    },
}

-- Helper functions (same as before)
local function is_valid_buffer()
    return vim.bo.buftype == ""
end

local function get_interpreter(filename)
    local extension = vim.fn.fnamemodify(filename, ":e")
    local interpreter = config.interpreters[extension]
    if not interpreter then
        print("Unsupported file type: " .. extension)
        return nil, extension
    end
    return interpreter, extension
end

local function get_current_filename()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" then
        print("No filename available")
        return nil
    end
    return filename
end

-- Check if we're in a Zellij session
local function in_zellij()
    return os.getenv("ZELLIJ") ~= nil
end

-- Run file in Zellij floating pane (Fixed Option 3)
function M.run_file()
    if not is_valid_buffer() then
        return
    end

    if not in_zellij() then
        print("Not in a Zellij session")
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

    local display_name = vim.fn.fnamemodify(filename, ":t")
    print("Running " .. display_name .. " in Zellij")

    -- Create floating pane and run command in one go
    local opts = config.zellij_opts

    local zellij_cmd = string.format(
        'zellij run --floating --width "%s" --height "%s" --x "%s" --y "%s" -- %s "%s"',
        opts.width,
        opts.height,
        opts.x,
        opts.y,
        interpreter,
        filename
    )

    -- Execute the command
    vim.fn.system(zellij_cmd)
end

-- Run in background (unchanged)
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
    local no_term_runners = {
        py = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B pythonw.exe "' .. filepath .. '"'
                or 'nohup python3 "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
        lua = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B lua.exe "' .. filepath .. '"'
                or 'nohup lua "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
        sh = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B bash.exe "' .. filepath .. '"'
                or 'nohup bash "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
        ps1 = function(filepath)
            return vim.fn.has("win32") == 1 and 'start /B pwsh.exe "' .. filepath .. '"'
                or 'nohup pwsh "' .. filepath .. '" > /dev/null 2>&1 &'
        end,
    }

    local runner_function = no_term_runners[extension]
    if runner_function then
        local display_name = vim.fn.fnamemodify(filename, ":t")
        print("Running " .. display_name .. " detached")
        local cmd = runner_function(filename)
        vim.cmd("silent !" .. cmd)
    else
        print("No background runner configured for file type: " .. extension)
    end
end

-- Setup keymaps
function M.setup_keymaps()
    vim.keymap.set("n", "<leader>rt", M.run_file, { desc = "Run in Terminal" })
    vim.keymap.set("n", "<leader>rd", M.run_background, { desc = "Run Detached" })
end

-- Setup function
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
    M.setup_keymaps()
end

-- Auto-setup
M.setup()

return M

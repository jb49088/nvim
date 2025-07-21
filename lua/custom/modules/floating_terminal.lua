local M = {}

-- State to track the floating terminal
local float_term = {
    buf = nil,
    win = nil,
    job_id = nil,
}

-- Set up global keymap for Ctrl+\ to work in all modes
vim.keymap.set({ "n", "i", "v", "t" }, "<C-\\>", function()
    require("custom.modules.floating_terminal").toggle_terminal()
end, { noremap = true, silent = true, desc = "Floating Terminal" })

-- Set up alternate keymap for <leader>tf
vim.keymap.set("n", "<leader>TF", function()
    require("custom.modules.floating_terminal").toggle_terminal()
end, { noremap = true, silent = true, desc = "Floating Terminal" })

-- Function to clean up terminal state
local function cleanup_terminal()
    if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
        vim.api.nvim_win_close(float_term.win, true)
    end
    if float_term.buf and vim.api.nvim_buf_is_valid(float_term.buf) then
        vim.api.nvim_buf_delete(float_term.buf, { force = true })
    end
    float_term.buf = nil
    float_term.win = nil
    float_term.job_id = nil
end

-- Function to create or toggle the floating terminal
function M.toggle_terminal()
    -- If terminal is already open, close it
    if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
        vim.api.nvim_win_close(float_term.win, true)
        float_term.win = nil
        return
    end

    -- Set fixed window size
    local win_width = 135
    local win_height = 29

    -- Get editor dimensions for centering
    local width = vim.o.columns
    local height = vim.o.lines

    -- Calculate starting position to center the window
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- Window configuration
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
    }

    -- Create buffer if it doesn't exist or is invalid
    if not float_term.buf or not vim.api.nvim_buf_is_valid(float_term.buf) then
        float_term.buf = vim.api.nvim_create_buf(false, true)

        -- Set up autocommand to handle terminal exit
        vim.api.nvim_create_autocmd("TermClose", {
            buffer = float_term.buf,
            callback = function()
                -- Close the terminal automatically when process exits
                vim.schedule(function()
                    cleanup_terminal()
                end)
            end,
            once = true,
        })
    end

    -- Create the floating window
    float_term.win = vim.api.nvim_open_win(float_term.buf, true, opts)

    -- Start terminal if buffer is empty or job doesn't exist
    if
        not float_term.job_id
        or (
            vim.api.nvim_buf_line_count(float_term.buf) == 1
            and vim.api.nvim_buf_get_lines(float_term.buf, 0, -1, false)[1] == ""
        )
    then
        float_term.job_id = vim.fn.termopen(vim.env.SHELL or vim.o.shell or "bash", {
            on_exit = function(job_id, exit_code, event_type)
                -- This callback runs when the terminal process exits
                vim.schedule(function()
                    cleanup_terminal()
                end)
            end,
        })
    end

    -- Enter insert mode automatically
    vim.cmd("startinsert")

    -- Set buffer options
    vim.bo[float_term.buf].filetype = "terminal"
end

return M

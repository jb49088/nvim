-- Keep track of the last non-floating window
local last_normal_win = nil

-- Check if a window is floating
local function is_floating(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
end

-- Check if a window is valid (exists and has content)
local function is_valid_float(win)
    if not vim.api.nvim_win_is_valid(win) then
        return false
    end

    local config = vim.api.nvim_win_get_config(win)
    if config.focusable == false then
        return false
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local line_count = vim.api.nvim_buf_line_count(buf)
    if line_count <= 1 then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #lines == 1 and (lines[1] == "" or lines[1]:match("^%s*$")) then
            return false
        end
    end

    return true
end

-- Get all floating windows in current tabpage, sorted by position (top to bottom)
local function get_floating_windows()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local floating_wins = {}

    for _, win in ipairs(wins) do
        if is_floating(win) and is_valid_float(win) then
            local config = vim.api.nvim_win_get_config(win)
            table.insert(floating_wins, {
                win = win,
                row = config.row or 0,
                col = config.col or 0,
            })
        end
    end

    -- Sort by row position (top to bottom), then by column (left to right)
    table.sort(floating_wins, function(a, b)
        if a.row == b.row then
            return a.col < b.col
        end
        return a.row < b.row
    end)

    -- Extract just the window IDs
    local sorted_wins = {}
    for _, win_info in ipairs(floating_wins) do
        table.insert(sorted_wins, win_info.win)
    end

    return sorted_wins
end

-- Toggle between normal buffer and floating windows
local function FloatCycle()
    local current_win = vim.api.nvim_get_current_win()
    local floating_wins = get_floating_windows()

    -- Early exit if no floating windows
    if #floating_wins == 0 then
        vim.notify("No floating windows available")
        return
    end

    if is_floating(current_win) then
        -- Find current float index and get next one
        local current_index = 1
        for i, win in ipairs(floating_wins) do
            if win == current_win then
                current_index = i
                break
            end
        end

        local next_index = current_index % #floating_wins + 1

        -- If we've cycled through all, go back to normal window
        if next_index == 1 and current_index == #floating_wins then
            if last_normal_win and vim.api.nvim_win_is_valid(last_normal_win) then
                vim.api.nvim_set_current_win(last_normal_win)
            end
        else
            -- Go to next floating window
            vim.api.nvim_set_current_win(floating_wins[next_index])
        end
    else
        -- We're in a normal window, remember it and go to first floating window
        last_normal_win = current_win
        vim.api.nvim_set_current_win(floating_wins[1])
    end
end

vim.keymap.set("n", "<leader>ww", FloatCycle, { desc = "Cycle Floating Windows" })

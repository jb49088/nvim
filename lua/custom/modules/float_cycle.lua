-- TODO: fix the branch lualine component disappearing on cycle

-- Keep track of the last non-floating window
local last_normal_win = nil
local float_cycle_index = 1 -- Track which float we're on in the cycle

-- Check if a window is floating
local function is_floating(win)
    local config = vim.api.nvim_win_get_config(win)
    return config.relative ~= ""
end

-- Get all floating windows in current tabpage, sorted by position (top to bottom)
local function get_floating_windows()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local floating_wins = {}
    for _, win in ipairs(wins) do
        if is_floating(win) then
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

-- Get the current floating window index
local function get_current_float_index()
    local floating_wins = get_floating_windows()
    local current_win = vim.api.nvim_get_current_win()
    for i, win in ipairs(floating_wins) do
        if win == current_win then
            return i
        end
    end
    return 1
end

-- Toggle between normal buffer and floating windows
local function FloatCycle()
    local current_win = vim.api.nvim_get_current_win()
    local current_is_floating = is_floating(current_win)
    local floating_wins = get_floating_windows()

    -- Early exit if no floating windows
    if #floating_wins == 0 then
        print("No floating windows available")
        return
    end

    -- Initialize last_normal_win if it's nil and we're in a normal window
    if not current_is_floating and not last_normal_win then
        last_normal_win = current_win
    end

    local target_win = nil

    if current_is_floating then
        -- We're in a floating window
        if #floating_wins > 1 then
            -- Multiple floating windows - cycle through them
            local current_index = get_current_float_index()
            local next_index = (current_index % #floating_wins) + 1

            -- If we've cycled through all floating windows, go back to normal buffer
            if next_index > #floating_wins then
                float_cycle_index = 1 -- Reset for next cycle
                if last_normal_win and vim.api.nvim_win_is_valid(last_normal_win) then
                    target_win = last_normal_win
                else
                    -- Fallback: find any non-floating window
                    local wins = vim.api.nvim_tabpage_list_wins(0)
                    for _, win in ipairs(wins) do
                        if not is_floating(win) then
                            target_win = win
                            last_normal_win = win -- Remember this window for next time
                            break
                        end
                    end
                end
            else
                -- Continue cycling through floating windows
                target_win = floating_wins[next_index]
            end
        else
            -- Only one floating window - go back to normal buffer
            if last_normal_win and vim.api.nvim_win_is_valid(last_normal_win) then
                target_win = last_normal_win
            else
                -- Fallback: find any non-floating window
                local wins = vim.api.nvim_tabpage_list_wins(0)
                for _, win in ipairs(wins) do
                    if not is_floating(win) then
                        target_win = win
                        last_normal_win = win -- Remember this window for next time
                        break
                    end
                end
            end
        end
    else
        -- We're in a normal window, remember it and go to floating window
        last_normal_win = current_win
        float_cycle_index = 1 -- Reset cycle tracking
        -- Start from the topmost floating window
        target_win = floating_wins[1]
    end

    if target_win then
        -- Use vim.schedule to defer the redrawstatus
        -- This ensures the window change is fully processed before redraw
        vim.api.nvim_set_current_win(target_win)
        vim.schedule(function()
            vim.cmd("redrawstatus")
        end)
    end
end

vim.keymap.set("n", "<leader>ww", FloatCycle, { desc = "Cycle Floating Windows" })

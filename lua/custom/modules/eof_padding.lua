-- Enhanced EOF padding that applies to all visible buffers (OPTIMIZED - NO DELAY)
local mode_disabled = false
local initial_scrolloff = vim.o.scrolloff
local scrolloff = vim.o.scrolloff
local opts = {
    pattern = "*",
    insert_mode = true,
    floating = true,
    disabled_filetypes = {},
    disabled_modes = { "t", "nt" },
}

-- Cache for expensive calculations
local win_cache = {}
local function get_win_cache_key(win_id, buf_id)
    return tostring(win_id) .. "_" .. tostring(buf_id)
end

-- Clear cache when window or buffer changes
local function clear_win_cache()
    win_cache = {}
end

-- Check and apply EOF scrolloff for the current window (optimized)
local function check_eof_scrolloff(ev)
    -- Early exit checks (cheapest operations first)
    if mode_disabled then
        return
    end

    local filetype = vim.o.filetype
    if opts.disabled_filetypes[filetype] then
        return
    end

    if opts.floating == false then
        local curr_win = vim.api.nvim_win_get_config(0)
        if curr_win.relative ~= "" then
            return
        end
    end

    if ev.event == "WinScrolled" then
        local win_id = vim.api.nvim_get_current_win()
        local win_event = vim.v.event[tostring(win_id)]
        if win_event ~= nil and win_event.topline <= 0 then
            return
        end
    end

    -- Fast path: check if we're near EOF before expensive visual operations
    local cursor_line = vim.fn.line(".")
    local total_lines = vim.fn.line("$")
    local lines_from_eof = total_lines - cursor_line

    -- If we're far from EOF, no need for expensive winline() call
    if lines_from_eof > scrolloff + 3 then -- Small buffer to reduce edge case checks
        return
    end

    -- Only do expensive visual calculations when actually near EOF
    local win_height = vim.fn.winheight(0)
    local win_cur_line = vim.fn.winline()
    local visual_distance_to_eof = win_height - win_cur_line

    if visual_distance_to_eof < scrolloff then
        -- Cache current view to avoid redundant winsaveview calls
        local win_view = vim.fn.winsaveview()
        local new_topline = win_view.topline + scrolloff - visual_distance_to_eof

        -- Only update if topline actually needs to change
        if new_topline ~= win_view.topline then
            vim.fn.winrestview({
                skipcol = 0,
                topline = new_topline,
            })
        end
    end
end

-- Optimized version for specific window
local function check_eof_scrolloff_for_win(win_id)
    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win_id)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Use cache key for this window/buffer combo
    local cache_key = get_win_cache_key(win_id, buf)

    -- Safely execute in the window's context
    pcall(vim.api.nvim_win_call, win_id, function()
        -- Early exit checks
        if mode_disabled then
            return
        end

        local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
        if opts.disabled_filetypes[filetype] then
            return
        end

        if opts.floating == false then
            local curr_win = vim.api.nvim_win_get_config(0)
            if curr_win.relative ~= "" then
                return
            end
        end

        -- Fast EOF distance check
        local cursor_line = vim.fn.line(".")
        local total_lines = vim.fn.line("$")
        local lines_from_eof = total_lines - cursor_line

        if lines_from_eof > scrolloff + 3 then
            return
        end

        -- Apply EOF padding logic only when needed
        local win_height = vim.fn.winheight(0)
        local win_cur_line = vim.fn.winline()
        local visual_distance_to_eof = win_height - win_cur_line

        if visual_distance_to_eof < scrolloff then
            local win_view = vim.fn.winsaveview()
            local new_topline = win_view.topline + scrolloff - visual_distance_to_eof

            if new_topline ~= win_view.topline then
                vim.fn.winrestview({
                    skipcol = 0,
                    topline = new_topline,
                })
            end
        end
    end)
end

-- Apply EOF padding to all visible buffers (with reduced redundancy)
local function apply_eof_padding_to_visible_buffers()
    local visible_wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win in ipairs(visible_wins) do
        check_eof_scrolloff_for_win(win)
    end
end

local vim_resized_cb = function()
    clear_win_cache()
    scrolloff = vim.o.scrolloff -- Just use whatever scrolloff is set to
end

-- Convert disabled arrays to hashmaps for O(1) lookup (keep this optimization)
local disabled_filetypes_hashmap = {}
for _, val in pairs(opts.disabled_filetypes) do
    disabled_filetypes_hashmap[val] = true
end
opts.disabled_filetypes = disabled_filetypes_hashmap

local disabled_modes_hashmap = {}
for _, val in pairs(opts.disabled_modes) do
    disabled_modes_hashmap[val] = true
end
opts.disabled_modes = disabled_modes_hashmap

-- Build autocmd event list
local autocmds = { "CursorMoved", "WinScrolled" }
if opts.insert_mode then
    table.insert(autocmds, "CursorMovedI")
end

local eof_padding = vim.api.nvim_create_augroup("eof_padding", { clear = true })

-- Mode change tracking (with cache clear)
vim.api.nvim_create_autocmd("ModeChanged", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local current_mode = vim.api.nvim_get_mode().mode
        mode_disabled = opts.disabled_modes[current_mode] == true
        clear_win_cache()
    end,
})

-- Window resize and buffer enter (with cache clear)
vim.api.nvim_create_autocmd({ "VimResized", "BufEnter" }, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        clear_win_cache()
        vim_resized_cb()
    end,
})

-- Tab switching
vim.api.nvim_create_autocmd("TabEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        clear_win_cache()
        apply_eof_padding_to_visible_buffers()
    end,
})

-- Buffer window enter (optimized with early exits)
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
        local buf_type = vim.api.nvim_get_option_value("buftype", { buf = 0 })

        -- Early exit for non-file buffers
        if
            buf_type == "terminal"
            or buf_type == "nofile"
            or buf_type == "prompt"
            or buf_ft == "terminal"
            or buf_ft == "noice"
            or buf_ft == "snacks_notif"
            or vim.api.nvim_buf_get_name(0) == ""
        then
            return
        end

        clear_win_cache()
        apply_eof_padding_to_visible_buffers()
    end,
})

-- Main cursor movement and scrolling handler (immediate, no delay)
vim.api.nvim_create_autocmd(autocmds, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = check_eof_scrolloff,
})

-- Window switching (with cache management)
vim.api.nvim_create_autocmd("WinEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local buf_type = vim.api.nvim_get_option_value("buftype", { buf = 0 })
        local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

        -- Early exit for non-file buffers
        if
            buf_type == "terminal"
            or buf_type == "nofile"
            or buf_type == "prompt"
            or buf_ft == "terminal"
            or buf_ft == "noice"
            or buf_ft == "snacks_notif"
        then
            return
        end

        clear_win_cache()
        apply_eof_padding_to_visible_buffers()
    end,
})

-- Initialize system
vim_resized_cb()
vim.defer_fn(function()
    vim_resized_cb()
    apply_eof_padding_to_visible_buffers()
end, 0)

-- Session loading
vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = eof_padding,
    callback = function()
        vim.defer_fn(function()
            clear_win_cache()
            apply_eof_padding_to_visible_buffers()
        end, 50)
    end,
})

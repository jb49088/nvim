-- Enhanced EOF padding that applies to all visible buffers
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

-- Check and apply EOF scrolloff for the current window
local function check_eof_scrolloff(ev)
    local filetype_disabled = opts.disabled_filetypes[vim.o.filetype] == true
    if mode_disabled or filetype_disabled then
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
    local win_height = vim.fn.winheight(0)
    local win_cur_line = vim.fn.winline()
    local visual_distance_to_eof = win_height - win_cur_line
    if visual_distance_to_eof < scrolloff then
        local win_view = vim.fn.winsaveview()
        vim.fn.winrestview({
            skipcol = 0,
            topline = win_view.topline + scrolloff - visual_distance_to_eof,
        })
    end
end

-- Check and apply EOF scrolloff for a specific window by ID
local function check_eof_scrolloff_for_win(win_id)
    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win_id)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Safely execute in the window's context
    pcall(vim.api.nvim_win_call, win_id, function()
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
        local filetype_disabled = opts.disabled_filetypes[filetype] == true

        if mode_disabled or filetype_disabled then
            return
        end

        if opts.floating == false then
            local curr_win = vim.api.nvim_win_get_config(0)
            if curr_win.relative ~= "" then
                return
            end
        end

        -- Apply EOF padding logic
        local win_height = vim.fn.winheight(0)
        local win_cur_line = vim.fn.winline()
        local visual_distance_to_eof = win_height - win_cur_line
        if visual_distance_to_eof < scrolloff then
            local win_view = vim.fn.winsaveview()
            vim.fn.winrestview({
                skipcol = 0,
                topline = win_view.topline + scrolloff - visual_distance_to_eof,
            })
        end
    end)
end

-- Apply EOF padding to all visible buffers in the current tabpage
local function apply_eof_padding_to_visible_buffers()
    local visible_wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win in ipairs(visible_wins) do
        check_eof_scrolloff_for_win(win)
    end
end

-- Dynamically adjust scrolloff based on window height
local vim_resized_cb = function()
    local win_height = vim.fn.winheight(0)
    local half_win_height = math.floor(win_height / 2)
    if initial_scrolloff < half_win_height then
        if vim.o.scrolloff < initial_scrolloff then
            vim.o.scrolloff = initial_scrolloff
            scrolloff = initial_scrolloff
        end
        return
    end
    scrolloff = half_win_height
    vim.o.scrolloff = win_height % 2 == 0 and scrolloff - 1 or scrolloff
end

-- Convert disabled arrays to hashmaps for O(1) lookup
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

-- Build autocmd event list based on configuration
local autocmds = { "CursorMoved", "WinScrolled" }
if opts.insert_mode then
    table.insert(autocmds, "CursorMovedI")
end

local eof_padding = vim.api.nvim_create_augroup("eof_padding", { clear = true })

-- Track mode changes to enable/disable EOF padding
vim.api.nvim_create_autocmd("ModeChanged", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local current_mode = vim.api.nvim_get_mode().mode
        mode_disabled = opts.disabled_modes[current_mode] == true
    end,
})

-- Recalculate scrolloff on window resize and buffer enter
vim.api.nvim_create_autocmd({ "VimResized", "BufEnter" }, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = vim_resized_cb,
})

-- Apply padding to all visible buffers when switching tabs
vim.api.nvim_create_autocmd("TabEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = apply_eof_padding_to_visible_buffers,
})

-- Apply padding selectively on buffer window enter
-- Excludes UI buffers and terminals to prevent unwanted scrolling
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
        local buf_type = vim.api.nvim_get_option_value("buftype", { buf = 0 })

        -- Skip non-file buffers to avoid interfering with UI elements
        if
            buf_type == "terminal"
            or buf_type == "nofile"
            or buf_type == "prompt"
            or buf_ft == "terminal"
            or buf_ft == "noice"
            or buf_ft == "snacks_notif"
            or buf_name == ""
        then
            return
        end

        apply_eof_padding_to_visible_buffers()
    end,
})

-- Apply EOF padding on cursor movement and scrolling events
vim.api.nvim_create_autocmd(autocmds, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = check_eof_scrolloff,
})

-- Initialize EOF padding system
vim_resized_cb()
vim.defer_fn(function()
    vim_resized_cb()
    -- Apply padding to all visible windows on startup for seamless loading
    apply_eof_padding_to_visible_buffers()
end, 0)

-- Additional initialization for session loading
vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = eof_padding,
    callback = function()
        vim.defer_fn(function()
            apply_eof_padding_to_visible_buffers()
        end, 50)
    end,
})

-- Ensure all windows get padding when switching between windows
vim.api.nvim_create_autocmd("WinEnter", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local buf_type = vim.api.nvim_get_option_value("buftype", { buf = 0 })
        local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

        -- Skip if entering a non-file buffer
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

        -- Apply to all visible windows to ensure consistency
        apply_eof_padding_to_visible_buffers()
    end,
})

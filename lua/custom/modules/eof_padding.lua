-- Simplified EOF padding - current window only
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

-- Check and apply EOF scrolloff for the current window only
local function check_eof_scrolloff(ev)
    -- Always sync scrolloff with current vim setting first
    scrolloff = vim.o.scrolloff

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

    if ev and ev.event == "WinScrolled" then
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

-- Build autocmd event list
local autocmds = { "CursorMoved", "WinScrolled" }
if opts.insert_mode then
    table.insert(autocmds, "CursorMovedI")
end

local eof_padding = vim.api.nvim_create_augroup("eof_padding", { clear = true })

-- Mode change tracking
vim.api.nvim_create_autocmd("ModeChanged", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local current_mode = vim.api.nvim_get_mode().mode
        mode_disabled = opts.disabled_modes[current_mode] == true
    end,
})

-- Window resize and buffer enter
vim.api.nvim_create_autocmd({ "VimResized", "BufEnter" }, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = vim_resized_cb,
})

-- Buffer window enter with early exits for non-file buffers
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

        -- Just trigger EOF check for current window
        check_eof_scrolloff()
    end,
})

-- Main cursor movement and scrolling handler
vim.api.nvim_create_autocmd(autocmds, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = check_eof_scrolloff,
})

-- Window switching - recalculate scrolloff for new window
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

        -- Recalculate scrolloff for the new window and apply EOF padding
        vim_resized_cb()
        check_eof_scrolloff()
    end,
})

-- Session loading - recalculate and apply immediately
vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = eof_padding,
    callback = function()
        vim.defer_fn(function()
            vim_resized_cb()
            check_eof_scrolloff()
        end, 0)
    end,
})

-- Initialize system
vim_resized_cb()

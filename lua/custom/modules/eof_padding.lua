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

-- Your original function - keeping it exactly as it was
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

-- Function to check and apply EOF scrolloff for a specific window (adapted from your original)
local function check_eof_scrolloff_for_win(win_id)
    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win_id)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Use pcall to safely execute in window context
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

        -- Use your exact original logic
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

-- Function to apply EOF padding to all visible buffers in current tabpage
local function apply_eof_padding_to_visible_buffers()
    local visible_wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win in ipairs(visible_wins) do
        check_eof_scrolloff_for_win(win)
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

-- Convert arrays to hashmaps for faster lookup
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

local autocmds = { "CursorMoved", "WinScrolled" }
if opts.insert_mode then
    table.insert(autocmds, "CursorMovedI")
end

local eof_padding = vim.api.nvim_create_augroup("eof_padding", { clear = true })

vim.api.nvim_create_autocmd("ModeChanged", {
    group = eof_padding,
    pattern = opts.pattern,
    callback = function()
        local current_mode = vim.api.nvim_get_mode().mode
        mode_disabled = opts.disabled_modes[current_mode] == true
    end,
})

vim.api.nvim_create_autocmd({ "VimResized", "BufEnter" }, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = vim_resized_cb,
})

-- Apply padding to all visible buffers on tab/buffer changes
vim.api.nvim_create_autocmd({ "TabEnter", "BufWinEnter" }, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = apply_eof_padding_to_visible_buffers,
})

-- Your original autocmds for cursor movement (only affects current window)
vim.api.nvim_create_autocmd(autocmds, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = check_eof_scrolloff,
})

-- Initial setup
vim_resized_cb()
vim.defer_fn(function()
    vim_resized_cb()
    apply_eof_padding_to_visible_buffers()
end, 0)

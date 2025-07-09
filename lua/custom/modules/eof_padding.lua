local mode_disabled = false
local initial_scrolloff = vim.o.scrolloff
local scrolloff = vim.o.scrolloff

-- Configuration - edit these directly
local disabled_filetypes = { "terminal" }
local disabled_modes = { "t", "nt" }

-- Convert arrays to hashmaps for faster lookup
local disabled_filetypes_map = {}
for _, ft in pairs(disabled_filetypes) do
    disabled_filetypes_map[ft] = true
end

local disabled_modes_map = {}
for _, mode in pairs(disabled_modes) do
    disabled_modes_map[mode] = true
end

-- Main EOF scrolling logic
local function check_eof_scrolloff(ev)
    -- Check if current filetype or mode is disabled
    if disabled_filetypes_map[vim.o.filetype] or mode_disabled then
        return
    end

    -- Handle WinScrolled event specifics - this prevents the locking issue
    if ev and ev.event == "WinScrolled" then
        local win_id = vim.api.nvim_get_current_win()
        local win_event = vim.v.event[tostring(win_id)]
        if win_event ~= nil and win_event.topline <= 0 then
            return
        end
    end

    -- Calculate distances and adjust view if needed
    local win_height = vim.fn.winheight(0)
    local win_cur_line = vim.fn.winline()
    local visual_distance_to_eof = win_height - win_cur_line

    -- If we're close to EOF, add padding by adjusting the view
    if visual_distance_to_eof < scrolloff then
        local win_view = vim.fn.winsaveview()
        vim.fn.winrestview({
            skipcol = 0,
            topline = win_view.topline + scrolloff - visual_distance_to_eof,
        })
    end
end

-- Handle window resize events
local function on_vim_resized()
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

-- Initialize the module
local group = vim.api.nvim_create_augroup("EOFPadding", { clear = true })

-- Defer all initialization until after Vim has fully started
vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        -- Track mode changes
        vim.api.nvim_create_autocmd("ModeChanged", {
            group = group,
            pattern = "*",
            callback = function()
                mode_disabled = disabled_modes_map[vim.api.nvim_get_mode().mode] == true
            end,
        })

        -- Handle window resize and buffer enter - key difference: pattern = "*"
        vim.api.nvim_create_autocmd({ "VimResized", "BufEnter" }, {
            group = group,
            pattern = "*",
            callback = on_vim_resized,
        })

        -- Main functionality - works in insert mode and all cursor movements
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinScrolled" }, {
            group = group,
            pattern = "*",
            callback = check_eof_scrolloff,
        })

        -- Initialize
        on_vim_resized()
        vim.defer_fn(on_vim_resized, 0)
    end,
})

-- TODO: add eof padding to inactive but visible buffers

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
for _, val in pairs(opts.disabled_filetypes) do -- Fixed syntax error
    disabled_filetypes_hashmap[val] = true
end
opts.disabled_filetypes = disabled_filetypes_hashmap

local disabled_modes_hashmap = {}
for _, val in pairs(opts.disabled_modes) do -- Fixed syntax error
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

vim.api.nvim_create_autocmd(autocmds, {
    group = eof_padding,
    pattern = opts.pattern,
    callback = check_eof_scrolloff,
})

vim_resized_cb()
vim.defer_fn(vim_resized_cb, 0)

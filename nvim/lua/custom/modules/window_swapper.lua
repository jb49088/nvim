-- ================================================================================
-- =                                WINDOW SWAPPER                                =
-- ================================================================================

local M = {}
local marked_window = nil

local function mark_window()
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_get_current_buf()
    marked_window = {
        win_id = win_id,
        buf_id = buf_id,
    }
    print("Window marked for swapping")
end

local function swap_window()
    if not marked_window then
        print("No window marked for swapping")
        return
    end

    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()

    if current_win == marked_window.win_id then
        print("Cannot swap window with itself")
        marked_window = nil
        return
    end

    if not vim.api.nvim_win_is_valid(marked_window.win_id) then
        print("Marked window no longer exists")
        marked_window = nil
        return
    end

    -- Get the buffer from the marked window
    local marked_buf = vim.api.nvim_win_get_buf(marked_window.win_id)

    -- Swap the buffers
    vim.api.nvim_win_set_buf(current_win, marked_buf)
    vim.api.nvim_win_set_buf(marked_window.win_id, current_buf)

    print("Windows swapped")
    marked_window = nil
end

local keymap_key = nil
local update_keymap_desc

local function swap()
    if marked_window then
        swap_window()
    else
        mark_window()
    end
    update_keymap_desc()
end

update_keymap_desc = function()
    if not keymap_key then
        return
    end
    local desc = marked_window and "Swap with Marked Window" or "Mark Window for Swapping"
    vim.keymap.set("n", keymap_key, swap, { desc = desc })
end

function M.setup(opts)
    opts = opts or {}
    keymap_key = opts.keymap or "<leader>ws"
    update_keymap_desc()
end

M.swap = swap
M.setup()

return M

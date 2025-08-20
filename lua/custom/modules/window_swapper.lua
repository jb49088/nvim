-- lua/custom/modules/window_swapper.lua

local M = {}

-- Store the marked window info
local marked_window = nil

-- Mark the current window for swapping
local function mark_window()
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_get_current_buf()

    marked_window = {
        win_id = win_id,
        buf_id = buf_id,
    }

    print("Window marked for swapping")
end

-- Swap the current window with the marked window
local function swap_window()
    if not marked_window then
        print("No window marked for swapping")
        return
    end

    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()

    -- Don't swap with itself
    if current_win == marked_window.win_id then
        print("Cannot swap window with itself")
        marked_window = nil
        return
    end

    -- Check if the marked window still exists
    if not vim.api.nvim_win_is_valid(marked_window.win_id) then
        print("Marked window no longer exists")
        marked_window = nil
        return
    end

    -- Perform the swap
    vim.api.nvim_win_set_buf(marked_window.win_id, current_buf)
    vim.api.nvim_win_set_buf(current_win, marked_window.buf_id)

    print("Windows swapped!")
    marked_window = nil
end

-- Store the keymap for dynamic description updates
local keymap_key = nil

-- Forward declaration
local update_keymap_desc

-- Swap: mark if nothing marked, swap if something is marked
local function swap()
    if marked_window then
        swap_window()
    else
        mark_window()
    end
    -- Update description after state change
    update_keymap_desc()
end

-- Update the keymap description based on state
update_keymap_desc = function()
    if not keymap_key then
        return
    end

    local desc = marked_window and "Swap with Marked Window" or "Mark Window for Swapping"
    vim.keymap.set("n", keymap_key, swap, { desc = desc })
end

-- Setup function to create keymaps
function M.setup(opts)
    opts = opts or {}

    -- Default keymap
    keymap_key = opts.keymap or "<leader>ws"

    -- Set up initial keymap
    update_keymap_desc()
end

-- Export functions for manual use
M.swap = swap

-- Auto-setup with default keymaps if no setup() is called
M.setup()

return M

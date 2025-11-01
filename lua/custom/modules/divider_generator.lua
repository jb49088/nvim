local M = {}

function M.create_box_divider()
    local line = vim.api.nvim_get_current_line()
    local text = line:match("^%s*(.-)%s*$") -- trim whitespace
    text = text:upper() -- capitalize the text
    local width = 80
    local text_len = #text
    local inner_width = width - 2 -- account for the = on each side
    local left_pad = math.floor((inner_width - text_len) / 2)
    local right_pad = inner_width - text_len - left_pad
    local border = string.rep("=", width)
    local centered = "=" .. string.rep(" ", left_pad) .. text .. string.rep(" ", right_pad) .. "="
    local row = vim.api.nvim_win_get_cursor(0)[1]
    -- Replace current line and add borders
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
        border,
        centered,
        border,
    })
    -- Comment the divider lines using the built-in commenting
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    vim.cmd("normal! Vjj")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gc", true, false, true), "x", false)
    -- Move cursor to bottom line of divider, far left
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
end

function M.create_line_divider()
    local line = vim.api.nvim_get_current_line()
    local text = line:match("^%s*(.-)%s*$") -- trim whitespace
    text = text:upper() -- capitalize the text
    local width = 80
    local text_len = #text
    local padding = math.floor((width - text_len - 2) / 2) -- account for space on each side
    local left_dashes = padding
    local right_dashes = width - text_len - 2 - left_dashes
    local centered = string.rep("=", left_dashes) .. " " .. text .. " " .. string.rep("=", right_dashes)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    -- Replace current line with divider
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { centered })
    -- Comment the divider line using the built-in commenting
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    vim.cmd("normal! V")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gc", true, false, true), "x", false)
    -- Move cursor to end of line
    vim.api.nvim_win_set_cursor(0, { row, #centered })
end

vim.keymap.set("n", "<leader>Db", M.create_box_divider, { desc = "Box Divider" })
vim.keymap.set("n", "<leader>Dl", M.create_line_divider, { desc = "Line Divider" })

return M

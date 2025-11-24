-- ================================================================================
-- =                              TODO COMMENTOR                                  =
-- ================================================================================

local M = {}

local function insert_todo_comment(tag)
    local line = vim.api.nvim_get_current_line()
    local text = line:match("^%s*(.-)%s*$") -- trim whitespace
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local comment = "#  " .. tag .. ": "

    if text == "" then
        -- No text on line, insert comment and enter insert mode
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { comment })
        vim.api.nvim_win_set_cursor(0, { row, #comment })
        vim.cmd("startinsert!")
    else
        -- Text exists, append it after the comment
        local new_line = comment .. text
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
        vim.api.nvim_win_set_cursor(0, { row, 0 })
    end
end

function M.perf()
    insert_todo_comment("PERF")
end

function M.hack()
    insert_todo_comment("HACK")
end

function M.todo()
    insert_todo_comment("TODO")
end

function M.note()
    insert_todo_comment("NOTE")
end

function M.fix()
    insert_todo_comment("FIX")
end

function M.warning()
    insert_todo_comment("WARNING")
end

vim.keymap.set("n", "<leader>Cp", M.perf, { desc = "PERF Todo" })
vim.keymap.set("n", "<leader>Ch", M.hack, { desc = "HACK Todo" })
vim.keymap.set("n", "<leader>Ct", M.todo, { desc = "TODO Todo" })
vim.keymap.set("n", "<leader>Cn", M.note, { desc = "NOTE Todo" })
vim.keymap.set("n", "<leader>Cf", M.fix, { desc = "FIX Todo" })
vim.keymap.set("n", "<leader>Cw", M.warning, { desc = "WARNING Todo" })

return M

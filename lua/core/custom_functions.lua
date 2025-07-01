-- Delete line if empty, otherwise mimics default backspace
function DelEmptyLine()
    local line = vim.api.nvim_get_current_line()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local total_lines = vim.api.nvim_buf_line_count(0)

    if line:match("^%s*$") then
        vim.cmd('normal! "_dd')
        if line_num < total_lines then
            vim.cmd("normal! k")
        end
    else
        vim.cmd("normal! h")
    end
end

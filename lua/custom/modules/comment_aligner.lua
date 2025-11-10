-- ================================================================================
-- =                               COMMENT ALIGNER                                =
-- ================================================================================

local M = {}

function M.align_comments()
    -- Get visual selection range
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    -- Get all lines in selection
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    -- Find the longest line (before the # comment)
    local max_length = 0
    local line_data = {}

    for i, line in ipairs(lines) do
        local before_comment, comment = line:match("^(.-)(%s*#.*)$")
        if before_comment and comment then
            -- Trim trailing whitespace from before_comment
            before_comment = before_comment:match("^(.-)%s*$")
            -- Remove # and trim leading spaces from comment
            comment = comment:match("^%s*#%s*(.*)$")
            max_length = math.max(max_length, #before_comment)
            table.insert(line_data, {
                before = before_comment,
                comment = comment,
                original_indent = line:match("^(%s*)") or "",
            })
        else
            -- Line doesn't have a comment, keep as-is
            table.insert(line_data, { original = line })
        end
    end

    -- Rebuild lines with aligned comments
    local new_lines = {}
    for _, data in ipairs(line_data) do
        if data.original then
            table.insert(new_lines, data.original)
        else
            local padding = max_length - #data.before
            local aligned = data.before .. string.rep(" ", padding) .. " # " .. data.comment
            table.insert(new_lines, aligned)
        end
    end

    -- Replace lines
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

-- Set up keymap
vim.keymap.set("v", "<leader>a", function()
    -- Exit visual mode to update marks
    vim.cmd("normal! \27") -- ESC key
    M.align_comments()
end, { desc = "Align Comments" })

return M

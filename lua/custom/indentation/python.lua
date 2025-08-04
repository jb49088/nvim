local M = {}

-- Configuration options matching the original vim function
local config = {
    continue_indent = vim.fn.shiftwidth() * 2, -- pyindent_continue
    open_paren_indent = vim.fn.shiftwidth(), -- pyindent_open_paren
    nested_paren_indent = vim.fn.shiftwidth(), -- pyindent_nested_paren
    disable_parentheses_indenting = false, -- g:python_indent.disable_parentheses_indenting
    closed_paren_align_last_line = false, -- g:python_indent.closed_paren_align_last_line
}

-- Helper functions
local function get_indent(lnum)
    return vim.fn.indent(lnum)
end

local function get_line(lnum)
    return vim.fn.getline(lnum)
end

-- Check if we're in a string at the start of line
local function in_string_at_start(lnum)
    if vim.fn.has("syntax_items") == 1 then
        local syn_name = vim.fn.synIDattr(vim.fn.synID(lnum, 1, 1), "name")
        return syn_name:match("String$") ~= nil
    end
    return false
end

-- Simplified and more reliable bracket search
local function find_opening_bracket(lnum)
    local bracket_pairs = {
        [")"] = "(",
        ["]"] = "[",
        ["}"] = "{",
    }

    local opening_brackets = { "(", "[", "{" }
    local closing_brackets = { ")", "]", "}" }

    local stack = {}

    -- Start from the line before the current line and search backwards
    for search_lnum = lnum - 1, 1, -1 do
        local line = get_line(search_lnum)

        -- Process each character from right to left
        for col = #line, 1, -1 do
            local char = line:sub(col, col)

            if vim.tbl_contains(closing_brackets, char) then
                table.insert(stack, char)
            elseif vim.tbl_contains(opening_brackets, char) then
                if #stack == 0 then
                    -- Found unmatched opening bracket
                    return search_lnum, col
                else
                    -- Pop matching closing bracket from stack
                    local expected_close = nil
                    if char == "(" then
                        expected_close = ")"
                    elseif char == "[" then
                        expected_close = "]"
                    elseif char == "{" then
                        expected_close = "}"
                    end

                    local last_close = table.remove(stack)
                    if expected_close ~= last_close then
                        -- Mismatched brackets
                        return 0, 0
                    end
                end
            end
        end
    end

    return 0, 0
end

-- Check if user has already dedented
local function is_dedented(lnum, expected_indent)
    return get_indent(lnum) < expected_indent
end

-- Remove trailing comment with syntax highlighting
local function remove_comment(line, lnum)
    local line_len = #line

    if vim.fn.has("syntax_items") == 1 then
        -- Check if last character is in a comment
        local synstack = vim.fn.synstack(lnum, line_len)
        local is_comment = false

        for _, id in ipairs(synstack) do
            local name = vim.fn.synIDattr(id, "name")
            if name:match("Comment$") or name:match("Todo$") then
                is_comment = true
                break
            end
        end

        if is_comment then
            -- Binary search for comment start
            local min_col = 1
            local max_col = line_len

            while min_col < max_col do
                local col = math.floor((min_col + max_col) / 2)
                local synstack_col = vim.fn.synstack(lnum, col)
                local col_is_comment = false

                for _, id in ipairs(synstack_col) do
                    local name = vim.fn.synIDattr(id, "name")
                    if name:match("Comment$") or name:match("Todo$") then
                        col_is_comment = true
                        break
                    end
                end

                if col_is_comment then
                    max_col = col
                else
                    min_col = col + 1
                end
            end

            return line:sub(1, min_col - 1)
        end
    else
        -- Fallback: simple # detection
        local comment_pos = line:find("#")
        if comment_pos then
            return line:sub(1, comment_pos - 1)
        end
    end

    return line
end

-- Main indentation function
function M.get_indent()
    local lnum = vim.v.lnum

    -- Handle line continuations with backslash
    if lnum > 1 and get_line(lnum - 1):match("\\%s*$") then
        if lnum > 2 and get_line(lnum - 2):match("\\%s*$") then
            return get_indent(lnum - 1)
        end
        return get_indent(lnum - 1) + config.continue_indent
    end

    -- Don't change indentation if line starts inside a string literal
    if in_string_at_start(lnum) then
        return -1
    end

    -- Find the previous non-empty line to base indentation on
    local plnum = vim.fn.prevnonblank(lnum - 1)
    if plnum == 0 then
        return 0
    end

    -- Handle bracket/parentheses indentation
    if not config.disable_parentheses_indenting then
        -- Check if current line is a closing bracket
        local current_line = get_line(lnum)
        if current_line:match("^%s*[%)%]%}]") then
            if not config.closed_paren_align_last_line then
                local parlnum, _ = find_opening_bracket(lnum)
                if parlnum > 0 then
                    return get_indent(parlnum)
                end
            end
        end

        -- Check if we're inside brackets
        local parlnum, parcol = find_opening_bracket(lnum)
        if parlnum > 0 then
            local bracket_line = get_line(parlnum)
            local bracket_char = bracket_line:sub(parcol, parcol)

            -- Check if the opening bracket line has content after the bracket
            local after_bracket = bracket_line:sub(parcol + 1):match("^%s*(.*)$")

            if after_bracket and after_bracket ~= "" and not after_bracket:match("^%s*$") then
                -- There's content on the same line as the opening bracket
                -- Align with the first non-whitespace character after the bracket
                local first_content_col = parcol + 1
                while first_content_col <= #bracket_line do
                    if
                        bracket_line:sub(first_content_col, first_content_col) ~= " "
                        and bracket_line:sub(first_content_col, first_content_col) ~= "\t"
                    then
                        break
                    end
                    first_content_col = first_content_col + 1
                end
                return first_content_col - 1
            else
                -- No content after opening bracket, use standard indentation
                return get_indent(parlnum) + config.open_paren_indent
            end
        end
    end

    local plindent = get_indent(plnum)

    -- Strip trailing comments from previous line before checking for colons
    local pline = remove_comment(get_line(plnum), plnum)

    -- Increase indentation after lines ending with colon (if/for/def/class/etc)
    if pline:match(":%s*$") then
        return plindent + vim.fn.shiftwidth()
    end

    -- Dedent after stop-execution statements (break/continue/return/pass/raise)
    if get_line(plnum):match("^%s*%(break%|continue%|raise%|return%|pass%)%f[%A]") then
        if is_dedented(lnum, plindent) then
            return -1
        end
        return plindent - vim.fn.shiftwidth()
    end

    -- Align except/finally with their corresponding try statement
    if get_line(lnum):match("^%s*%(except%|finally%)%f[%A]") then
        local search_lnum = lnum - 1
        while search_lnum >= 1 do
            if get_line(search_lnum):match("^%s*%(try%|except%)%f[%A]") then
                local ind = get_indent(search_lnum)
                if ind >= get_indent(lnum) then
                    return -1
                end
                return ind
            end
            search_lnum = search_lnum - 1
        end
        return -1
    end

    -- Dedent elif/else to match their corresponding if/elif statement
    if get_line(lnum):match("^%s*%(elif%|else%)%f[%A]") then
        -- Unless previous line was a one-liner
        if get_line(plnum):match("^%s*%(for%|if%|elif%|try%)%f[%A]") then
            return plindent
        end

        if is_dedented(lnum, plindent) then
            return -1
        end

        return plindent - vim.fn.shiftwidth()
    end

    -- Default fallback: maintain current indentation or let Neovim handle it
    return -1
end

-- Setup function
function M.setup(opts)
    opts = opts or {}
    config = vim.tbl_deep_extend("force", config, opts)

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
            vim.bo.indentexpr = "v:lua.require'custom.indentation.python'.get_indent()"
        end,
        desc = "Set custom Python indentation",
    })
end

-- Auto-setup when required
M.setup()

return M

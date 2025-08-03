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

-- Search for bracket (simplified but functional version of s:SearchBracket)
local function search_bracket(lnum, direction)
    local bracket_pairs = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        [")"] = "(",
        ["]"] = "[",
        ["}"] = "{",
    }

    local open_brackets = { "(", "[", "{" }
    local close_brackets = { ")", "]", "}" }

    local stack = {}
    local search_lnum = lnum

    -- Search backwards for opening bracket
    while search_lnum > 0 do
        local line = get_line(search_lnum)

        -- Scan line from right to left
        for i = #line, 1, -1 do
            local char = line:sub(i, i)

            if vim.tbl_contains(close_brackets, char) then
                table.insert(stack, char)
            elseif vim.tbl_contains(open_brackets, char) then
                if #stack == 0 then
                    -- Found unmatched opening bracket
                    return search_lnum, i
                else
                    -- Check if it matches the last closing bracket
                    local last_close = table.remove(stack)
                    if bracket_pairs[char] ~= last_close then
                        -- Mismatched brackets, something's wrong
                        return 0, 0
                    end
                end
            end
        end

        search_lnum = search_lnum - 1
    end

    return 0, 0
end

-- Check if user has already dedented (s:Dedented equivalent)
local function is_dedented(lnum, expected_indent)
    return get_indent(lnum) < expected_indent
end

-- Remove trailing comment with syntax highlighting (lines 113-145)
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
            -- Binary search for comment start (like original)
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

-- Main indentation function (direct translation of python#GetIndent)
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

    local plindent, plnumstart

    -- Handle bracket/parentheses indentation with consistent spacing
    -- Uses shiftwidth-based indentation instead of aligning with bracket position
    if config.disable_parentheses_indenting then
        plindent = get_indent(plnum)
        plnumstart = plnum
    else
        -- Find opening bracket for current line
        local parlnum, parcol = search_bracket(lnum)

        if parlnum > 0 then
            -- Closing brackets align with the line that opened them
            if get_line(lnum):match("^%s*[%)%]%}]") and not config.closed_paren_align_last_line then
                return get_indent(parlnum)
            end
        end

        -- Check if previous line is inside parentheses
        local prev_parlnum, _ = search_bracket(plnum)
        if prev_parlnum > 0 then
            plindent = get_indent(prev_parlnum)
            plnumstart = prev_parlnum
        else
            plindent = get_indent(plnum)
            plnumstart = plnum
        end

        -- Handle first line inside parentheses/brackets with consistent indentation
        local p, _ = search_bracket(lnum)
        if p > 0 then
            if p == plnum then
                -- First line inside parentheses uses consistent indentation
                local pp, _ = search_bracket(lnum)
                if pp > 0 then
                    return get_indent(plnum) + config.nested_paren_indent
                end
                return get_indent(plnum) + config.open_paren_indent
            end

            if plnumstart == p then
                return get_indent(plnum)
            end
            return plindent
        end
    end

    -- Strip trailing comments from previous line before checking for colons
    local pline = remove_comment(get_line(plnum), plnum)

    -- Increase indentation after lines ending with colon (if/for/def/class/etc)
    if pline:match(":%s*$") then
        return plindent + vim.fn.shiftwidth()
    end

    -- Dedent after stop-execution statements (break/continue/return/pass/raise)
    if get_line(plnum):match("^%s*%(break%|continue%|raise%|return%|pass%)%f[%A]") then
        if is_dedented(lnum, get_indent(plnum)) then
            return -1
        end
        return get_indent(plnum) - vim.fn.shiftwidth()
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
        if get_line(plnumstart):match("^%s*%(for%|if%|elif%|try%)%f[%A]") then
            return plindent
        end

        if is_dedented(lnum, plindent) then
            return -1
        end

        return plindent - vim.fn.shiftwidth()
    end

    -- Handle indentation after closing parentheses/brackets
    local final_parlnum, _ = search_bracket(lnum)
    if final_parlnum > 0 then
        if is_dedented(lnum, plindent) then
            return -1
        else
            return plindent
        end
    end

    -- Default fallback: let Neovim handle indentation
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

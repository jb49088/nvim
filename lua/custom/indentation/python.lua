-- ================================================================================
-- =                              PYTHON INDENTATION                              =
-- ================================================================================

-- Python indentation in Lua with treesitter-aware bracket detection
-- Fixes brackets in strings (e.g., regex patterns) breaking indent when using treesitter highlighting

local M = {}

local config = {
    closed_paren_align_last_line = true,
    open_paren = "shiftwidth() * 2",
    nested_paren = "shiftwidth()",
    continue = "shiftwidth() * 2",
    searchpair_timeout = 150,
    disable_parentheses_indenting = false,
}

if vim.g.python_indent then
    config = vim.tbl_extend("force", config, vim.g.python_indent)
end

local maxoff = 50

local function eval_indent(expr)
    if type(expr) == "number" then
        return expr
    end
    local func = loadstring("return " .. expr:gsub("shiftwidth%(%)", "vim.fn.shiftwidth()"))
    return func and func() or vim.fn.shiftwidth()
end

local function is_in_string_or_comment(lnum, col)
    local ok, parser = pcall(vim.treesitter.get_parser, 0, "python")
    if ok and parser then
        local tree = parser:parse()[1]
        if tree then
            local node = tree:root():named_descendant_for_range(lnum - 1, col - 1, lnum - 1, col - 1)
            while node do
                local node_type = node:type()
                if node_type:match("string") or node_type:match("comment") then
                    return true
                end
                node = node:parent()
            end
            return false
        end
    end

    if vim.fn.has("syntax_items") == 1 then
        local synstack = vim.fn.synstack(lnum, col)
        for _, id in ipairs(synstack) do
            local name = vim.fn.synIDattr(id, "name")
            if name:match("Comment$") or name:match("Todo$") or name:match("String$") then
                return true
            end
        end
    end
    return false
end

local function search_bracket(fromlnum, flags)
    local skip_expr = function()
        return is_in_string_or_comment(vim.fn.line("."), vim.fn.col("."))
    end
    local start_line = math.max(0, fromlnum - maxoff)
    local result = vim.fn.searchpairpos("[[({]", "", "[])}]", flags, skip_expr, start_line, config.searchpair_timeout)
    return result[1], result[2]
end

local function is_dedented(lnum, expected)
    return vim.fn.indent(lnum) <= expected - vim.fn.shiftwidth()
end

local function remove_comment(line, lnum)
    local line_len = #line
    if is_in_string_or_comment(lnum, line_len) then
        local min_col, max_col = 1, line_len
        while min_col < max_col do
            local col = math.floor((min_col + max_col) / 2)
            if is_in_string_or_comment(lnum, col) then
                max_col = col
            else
                min_col = col + 1
            end
        end
        return line:sub(1, min_col - 1)
    end
    return line
end

function M.get_indent()
    local lnum = vim.v.lnum

    if vim.fn.getline(lnum - 1):match("\\%s*$") then
        if lnum > 1 and vim.fn.getline(lnum - 2):match("\\%s*$") then
            return vim.fn.indent(lnum - 1)
        end
        return vim.fn.indent(lnum - 1) + eval_indent(config.continue)
    end

    if is_in_string_or_comment(lnum, 1) then
        return -1
    end

    local plnum = vim.fn.prevnonblank(lnum - 1)
    if plnum == 0 then
        return 0
    end

    local plindent, plnumstart

    if config.disable_parentheses_indenting then
        plindent = vim.fn.indent(plnum)
        plnumstart = plnum
    else
        vim.fn.cursor(lnum, 1)
        local parlnum, parcol = search_bracket(lnum, "nbW")

        if parlnum > 0 then
            local parlnum_line = vim.fn.getline(parlnum)
            if parcol ~= vim.fn.col({ parlnum, "$" }) - 1 then
                return parcol
            elseif vim.fn.getline(lnum):match("^%s*[%)%]%}]") and not config.closed_paren_align_last_line then
                return vim.fn.indent(parlnum)
            end
        end

        vim.fn.cursor(plnum, 1)
        local prev_parlnum, _ = search_bracket(plnum, "nbW")
        if prev_parlnum > 0 then
            plindent = vim.fn.indent(prev_parlnum)
            plnumstart = prev_parlnum
        else
            plindent = vim.fn.indent(plnum)
            plnumstart = plnum
        end

        vim.fn.cursor(lnum, 1)
        local p, _ = search_bracket(lnum, "bW")
        if p > 0 then
            if p == plnum then
                vim.fn.cursor(lnum, 1)
                local pp, _ = search_bracket(lnum, "bW")
                if pp > 0 then
                    return vim.fn.indent(plnum) + eval_indent(config.nested_paren)
                end
                return vim.fn.indent(plnum) + eval_indent(config.open_paren)
            end
            if plnumstart == p then
                return vim.fn.indent(plnum)
            end
            return plindent
        end
    end

    local pline = remove_comment(vim.fn.getline(plnum), plnum)
    if pline:match(":%s*$") then
        return plindent + vim.fn.shiftwidth()
    end

    local plnum_line = vim.fn.getline(plnum)
    if
        plnum_line:match("^%s*break%f[%A]")
        or plnum_line:match("^%s*continue%f[%A]")
        or plnum_line:match("^%s*raise%f[%A]")
        or plnum_line:match("^%s*return%f[%A]")
        or plnum_line:match("^%s*pass%f[%A]")
    then
        if is_dedented(lnum, plindent) then
            return -1
        end
        return plindent - vim.fn.shiftwidth()
    end

    local curr_line = vim.fn.getline(lnum)
    if curr_line:match("^%s*except%f[%A]") or curr_line:match("^%s*finally%f[%A]") then
        local search_lnum = lnum - 1
        while search_lnum >= 1 do
            local search_line = vim.fn.getline(search_lnum)
            if search_line:match("^%s*try%f[%A]") or search_line:match("^%s*except%f[%A]") then
                local ind = vim.fn.indent(search_lnum)
                if ind >= vim.fn.indent(lnum) then
                    return -1
                end
                return ind
            end
            search_lnum = search_lnum - 1
        end
        return -1
    end

    if curr_line:match("^%s*elif%f[%A]") or curr_line:match("^%s*else%f[%A]") then
        local plnumstart_line = vim.fn.getline(plnumstart)
        if
            plnumstart_line:match("^%s*for%f[%A]")
            or plnumstart_line:match("^%s*if%f[%A]")
            or plnumstart_line:match("^%s*elif%f[%A]")
            or plnumstart_line:match("^%s*try%f[%A]")
        then
            return plindent
        end
        if is_dedented(lnum, plindent) then
            return -1
        end
        return plindent - vim.fn.shiftwidth()
    end

    if not config.disable_parentheses_indenting then
        vim.fn.cursor(lnum, 1)
        local after_paren, _ = search_bracket(lnum, "bW")
        if after_paren > 0 then
            if is_dedented(lnum, plindent) then
                return -1
            end
            return plindent
        end
    end

    return -1
end

function M.setup(opts)
    opts = opts or {}
    config = vim.tbl_extend("force", config, opts)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
            vim.bo.indentexpr = "v:lua.require'custom.indentation.python'.get_indent()"
        end,
    })
end

M.setup()

return M

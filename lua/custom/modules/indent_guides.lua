local M = {}

M.enabled = false

local config = {
    char = "│",
    hl = "IndentGuidesChar",
    priority = 1,
    filter = function(buf)
        return vim.bo[buf].buftype == ""
    end,
}

local ns = vim.api.nvim_create_namespace("simple_indent")
local cache_extmarks = {}
local states = {}

--- Get the virtual text extmarks for the indent guide
local function get_extmarks(indent, state, line_text)
    local key = indent .. ":" .. state.leftcol .. ":" .. state.shiftwidth
    if cache_extmarks[key] then
        return cache_extmarks[key]
    end

    local sw = state.shiftwidth
    local num_guides = math.floor(indent / sw)

    -- If there's any indentation but no full guide levels, show at least one guide
    if indent > 0 and num_guides == 0 then
        num_guides = 1
    end

    cache_extmarks[key] = {}

    for i = 1, num_guides do
        local col = (i - 1) * sw - state.leftcol
        if col >= 0 then
            table.insert(cache_extmarks[key], {
                virt_text = { { config.char, config.hl } },
                virt_text_pos = "overlay",
                virt_text_win_col = col,
                hl_mode = "combine",
                priority = config.priority,
                ephemeral = true,
            })
        end
    end
    return cache_extmarks[key]
end

--- Get whitespace from start of line
local function get_whitespace(line)
    return line:match("^%s*") or ""
end

--- Check if line has block endings
local function has_end(line)
    local trimmed = vim.trim(line)
    return trimmed:match("^[}%]%)]")
        or trimmed:match("^end")
        or trimmed:match("^else")
        or trimmed:match("^elif")
        or trimmed:match("^except")
        or trimmed:match("^finally")
end

--- Calculate raw whitespace width (like IBL)
local function calculate_whitespace_width(whitespace, tabstop)
    local width = 0
    for ch in whitespace:gmatch(".") do
        if ch == "\t" then
            local tab_width = tabstop - (width % tabstop)
            width = width + tab_width
        else
            width = width + 1
        end
    end
    return width
end

--- IBL-style indent calculation with proper state management
local function get_indent_whitespace(whitespace, shiftwidth, tabstop, indent_stack, whitespace_only)
    local spaces = 0
    local tabs_width = 0
    local whitespace_tbl = {}

    -- Process character by character like IBL
    for ch in whitespace:gmatch(".") do
        if ch == "\t" then
            local tab_width = tabstop - (spaces % tabstop)
            tabs_width = tabs_width + tab_width
            -- Add tab representations to whitespace_tbl
            for _ = 1, tab_width do
                table.insert(whitespace_tbl, "TAB")
            end
        else
            spaces = spaces + 1
            local total_so_far = spaces + tabs_width
            if total_so_far % shiftwidth == 0 then
                table.insert(whitespace_tbl, "INDENT")
            else
                table.insert(whitespace_tbl, "SPACE")
            end
        end
    end

    local total_indent = spaces + tabs_width

    -- Update indent stack (filter out >= current level)
    local new_stack = {}
    for _, stack_indent in ipairs(indent_stack) do
        if stack_indent < total_indent then
            table.insert(new_stack, stack_indent)
        end
    end

    -- Add current indent to stack if not whitespace_only and > 0
    if not whitespace_only and total_indent > 0 then
        table.insert(new_stack, total_indent)
    end

    return whitespace_tbl, new_stack, total_indent
end

--- Main refresh function - simplified without cursor interference
local function refresh_buffer(buf, top, bottom, shiftwidth, tabstop)
    local line_indents = {}
    local lines = vim.api.nvim_buf_get_lines(buf, top - 1, bottom, false)

    -- Get extended lines for lookahead
    local line_count = vim.api.nvim_buf_line_count(buf)
    local extended_top = math.max(1, top - 5)
    local extended_bottom = math.min(line_count, bottom + 10)
    local extended_lines = vim.api.nvim_buf_get_lines(buf, extended_top - 1, extended_bottom, false)

    -- Build a map of line numbers to extended line indices
    local extended_map = {}
    for i = 1, #extended_lines do
        extended_map[extended_top + i - 1] = i
    end

    local indent_stack = {}
    local empty_line_counter = 0
    local next_whitespace_tbl = {}
    local last_whitespace_tbl = {}

    -- Main processing loop
    for i = 1, #lines do
        local line = lines[i]
        local lnum = top + i - 1
        local blankline = line:len() == 0
        local whitespace_tbl = {}

        if not blankline then
            -- Non-blank line: process whitespace normally
            local whitespace = get_whitespace(line)
            whitespace_tbl, indent_stack = get_indent_whitespace(whitespace, shiftwidth, tabstop, indent_stack, false)
            last_whitespace_tbl = whitespace_tbl
        elseif empty_line_counter > 0 then
            -- We're in a sequence of empty lines, use cached whitespace_tbl
            empty_line_counter = empty_line_counter - 1
            whitespace_tbl = next_whitespace_tbl
        else
            -- First blank line in sequence: look ahead
            if i == #lines then
                whitespace_tbl = {}
            else
                local j = i + 1

                -- Count consecutive blank lines and find next non-blank
                while j <= #lines and lines[j]:len() == 0 do
                    empty_line_counter = empty_line_counter + 1
                    j = j + 1
                end

                -- Look beyond visible range if needed
                local next_line = nil
                local next_lnum = top + j - 1

                if j <= #lines then
                    next_line = lines[j]
                elseif extended_map[next_lnum] then
                    next_line = extended_lines[extended_map[next_lnum]]
                else
                    -- Look even further ahead
                    for look_ahead = next_lnum, math.min(line_count, next_lnum + 10) do
                        local ahead_line = vim.api.nvim_buf_get_lines(buf, look_ahead - 1, look_ahead, false)[1]
                        if ahead_line and ahead_line:len() > 0 then
                            next_line = ahead_line
                            break
                        end
                    end
                end

                if next_line then
                    local j_whitespace = get_whitespace(next_line)

                    -- Calculate whitespace for the next line
                    whitespace_tbl, indent_stack =
                        get_indent_whitespace(j_whitespace, shiftwidth, tabstop, indent_stack, true)

                    -- Special handling if next line has block ending
                    if has_end(next_line) and #indent_stack > 0 then
                        -- Add an extra indent level based on the stack
                        local stack_level = indent_stack[#indent_stack]
                        local stack_guides = math.floor(stack_level / shiftwidth)
                        if stack_guides > 0 and last_whitespace_tbl[stack_guides] == "INDENT" then
                            table.insert(whitespace_tbl, "INDENT")
                        end
                    end

                    next_whitespace_tbl = whitespace_tbl
                else
                    whitespace_tbl = {}
                end
            end
        end

        -- MODIFIED: Use raw whitespace width instead of only counting "INDENT" entries
        -- This allows guides to show even for non-standard indentation
        local indent = 0
        if not blankline then
            local whitespace = get_whitespace(line)
            indent = calculate_whitespace_width(whitespace, tabstop)
        else
            -- For blank lines, convert whitespace_tbl to indent count like before
            for _, ws_type in ipairs(whitespace_tbl) do
                if ws_type == "INDENT" then
                    indent = indent + shiftwidth
                end
            end
        end

        line_indents[lnum] = indent
    end

    return line_indents
end

local function get_state(win, buf, top, bottom)
    local prev, changedtick = states[win], vim.b[buf].changedtick

    if
        not (prev and prev.buf == buf and prev.changedtick == changedtick and prev.top == top and prev.bottom == bottom)
    then
        prev = nil
    end

    local state = {
        win = win,
        buf = buf,
        changedtick = changedtick,
        top = top,
        bottom = bottom,
        leftcol = vim.api.nvim_buf_call(buf, vim.fn.winsaveview).leftcol,
        shiftwidth = vim.bo[buf].shiftwidth,
        tabstop = vim.bo[buf].tabstop,
        line_indents = prev and prev.line_indents or nil,
    }

    state.shiftwidth = state.shiftwidth == 0 and state.tabstop or state.shiftwidth
    states[win] = state
    return state
end

--- Check if we should show a guide at a specific position
local function should_show_guide(buf, lnum, col)
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""

    -- Don't show guide if there's non-whitespace content at this position
    if col < #line then
        local char = line:sub(col + 1, col + 1)
        return char == " " or char == "\t"
    end

    -- Show guide if we're past the end of the line (in whitespace)
    return true
end

--- Main rendering function
function M.on_win(win, buf, top, bottom)
    local state = get_state(win, buf, top + 1, bottom + 1)

    if not state.line_indents then
        state.line_indents = refresh_buffer(buf, state.top, state.bottom, state.shiftwidth, state.tabstop)
    end

    vim.api.nvim_buf_call(buf, function()
        for l = state.top, state.bottom do
            local line = vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1] or ""
            local indent = state.line_indents[l] or 0

            -- For empty lines, check if they are part of a "trailing" sequence
            -- that ends with an empty line (indicating user has unindented)
            if line:len() == 0 and indent > 0 then
                -- Look ahead to see if this empty line sequence ends with actual code or just trailing empty
                local is_trailing_empty = true
                local line_count = vim.api.nvim_buf_line_count(buf)

                -- Check lines after this one
                for check_line = l + 1, math.min(line_count, l + 20) do
                    local check_content = vim.api.nvim_buf_get_lines(buf, check_line - 1, check_line, false)[1] or ""
                    if check_content:len() > 0 then
                        -- Found non-empty line, check if it's indented
                        local check_whitespace = get_whitespace(check_content)
                        if #check_whitespace >= indent / state.shiftwidth * state.shiftwidth then
                            -- Next non-empty line has sufficient indentation, so this is not trailing
                            is_trailing_empty = false
                        end
                        break
                    end
                end

                -- If this appears to be trailing empty lines, don't show guides
                if is_trailing_empty then
                    indent = 0
                end
            end

            if indent > 0 then
                local extmarks = get_extmarks(indent, state, line)

                for _, opts in ipairs(extmarks) do
                    local col = opts.virt_text_win_col
                    -- Only place guide if it won't overlap with text
                    if should_show_guide(buf, l, col) then
                        vim.api.nvim_buf_set_extmark(buf, ns, l - 1, 0, opts)
                    end
                end
            end
        end
    end)
end

--- Force immediate refresh
local function force_refresh()
    -- Clear all state immediately
    states = {}
    cache_extmarks = {}

    -- Trigger immediate redraw
    vim.schedule(function()
        vim.cmd("redraw!")
    end)
end

--- Enable indent guides
function M.enable()
    if M.enabled then
        return
    end
    M.enabled = true

    vim.api.nvim_set_decoration_provider(ns, {
        on_win = function(_, win, buf, top, bottom)
            if M.enabled and config.filter(buf) then
                M.on_win(win, buf, top, bottom)
            end
        end,
    })

    local group = vim.api.nvim_create_augroup("simple_indent", { clear = true })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function()
            for win in pairs(states) do
                if not vim.api.nvim_win_is_valid(win) then
                    states[win] = nil
                end
            end
        end,
    })

    -- Simpler event handling - just refresh on text changes and mode changes
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = force_refresh,
    })

    vim.api.nvim_create_autocmd({ "InsertLeave", "InsertEnter" }, {
        group = group,
        callback = force_refresh,
    })
end

--- Disable indent guides
function M.disable()
    if not M.enabled then
        return
    end
    M.enabled = false
    vim.api.nvim_del_augroup_by_name("simple_indent")
    states = {}
    cache_extmarks = {}
    vim.cmd("redraw!")
end

--- Toggle indent guides
function M.toggle()
    if M.enabled then
        M.disable()
    else
        M.enable()
    end
end

--- Setup function
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Auto-enable
M.setup()
M.enable()

-- Snacks toggle integration
if Snacks and Snacks.toggle then
    Snacks.toggle({
        name = "Indent Guides",
        get = function()
            return M.enabled
        end,
        set = function(enabled)
            if enabled then
                M.enable()
            else
                M.disable()
            end
        end,
    }):map("<leader>ug")
end

return M

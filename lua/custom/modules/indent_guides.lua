local M = {}

M.enabled = false

local config = {
    char = "│",
    hl = "IndentGuidesChar",
    priority = 1,
    debounce_ms = 200,
    filter = function(buf)
        return vim.bo[buf].buftype == ""
    end,
}

local ns = vim.api.nvim_create_namespace("simple_indent")
local cache_extmarks = {}
local states = {}
local buffer_leftcol = {}

-- Debounced refresh system
local debounced_refresh = setmetatable({
    timers = {},
    queued_buffers = {},
}, {
    __call = function(self, bufnr)
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        if self.timers[bufnr] then
            self.timers[bufnr]:close()
        end

        self.queued_buffers[bufnr] = true

        self.timers[bufnr] = vim.defer_fn(function()
            if self.queued_buffers[bufnr] and vim.api.nvim_buf_is_valid(bufnr) then
                M.refresh_buffer_state(bufnr)
                self.queued_buffers[bufnr] = nil
            end
            self.timers[bufnr] = nil
        end, config.debounce_ms)
    end,
})

--- Get the virtual text extmarks for the indent guide
local function get_extmarks(num_guides, state)
    local key = num_guides .. ":" .. state.leftcol .. ":" .. state.shiftwidth
    if cache_extmarks[key] then
        return cache_extmarks[key]
    end

    local sw = state.shiftwidth
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

--- Calculate raw whitespace width
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

--- Process line and return scope depth (number of indent levels)
local function get_scope_depth(whitespace, shiftwidth, tabstop, indent_stack, whitespace_only)
    local width = calculate_whitespace_width(whitespace, tabstop)

    -- Filter stack to only keep levels less than current
    local new_stack = {}
    for _, stack_width in ipairs(indent_stack) do
        if stack_width < width then
            table.insert(new_stack, stack_width)
        end
    end

    -- Add current level if this is actual code (not whitespace only)
    if not whitespace_only and width > 0 then
        table.insert(new_stack, width)
    end

    -- Return the depth (number of levels in stack)
    return #new_stack, new_stack
end

--- Process entire buffer to get accurate indent depths
local function refresh_buffer(buf, shiftwidth, tabstop)
    local line_depths = {}
    local line_count = vim.api.nvim_buf_line_count(buf)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, line_count, false)

    local indent_stack = {}
    local empty_line_counter = 0
    local next_depth = 0

    for i = 1, #lines do
        local line = lines[i]
        local blankline = line:len() == 0
        local depth = 0

        if not blankline then
            local whitespace = get_whitespace(line)
            local whitespace_only = line == whitespace
            depth, indent_stack = get_scope_depth(whitespace, shiftwidth, tabstop, indent_stack, whitespace_only)
        elseif empty_line_counter > 0 then
            empty_line_counter = empty_line_counter - 1
            depth = next_depth
        else
            -- Look ahead for next non-blank line
            local j = i + 1
            local max_lookahead = math.min(#lines, i + 10)

            while j <= max_lookahead and lines[j] and lines[j]:len() == 0 do
                empty_line_counter = empty_line_counter + 1
                j = j + 1
            end

            if j <= #lines then
                local next_line = lines[j]
                local j_whitespace = get_whitespace(next_line)
                depth, _ = get_scope_depth(j_whitespace, shiftwidth, tabstop, indent_stack, true)

                -- Special handling for block endings
                if has_end(next_line) and depth > 0 then
                    depth = depth + 1
                end

                next_depth = depth
            else
                depth = 0
            end
        end

        line_depths[i] = depth
    end

    return line_depths
end

local function get_state(win, buf, top, bottom)
    local prev, changedtick = states[win], vim.b[buf].changedtick

    -- Only invalidate on content change, NOT viewport change
    local content_changed = not (prev and prev.buf == buf and prev.changedtick == changedtick)

    if content_changed then
        prev = nil
    end

    local leftcol = vim.api.nvim_buf_call(buf, vim.fn.winsaveview).leftcol
    local state = {
        win = win,
        buf = buf,
        changedtick = changedtick,
        top = top,
        bottom = bottom,
        leftcol = leftcol,
        shiftwidth = vim.bo[buf].shiftwidth,
        tabstop = vim.bo[buf].tabstop,
        line_depths = prev and prev.line_depths or nil,
    }

    state.shiftwidth = state.shiftwidth == 0 and state.tabstop or state.shiftwidth

    if buffer_leftcol[buf] ~= leftcol then
        buffer_leftcol[buf] = leftcol
        state.line_depths = nil
    end

    states[win] = state
    return state
end

--- Check if we should show a guide at a specific position
local function should_show_guide(buf, lnum, col)
    if not vim.api.nvim_buf_is_valid(buf) then
        return false
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    if lnum < 1 or lnum > line_count then
        return false
    end

    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""

    if col < 0 then
        return false
    end

    if col < #line then
        local char = line:sub(col + 1, col + 1)
        return char == " " or char == "\t"
    end

    return true
end

--- Main rendering function
function M.on_win(win, buf, top, bottom)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    if line_count == 0 then
        return
    end

    local state = get_state(win, buf, top + 1, bottom + 1)

    if not state.line_depths then
        state.line_depths = refresh_buffer(buf, state.shiftwidth, state.tabstop)
    end

    vim.api.nvim_buf_call(buf, function()
        for l = state.top, state.bottom do
            if l < 1 or l > line_count then
                goto continue
            end

            local depth = state.line_depths[l] or 0

            if depth > 0 then
                local extmarks = get_extmarks(depth, state)

                for _, opts in ipairs(extmarks) do
                    local col = opts.virt_text_win_col
                    if should_show_guide(buf, l, col) then
                        pcall(vim.api.nvim_buf_set_extmark, buf, ns, l - 1, 0, opts)
                    end
                end
            end

            ::continue::
        end
    end)
end

--- Refresh only the specific buffer's state
function M.refresh_buffer_state(bufnr)
    for win, state in pairs(states) do
        if state.buf == bufnr then
            state.line_depths = nil
        end
    end

    local keys_to_clear = {}
    for key in pairs(cache_extmarks) do
        table.insert(keys_to_clear, key)
    end

    if #keys_to_clear > 100 then
        cache_extmarks = {}
    else
        for _, key in ipairs(keys_to_clear) do
            cache_extmarks[key] = nil
        end
    end
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
        callback = function(opts)
            if opts.buf and debounced_refresh.timers[opts.buf] then
                debounced_refresh.timers[opts.buf]:close()
                debounced_refresh.timers[opts.buf] = nil
                debounced_refresh.queued_buffers[opts.buf] = nil
            end

            for win in pairs(states) do
                if not vim.api.nvim_win_is_valid(win) then
                    states[win] = nil
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(opts)
            debounced_refresh(opts.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "InsertLeave", "InsertEnter" }, {
        group = group,
        callback = function(opts)
            debounced_refresh(opts.buf)
        end,
    })

    vim.api.nvim_create_autocmd("WinScrolled", {
        group = group,
        callback = function(opts)
            local buf = vim.api.nvim_win_get_buf(0)
            if not config.filter(buf) then
                return
            end

            local win_view = vim.fn.winsaveview()
            if buffer_leftcol[buf] ~= win_view.leftcol then
                buffer_leftcol[buf] = win_view.leftcol
                M.refresh_buffer_state(buf)
            else
                debounced_refresh(buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
        group = group,
        callback = function(opts)
            vim.defer_fn(function()
                if vim.api.nvim_buf_is_valid(opts.buf) then
                    M.refresh_buffer_state(opts.buf)
                end
            end, 50)
        end,
    })
end

--- Disable indent guides
function M.disable()
    if not M.enabled then
        return
    end
    M.enabled = false
    vim.api.nvim_del_augroup_by_name("simple_indent")

    for _, timer in pairs(debounced_refresh.timers) do
        if timer then
            timer:close()
        end
    end

    debounced_refresh.timers = {}
    debounced_refresh.queued_buffers = {}
    states = {}
    cache_extmarks = {}
    buffer_leftcol = {}
    vim.cmd("redraw!")
end

--- Setup function
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

M.setup()
M.enable()

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
    }):map("<leader>uI")
end

return M

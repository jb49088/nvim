local api = vim.api
local fn = vim.fn
local treesitter = vim.treesitter

-- Configuration
local config = {
    enable = true,
    priority = 15,
    use_treesitter = true,
    chars = {
        horizontal_line = "─",
        vertical_line = "│",
        corner_top = "╭",
        corner_bottom = "╰",
    },
    textobject = "",
    max_file_size = 1024 * 1024,
    animation_duration = 200,
    -- NEW: Adaptive animation configuration - now character-based, no max duration
    adaptive_animation = {
        enabled = true,
        min_duration = 80, -- ms for very small chunks (few characters)
        base_multiplier = 8, -- ms per character (instead of per line)
        min_chunk_size = 3, -- chunks with this many chars or less use min_duration
    },
    fire_events = { "CursorHold", "CursorHoldI" },
    notify = true,
    exclude_filetypes = {
        [""] = true,
        aerial = true,
        alpha = true,
        better_term = true,
        checkhealth = true,
        cmp_menu = true,
        dashboard = true,
        ["dap-repl"] = true,
        DiffviewFileHistory = true,
        DiffviewFiles = true,
        DressingInput = true,
        fugitiveblame = true,
        glowpreview = true,
        help = true,
        lazy = true,
        lspinfo = true,
        lspsagafinder = true,
        man = true,
        mason = true,
        Navbuddy = true,
        NeogitPopup = true,
        NeogitStatus = true,
        ["neo-tree"] = true,
        ["neo-tree-popup"] = true,
        noice = true,
        notify = true,
        NvimTree = true,
        oil = true,
        Outline = true,
        OverseerList = true,
        packer = true,
        plugin = true,
        qf = true,
        query = true,
        registers = true,
        saga_codeaction = true,
        sagaoutline = true,
        sagafinder = true,
        sagarename = true,
        spectre_panel = true,
        startify = true,
        startuptime = true,
        starter = true,
        TelescopePrompt = true,
        toggleterm = true,
        Trouble = true,
        trouble = true,
        zsh = true,
    },
}

-- Module state
local M = {
    ns_id = api.nvim_create_namespace("chunk_guides"),
    augroup = nil,
    enabled = true,
    animation_task = nil,
    shiftwidth = fn.shiftwidth(),
    leftcol = fn.winsaveview().leftcol,
    pre_virt_text_list = {},
    pre_row_list = {},
    pre_virt_text_win_col_list = {},
    -- NEW: Track the last regular window to only show chunks on focused buffer
    last_regular_win = nil,
}

-- Get indentation and line utilities
local function get_indent(bufnr, lnum)
    return fn.indent(lnum + 1)
end

local function get_sw(bufnr)
    return fn.shiftwidth()
end

local function get_line(bufnr, lnum)
    local lines = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
    return lines[1] or ""
end

-- UPDATED: Check if a row is in the current viewport
local function is_row_in_viewport(row)
    local top_line = fn.line("w0") - 1
    local bottom_line = fn.line("w$") - 1

    return row >= top_line and row <= bottom_line
end

-- UPDATED: Check if any part of chunk intersects with viewport
local function is_chunk_in_viewport(start_row, end_row)
    local top_line = fn.line("w0") - 1
    local bottom_line = fn.line("w$") - 1

    -- Check if chunk intersects with viewport (any overlap)
    return not (end_row < top_line or start_row > bottom_line)
end

-- NEW: Calculate adaptive animation duration based on total character length (no max cap)
local function calculate_adaptive_duration(chunk_range)
    if not config.adaptive_animation.enabled then
        return config.animation_duration
    end

    -- Calculate the total character length of the guide
    local total_chars = 0

    -- Top horizontal line characters
    local beg_blank_len = get_indent(chunk_range.bufnr, chunk_range.start_row)
    local start_col = math.max(beg_blank_len - M.shiftwidth, 0)
    if beg_blank_len > 0 then
        local virt_text_len = beg_blank_len - start_col
        total_chars = total_chars + virt_text_len -- corner_top + horizontal_line:rep(virt_text_len - 1)
    end

    -- Vertical line characters (one per middle line)
    local mid_char_nums = chunk_range.end_row - chunk_range.start_row - 1
    if mid_char_nums > 0 then
        total_chars = total_chars + mid_char_nums -- vertical_line for each middle line
    end

    -- Bottom horizontal line characters
    local end_blank_len = get_indent(chunk_range.bufnr, chunk_range.end_row)
    if end_blank_len > 0 then
        local virt_text_len = end_blank_len - start_col
        total_chars = total_chars + virt_text_len -- corner_bottom + horizontal_line:rep(virt_text_len - 1)
    end

    -- Calculate duration based on character count
    if total_chars <= config.adaptive_animation.min_chunk_size then
        return config.adaptive_animation.min_duration
    end

    return config.adaptive_animation.min_duration + (total_chars * config.adaptive_animation.base_multiplier)
end

-- Chunk range return codes
local CHUNK_RANGE_RET = {
    OK = 0,
    NO_CHUNK = 2,
    NO_TS = 3,
}

-- Pre-compiled node type patterns
local node_types = {
    default = {
        "^class",
        "^func",
        "^method",
        "^if",
        "^while",
        "^for",
        "^with",
        "^try",
        "^match",
        "^arguments",
        "^argument_list",
        "^object",
        "^dictionary",
        "^list",
        "^element",
        "^table",
        "^tuple",
        "^do_block",
        "^return",
    },
}

-- NEW: Check if window is floating
local function is_floating_win(winid)
    local win_config = api.nvim_win_get_config(winid or 0)
    return win_config.relative ~= ""
end

-- Clear highlights
local function clear_highlights(bufnr, start_row, end_row)
    local start = start_row or 0
    local finish = end_row and (end_row + 1) or -1

    if finish == api.nvim_buf_line_count(bufnr) then
        finish = -1
    end

    if M.ns_id ~= -1 then
        api.nvim_buf_clear_namespace(bufnr, M.ns_id, start, finish)
    end
end

-- Utility functions
local function set_timeout(fn_callback, delay, ...)
    local timer = vim.uv.new_timer()
    if not timer then
        return nil
    end
    local args = { ... }
    timer:start(delay, 0, function()
        vim.schedule(function()
            fn_callback(unpack(args))
        end)
    end)
    return timer
end

local function shallow_cmp(t1, t2)
    if #t1 ~= #t2 then
        return false
    end
    for i, v in ipairs(t1) do
        if t2[i] ~= v then
            return false
        end
    end
    return true
end

local function range_from_to(i, j, step)
    local t = {}
    step = step or 1
    for x = i, j, step do
        table.insert(t, x)
    end
    return t
end

local function utf8_split(inputstr)
    local list = {}
    for uchar in string.gmatch(inputstr, "[^\128-\191][\128-\191]*") do
        table.insert(list, uchar)
    end
    return list
end

-- UPDATED: Viewport-aware animation task with immediate drawing for visible portions
local function create_viewport_aware_task(
    fn_callback,
    strategy,
    duration,
    virt_text_list,
    row_list,
    virt_text_win_col_list,
    chunk_start_row,
    chunk_end_row
)
    local data = {}
    for i = 1, #virt_text_list do
        table.insert(data, { virt_text_list[i], row_list[i], virt_text_win_col_list[i] })
    end

    local timer = nil
    local time_intervals = {}
    for _ = 1, #data do
        table.insert(time_intervals, duration / #data)
    end
    local progress = 1

    local task = {
        data = data,
        timer = timer,
        fn_callback = fn_callback,
        strategy = strategy,
        time_intervals = time_intervals,
        progress = progress,
        chunk_start_row = chunk_start_row,
        chunk_end_row = chunk_end_row,
    }

    function task:start()
        if self.timer or #self.data == 0 then
            return
        end

        -- NEW: Find the first visible row in the chunk
        local first_visible_index = 1
        for i = 1, #self.data do
            local row = self.data[i][2]
            if is_row_in_viewport(row) then
                first_visible_index = i
                break
            end
        end

        -- NEW: If we're starting from a visible row that's not the first one,
        -- instantly render everything up to this point
        if first_visible_index > 1 then
            for i = 1, first_visible_index - 1 do
                self.fn_callback(unpack(self.data[i]))
            end
            self.progress = first_visible_index
        end

        local f
        f = function()
            -- Check if any part of chunk is still in viewport
            if not is_chunk_in_viewport(self.chunk_start_row, self.chunk_end_row) then
                -- Chunk completely off-screen, complete instantly
                for i = self.progress, #self.data do
                    self.fn_callback(unpack(self.data[i]))
                end
                self:stop()
                return
            end

            -- Render the current step
            self.fn_callback(unpack(self.data[self.progress]))
            self.progress = self.progress + 1

            if self.progress > #self.time_intervals then
                if self.timer then
                    self.timer:stop()
                end
                self.timer = nil
                return
            else
                self.timer = set_timeout(f, self.time_intervals[self.progress])
                if not self.timer then
                    self:stop()
                    return
                end
            end
        end

        -- Start from the current progress (which might be after instant rendering)
        if self.progress <= #self.time_intervals then
            self.timer = set_timeout(f, self.time_intervals[self.progress])
            if not self.timer then
                self:stop()
                return
            end
        end
    end

    function task:stop()
        if self.timer then
            self.timer:stop()
            self.timer = nil
        end
    end

    return task
end

-- Check if node type is suitable for chunk detection
local function is_suit_type(node_type)
    for _, pattern in ipairs(node_types.default) do
        if pattern:sub(1, 1) == "^" then
            local compiled = "^" .. pattern:sub(2)
            if node_type:find(compiled) then
                return true
            end
        else
            if node_type:find(pattern) then
                return true
            end
        end
    end
    return false
end

-- Check if treesitter is available
local function has_treesitter(bufnr)
    local has_lang, lang = pcall(treesitter.language.get_lang, vim.bo[bufnr].filetype)
    if not has_lang then
        return false
    end

    local has, parser = pcall(treesitter.get_parser, bufnr, lang)
    if not has or not parser then
        return false
    end
    return true
end

-- Enhanced context-based detection for end-of-line cursors
local function get_chunk_range_by_context(bufnr, row, col)
    local base_flag = "nWz"
    local cur_row_val = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if not cur_row_val then
        return CHUNK_RANGE_RET.NO_CHUNK, nil
    end

    local line_len = #cur_row_val
    local search_positions = {}

    -- Use row instead of unused col parameter for position-based logic
    local cursor_pos = api.nvim_win_get_cursor(0)[2]

    if cursor_pos >= line_len then
        if line_len > 0 then
            for i = line_len - 1, 0, -1 do
                table.insert(search_positions, i)
            end
        end
        table.insert(search_positions, 0)
    else
        table.insert(search_positions, cursor_pos)
        if cursor_pos > 0 then
            table.insert(search_positions, cursor_pos - 1)
        end
    end

    local save_cursor = api.nvim_win_get_cursor(0)

    for _, search_col in ipairs(search_positions) do
        search_col = math.max(0, math.min(search_col, line_len - 1))
        local cur_char = cur_row_val:sub(search_col + 1, search_col + 1)

        api.nvim_win_set_cursor(0, { row + 1, search_col })

        local beg_row = fn.searchpair("{", "", "}", base_flag .. "b" .. (cur_char == "{" and "c" or ""))
        local end_row = fn.searchpair("{", "", "}", base_flag .. (cur_char == "}" and "c" or ""))

        if beg_row > 0 and end_row > 0 and beg_row < end_row then
            api.nvim_win_set_cursor(0, save_cursor)
            return CHUNK_RANGE_RET.OK,
                {
                    start_row = beg_row - 1,
                    end_row = end_row - 1,
                }
        end
    end

    api.nvim_win_set_cursor(0, save_cursor)
    return CHUNK_RANGE_RET.NO_CHUNK, nil
end

-- Simplified treesitter chunk detection
local function get_chunk_range_by_treesitter(bufnr, row, col)
    if not has_treesitter(bufnr) then
        return CHUNK_RANGE_RET.NO_TS, nil
    end

    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local line_len = #line
    local all_candidates = {}

    local positions_to_check = { 0 }
    if line_len > 0 then
        table.insert(positions_to_check, math.floor(line_len / 2))
        table.insert(positions_to_check, line_len - 1)
    end

    for _, check_col in ipairs(positions_to_check) do
        check_col = math.max(0, math.min(check_col, line_len > 0 and line_len - 1 or 0))

        local cursor_node = treesitter.get_node({
            ignore_injections = false,
            bufnr = bufnr,
            pos = { row, check_col },
        })

        if cursor_node and cursor_node:type() == "source" then
            cursor_node = treesitter.get_node({
                bufnr = bufnr,
                pos = { row, check_col },
            })
        end

        local current_node = cursor_node
        while current_node do
            local node_type = current_node:type()
            local node_start, _, node_end, _ = current_node:range()

            if node_start ~= node_end and is_suit_type(node_type) then
                local already_added = false
                for _, existing in ipairs(all_candidates) do
                    if existing.start_row == node_start and existing.end_row == node_end then
                        already_added = true
                        break
                    end
                end

                if not already_added then
                    table.insert(all_candidates, {
                        node = current_node,
                        start_row = node_start,
                        end_row = node_end,
                        size = node_end - node_start,
                        starts_on_cursor_row = node_start == row,
                    })
                end
            end

            local parent_node = current_node:parent()
            if parent_node == current_node then
                break
            end
            current_node = parent_node
        end
    end

    if #all_candidates == 0 then
        return CHUNK_RANGE_RET.NO_CHUNK, nil
    end

    local best_candidate = nil

    for _, candidate in ipairs(all_candidates) do
        if candidate.starts_on_cursor_row then
            if not best_candidate or candidate.size < best_candidate.size then
                best_candidate = candidate
            end
        end
    end

    if not best_candidate then
        for _, candidate in ipairs(all_candidates) do
            if not best_candidate or candidate.size < best_candidate.size then
                best_candidate = candidate
            end
        end
    end

    return CHUNK_RANGE_RET.OK,
        {
            start_row = best_candidate.start_row,
            end_row = best_candidate.end_row,
        }
end

-- Main chunk range function
local function get_chunk_range(pos, use_treesitter)
    local ret_code, chunk_range
    if use_treesitter then
        ret_code, chunk_range = get_chunk_range_by_treesitter(pos.bufnr, pos.row, pos.col)
    else
        ret_code, chunk_range = get_chunk_range_by_context(pos.bufnr, pos.row, pos.col)
    end
    return ret_code, chunk_range
end

local function calc_virt_text_pos(str, col, leftcol)
    local len = vim.api.nvim_strwidth(str)
    if col < leftcol then
        local byte_idx = math.min(leftcol - col, len)
        local utf_beg = vim.str_byteindex(str, byte_idx, true)
        str = str:sub(utf_beg + 1)
    end
    col = math.max(col - leftcol, 0)
    return str, col
end

-- Mode-based color functionality
local highlight_cache = {}

local function get_highlight_color(group_name)
    local cached = highlight_cache[group_name]
    if cached then
        return cached
    end

    local ok, hl = pcall(api.nvim_get_hl, 0, { name = group_name })
    local color = nil

    if ok and hl.fg then
        color = string.format("#%06x", hl.fg)
    end

    highlight_cache[group_name] = color
    return color
end

local mode_color_map = {
    ["n"] = "ModeColorNormal",
    ["i"] = "ModeColorInsert",
    ["v"] = "ModeColorVisual",
    ["V"] = "ModeColorVisual",
    ["\22"] = "ModeColorVisual",
    ["c"] = "ModeColorCommand",
    ["R"] = "ModeColorReplace",
    ["Rc"] = "ModeColorReplace",
    ["Rx"] = "ModeColorReplace",
    ["Rv"] = "ModeColorReplace",
    ["Rvc"] = "ModeColorReplace",
    ["Rvx"] = "ModeColorReplace",
    ["r"] = "ModeColorReplace",
    ["t"] = "ModeColorTerminal",
}

local function get_mode_color()
    local mode_code = api.nvim_get_mode().mode
    local color_group = mode_color_map[mode_code] or "ModeColorNormal"
    return get_highlight_color(color_group) or "#ffffff"
end

local function update_mode_highlight()
    local color = get_mode_color()
    if color then
        api.nvim_set_hl(0, "ChunkGuidesMode", { fg = color })
        return "ChunkGuidesMode"
    end
    return "Comment"
end

-- Simple debounce for animation
local function simple_debounce(fn_callback, delay)
    local timer = nil
    return function(...)
        local args = { ... }
        if timer then
            timer:stop()
        end
        timer = set_timeout(function()
            fn_callback(unpack(args))
        end, delay)
    end
end

-- Check if should render
local function should_render(bufnr)
    if not api.nvim_buf_is_valid(bufnr) then
        return false
    end

    local ft = vim.bo[bufnr].filetype
    local buftype = vim.bo[bufnr].buftype

    if not config.enable then
        return false
    end

    if config.exclude_filetypes[ft] then
        return false
    end

    local shiftwidth = get_sw(bufnr)
    if shiftwidth == 0 then
        return false
    end

    local allowed_buftypes = { "help", "nofile", "terminal", "prompt" }
    if vim.tbl_contains(allowed_buftypes, buftype) then
        return false
    end

    -- NEW: Only render for current window
    local current_buf = api.nvim_get_current_buf()
    if bufnr ~= current_buf then
        return false
    end

    return true
end

-- Update previous state
local function update_pre_state(virt_text_list, row_list, virt_text_win_col_list)
    M.pre_virt_text_list = virt_text_list
    M.pre_row_list = row_list
    M.pre_virt_text_win_col_list = virt_text_win_col_list
end

-- Stop animation task
local function stop_render()
    if M.animation_task then
        M.animation_task:stop()
        M.animation_task = nil
    end
end

-- Get chunk data for rendering
local function get_chunk_data(chunk_range, virt_text_list, row_list, virt_text_win_col_list)
    local beg_blank_len = get_indent(chunk_range.bufnr, chunk_range.start_row)
    local end_blank_len = get_indent(chunk_range.bufnr, chunk_range.end_row)
    local start_col = math.max(math.min(beg_blank_len, end_blank_len) - M.shiftwidth, 0)

    if beg_blank_len > 0 then
        local virt_text_len = beg_blank_len - start_col
        local beg_virt_text = config.chars.corner_top .. config.chars.horizontal_line:rep(virt_text_len - 1)
        local virt_text, virt_text_win_col = calc_virt_text_pos(beg_virt_text, start_col, M.leftcol)
        local char_list = fn.reverse(utf8_split(virt_text))
        vim.list_extend(virt_text_list, char_list)
        vim.list_extend(row_list, vim.fn["repeat"]({ chunk_range.start_row }, #char_list))
        vim.list_extend(
            virt_text_win_col_list,
            range_from_to(virt_text_win_col + #char_list - 1, virt_text_win_col, -1)
        )
    end

    local mid_char_nums = chunk_range.end_row - chunk_range.start_row - 1
    vim.list_extend(row_list, range_from_to((chunk_range.start_row + 1), (chunk_range.end_row - 1)))
    vim.list_extend(virt_text_win_col_list, vim.fn["repeat"]({ start_col - M.leftcol }, mid_char_nums))
    local mid = config.chars.vertical_line:rep(mid_char_nums)
    local chars
    if start_col - M.leftcol < 0 then
        chars = vim.fn["repeat"]({ "" }, mid_char_nums)
    else
        chars = utf8_split(mid)
        for i = 1, mid_char_nums do
            local line = get_line(chunk_range.bufnr, chunk_range.start_row + i) or ""
            local char = line:sub(start_col + 1, start_col + 1) or ""
            if not char:match("%s") and #char ~= 0 then
                chars[i] = ""
            end
        end
    end
    vim.list_extend(virt_text_list, chars)

    if end_blank_len > 0 then
        local virt_text_len = end_blank_len - start_col
        local end_virt_text = config.chars.corner_bottom .. config.chars.horizontal_line:rep(virt_text_len - 1)
        local virt_text, virt_text_win_col = calc_virt_text_pos(end_virt_text, start_col, M.leftcol)
        local char_list = utf8_split(virt_text)
        vim.list_extend(virt_text_list, char_list)
        vim.list_extend(row_list, vim.fn["repeat"]({ chunk_range.end_row }, virt_text_len))
        vim.list_extend(virt_text_win_col_list, range_from_to(virt_text_win_col, virt_text_win_col + virt_text_len - 1))
    end
end

-- Animated rendering
local function render_animated(chunk_range)
    if not should_render(chunk_range.bufnr) then
        return
    end

    local virt_text_list = {}
    local row_list = {}
    local virt_text_win_col_list = {}
    get_chunk_data(chunk_range, virt_text_list, row_list, virt_text_win_col_list)

    if
        shallow_cmp(virt_text_list, M.pre_virt_text_list)
        and shallow_cmp(row_list, M.pre_row_list)
        and shallow_cmp(virt_text_win_col_list, M.pre_virt_text_win_col_list)
    then
        return
    end

    stop_render()
    update_pre_state(virt_text_list, row_list, virt_text_win_col_list)
    clear_highlights(chunk_range.bufnr)

    local text_hl = update_mode_highlight()

    -- NEW: Use adaptive duration based on character length (no max cap)
    local animation_duration = calculate_adaptive_duration(chunk_range)

    if animation_duration > 0 then
        M.animation_task = create_viewport_aware_task(
            function(vt, row, vt_win_col)
                local row_opts = {
                    virt_text = { { vt, text_hl } },
                    virt_text_pos = "overlay",
                    virt_text_win_col = vt_win_col,
                    hl_mode = "combine",
                    priority = 100,
                }
                if api.nvim_buf_is_valid(chunk_range.bufnr) and api.nvim_buf_line_count(chunk_range.bufnr) > row then
                    api.nvim_buf_set_extmark(chunk_range.bufnr, M.ns_id, row, 0, row_opts)
                end
            end,
            "linear",
            animation_duration,
            virt_text_list,
            row_list,
            virt_text_win_col_list,
            chunk_range.start_row,
            chunk_range.end_row
        )
        M.animation_task:start()
    else
        for i, vt in ipairs(virt_text_list) do
            local row_opts = {
                virt_text = { { vt, text_hl } },
                virt_text_pos = "overlay",
                virt_text_win_col = virt_text_win_col_list[i],
                hl_mode = "combine",
                priority = 100,
            }
            local row = row_list[i]
            if
                row
                and api.nvim_buf_is_valid(chunk_range.bufnr)
                and api.nvim_buf_line_count(chunk_range.bufnr) > row
            then
                api.nvim_buf_set_extmark(chunk_range.bufnr, M.ns_id, row, 0, row_opts)
            end
        end
    end
end

-- Main render function with debouncing
local animate_debounce = simple_debounce(function(chunk_range)
    render_animated(chunk_range)
end, 10)

local function render_chunk_guides(chunk_range)
    animate_debounce(chunk_range)
end

-- Main render callback
local function on_render()
    local bufnr = api.nvim_get_current_buf()
    if not should_render(bufnr) then
        return
    end

    local winid = api.nvim_get_current_win()
    local pos = api.nvim_win_get_cursor(winid)

    local ret_code, chunk_range = get_chunk_range({
        bufnr = bufnr,
        row = pos[1] - 1,
        col = pos[2],
    }, config.use_treesitter)

    api.nvim_win_call(winid, function()
        M.shiftwidth = get_sw(bufnr)
        M.leftcol = fn.winsaveview().leftcol
    end)

    if ret_code == CHUNK_RANGE_RET.OK and chunk_range then
        local range_with_bufnr = {
            bufnr = bufnr,
            start_row = chunk_range.start_row,
            end_row = chunk_range.end_row,
        }
        render_chunk_guides(range_with_bufnr)
    elseif ret_code == CHUNK_RANGE_RET.NO_CHUNK then
        update_pre_state({}, {}, {})
        if M.animation_task then
            M.animation_task:stop()
        end
        clear_highlights(bufnr)
    elseif ret_code == CHUNK_RANGE_RET.NO_TS then
        if config.notify then
            vim.notify("[chunk_guides]: no parser for " .. vim.bo[bufnr].ft, vim.log.levels.INFO, { once = true })
        end
    end
end

-- Setup autocmds
local function setup_autocmds()
    M.augroup = api.nvim_create_augroup("ChunkGuides", { clear = true })

    -- NEW: Window management - only show chunks on focused buffer
    api.nvim_create_autocmd(config.fire_events, {
        group = M.augroup,
        callback = function()
            local current_win = api.nvim_get_current_win()

            -- Skip floating windows
            if is_floating_win(current_win) then
                return
            end

            -- Clear chunks from previous regular window if different
            if
                M.last_regular_win
                and M.last_regular_win ~= current_win
                and api.nvim_win_is_valid(M.last_regular_win)
            then
                api.nvim_win_call(M.last_regular_win, function()
                    local prev_bufnr = api.nvim_get_current_buf()
                    clear_highlights(prev_bufnr)
                end)
            end

            -- Enable chunks for current window immediately if enabled
            if M.enabled then
                vim.schedule(on_render)
            end

            M.last_regular_win = current_win
        end,
    })

    for _, event in ipairs(config.fire_events) do
        api.nvim_create_autocmd({ event }, {
            group = M.augroup,
            callback = function()
                vim.schedule(on_render)
            end,
        })
    end

    api.nvim_create_autocmd({ "ModeChanged", "CmdlineEnter", "CmdlineLeave" }, {
        group = M.augroup,
        callback = function()
            update_mode_highlight()
            vim.schedule(on_render)
        end,
    })

    api.nvim_create_autocmd({ "UIEnter", "BufWinEnter" }, {
        group = M.augroup,
        callback = function()
            local ok, status = pcall(fn.getfsize, fn.expand("%"))
            if ok and status >= config.max_file_size then
                if config.notify then
                    vim.notify("File is too large, chunk guides will not be loaded")
                end
                M.enabled = false
            else
                vim.schedule(on_render)
            end
        end,
    })

    api.nvim_create_autocmd({ "ColorScheme" }, {
        group = M.augroup,
        pattern = "*",
        callback = function()
            highlight_cache = {}
            update_mode_highlight()
            vim.schedule(on_render)
        end,
    })
end

-- Setup textobject
local function setup_textobject()
    local textobject = config.textobject
    if #textobject == 0 then
        return
    end

    vim.keymap.set({ "x", "o" }, textobject, function()
        local pos = api.nvim_win_get_cursor(0)
        local retcode, cur_chunk_range = get_chunk_range({
            bufnr = 0,
            row = pos[1] - 1,
            col = pos[2],
        }, config.use_treesitter)

        if retcode ~= CHUNK_RANGE_RET.OK or not cur_chunk_range then
            return
        end

        local s_row = cur_chunk_range.start_row + 1
        local e_row = cur_chunk_range.end_row + 1
        local ctrl_v = api.nvim_replace_termcodes("<C-v>", true, true, true)
        local cur_mode = vim.fn.mode()

        if cur_mode == "v" or cur_mode == "V" or cur_mode == ctrl_v then
            vim.cmd("normal! " .. cur_mode)
        end

        api.nvim_win_set_cursor(0, { s_row, 0 })
        vim.cmd("normal! V")
        api.nvim_win_set_cursor(0, { e_row, 0 })
    end)
end

-- Public API
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
end

function M.enable()
    config.enable = true
    M.enabled = true
    update_mode_highlight()

    local bufnr = api.nvim_get_current_buf()
    if should_render(bufnr) then
        vim.schedule(on_render)
    end
    setup_autocmds()
    setup_textobject()
end

function M.disable()
    config.enable = false
    M.enabled = false
    for _, bufnr in pairs(api.nvim_list_bufs()) do
        clear_highlights(bufnr)
    end
    if M.augroup then
        pcall(api.nvim_del_augroup_by_name, "ChunkGuides")
        M.augroup = nil
    end
end

function M.refresh()
    local bufnr = api.nvim_get_current_buf()
    if should_render(bufnr) then
        on_render()
    end
end

function M.toggle()
    if config.enable then
        M.disable()
    else
        M.enable()
    end
end

-- Initialize
local function init()
    update_mode_highlight()
    setup_autocmds()
    setup_textobject()

    vim.schedule(function()
        local bufnr = api.nvim_get_current_buf()
        if should_render(bufnr) then
            on_render()
        end
    end)
end

-- Auto-enable on require
init()

-- Create user commands
api.nvim_create_user_command("EnableChunkGuides", function()
    if not config.enable then
        M.enable()
    end
end, { desc = "Enable chunk guides" })

api.nvim_create_user_command("DisableChunkGuides", function()
    if config.enable then
        M.disable()
    end
end, { desc = "Disable chunk guides" })

api.nvim_create_user_command("ToggleChunkGuides", function()
    M.toggle()
end, { desc = "Toggle chunk guides" })

-- Snacks toggle integration (commented out since Snacks might not be available)
-- if Snacks and Snacks.toggle then
--     Snacks.toggle({
--         name = "Chunk Guides",
--         get = function()
--             return M.enabled
--         end,
--         set = function(enabled)
--             if enabled then
--                 M.enable()
--             else
--                 M.disable()
--             end
--         end,
--     }):map("<leader>uC")
-- end

return M

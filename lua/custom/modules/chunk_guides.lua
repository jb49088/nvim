-- TODO: test what other chunk plugins do with markdown and implement something similar
-- figure out what to do with chunk when folding code

local treesitter = vim.treesitter
local api = vim.api
local fn = vim.fn

-- Configuration
local config = {
    chars = {
        horizontal_line = "─",
        vertical_line = "│",
        corner_top = "╭",
        corner_bottom = "╰",
    },
    use_treesitter = true,
    max_file_size = 1024 * 1024, -- 1MB
}

-- Module state
local M = {
    ns_id = api.nvim_create_namespace("custom_chunk_guides"),
    augroup = nil,
    last_regular_win = nil,
    last_mode = nil,
    enabled = true,
    disabled_buffers = {}, -- Track buffers that are too large
}

-- Chunk range return codes
local CHUNK_RANGE_RET = {
    OK = 0,
    CHUNK_ERR = 1,
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

-- Check if buffer is disabled due to size
local function is_buffer_disabled(bufnr)
    return M.disabled_buffers[bufnr] == true
end

-- Check if node type is suitable for chunk detection
local function is_suit_type(node_type)
    local ft = vim.bo.filetype
    local is_spec_ft = node_types[ft]

    if is_spec_ft then
        return is_spec_ft[node_type] == true
    else
        -- Use patterns for default types
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
    end

    return false
end

-- Check if treesitter is available for current buffer
local function has_treesitter(bufnr)
    local ft = vim.bo[bufnr].filetype
    local has_lang, lang = pcall(treesitter.language.get_lang, ft)
    if not has_lang then
        return false
    end

    local has, parser = pcall(treesitter.get_parser, bufnr, lang)
    return has and parser ~= nil
end

-- Enhanced context-based detection for end-of-line cursors
local function get_chunk_range_by_context(bufnr, row, col)
    local base_flag = "nWz"
    local cur_row_val = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if not cur_row_val then
        return CHUNK_RANGE_RET.NO_CHUNK, nil
    end

    local line_len = #cur_row_val

    -- Smart position selection for end-of-line cases
    local search_positions = {}

    if col >= line_len then
        -- Cursor at or past end of line - work backwards through meaningful positions
        if line_len > 0 then
            for i = line_len - 1, 0, -1 do
                table.insert(search_positions, i)
            end
        end
        table.insert(search_positions, 0) -- Beginning of line fallback
    else
        -- Normal position
        table.insert(search_positions, col)
        if col > 0 then
            table.insert(search_positions, col - 1)
        end
    end

    -- Save current cursor position
    local save_cursor = api.nvim_win_get_cursor(0)

    for _, search_col in ipairs(search_positions) do
        -- Ensure search_col is within bounds
        search_col = math.max(0, math.min(search_col, line_len - 1))
        local cur_char = cur_row_val:sub(search_col + 1, search_col + 1)

        -- Set cursor to search position
        api.nvim_win_set_cursor(0, { row + 1, search_col })

        local beg_row = fn.searchpair("{", "", "}", base_flag .. "b" .. (cur_char == "{" and "c" or ""))
        local end_row = fn.searchpair("{", "", "}", base_flag .. (cur_char == "}" and "c" or ""))

        if beg_row > 0 and end_row > 0 and beg_row < end_row then
            -- Restore cursor position before returning
            api.nvim_win_set_cursor(0, save_cursor)
            return CHUNK_RANGE_RET.OK,
                {
                    start_row = beg_row - 1, -- Convert to 0-indexed
                    end_row = end_row - 1,
                }
        end
    end

    -- Restore cursor position
    api.nvim_win_set_cursor(0, save_cursor)
    return CHUNK_RANGE_RET.NO_CHUNK, nil
end

-- Simplified treesitter chunk detection that prioritizes nodes starting on current line
local function get_chunk_range_by_treesitter(bufnr, row, col)
    if not has_treesitter(bufnr) then
        return CHUNK_RANGE_RET.NO_TS, nil
    end

    -- Try different positions on the line to get all possible nodes
    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local line_len = #line

    local all_candidates = {}

    -- Try positions across the line to collect all possible nodes
    local positions_to_check = { 0 } -- Always check beginning of line
    if line_len > 0 then
        -- Add middle and end positions
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

        -- When cursor_node is comment content (source), find by tree
        if cursor_node and cursor_node:type() == "source" then
            cursor_node = treesitter.get_node({
                bufnr = bufnr,
                pos = { row, check_col },
            })
        end

        -- Walk up the tree and collect candidates
        local current_node = cursor_node
        while current_node do
            local node_type = current_node:type()
            local node_start, _, node_end, _ = current_node:range()

            if node_start ~= node_end and is_suit_type(node_type) then
                -- Check if we already have this node
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

    -- Find the best candidate: prioritize nodes that start on current row, then smallest
    local best_candidate = nil

    -- First, look for nodes that start on the cursor row
    for _, candidate in ipairs(all_candidates) do
        if candidate.starts_on_cursor_row then
            if not best_candidate or candidate.size < best_candidate.size then
                best_candidate = candidate
            end
        end
    end

    -- If no node starts on cursor row, fall back to smallest containing node
    if not best_candidate then
        for _, candidate in ipairs(all_candidates) do
            if not best_candidate or candidate.size < best_candidate.size then
                best_candidate = candidate
            end
        end
    end

    local ret_code = best_candidate.node:has_error() and CHUNK_RANGE_RET.CHUNK_ERR or CHUNK_RANGE_RET.OK
    return ret_code, {
        start_row = best_candidate.start_row,
        end_row = best_candidate.end_row,
    }
end

-- Main chunk range function
local function get_chunk_range(bufnr, row, col, use_treesitter)
    if use_treesitter then
        return get_chunk_range_by_treesitter(bufnr, row, col)
    else
        return get_chunk_range_by_context(bufnr, row, col)
    end
end

-- Get indentation level for a line
local function get_indent_level(bufnr, row)
    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if not line then
        return 0
    end

    local indent = 0
    local tabstop = vim.bo[bufnr].tabstop

    local i = 1
    while i <= #line do
        local char = line:sub(i, i)
        if char == " " then
            indent = indent + 1
        elseif char == "\t" then
            indent = indent + tabstop
        else
            break
        end
        i = i + 1
    end

    return indent
end

-- Calculate virtual text position
local function calc_virt_text_pos(text, start_col, leftcol)
    local len = api.nvim_strwidth(text)
    if start_col < leftcol then
        local byte_idx = math.min(leftcol - start_col, len)
        local utf_beg = vim.str_byteindex(text, byte_idx)
        text = text:sub(utf_beg + 1)
    end

    local win_col = math.max(start_col - leftcol, 0)
    return text, win_col
end

-- Split UTF-8 string into characters
local function utf8_split(str)
    local chars = {}
    for char in str:gmatch("[^\128-\191][\128-\191]*") do
        chars[#chars + 1] = char
    end
    return chars
end

-- Get character at position
local function get_char_at_pos(bufnr, row, col, expand_tab_width)
    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if not line then
        return ""
    end

    if expand_tab_width then
        local expanded_tab = (" "):rep(expand_tab_width)
        line = line:gsub("\t", expanded_tab)
    end
    return line:sub(col + 1, col + 1)
end

-- Simple highlight color cache
local highlight_cache = {}

-- Optimized highlight color retrieval with caching
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

-- Pre-defined mode color mapping for better performance
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

-- Optimized mode color detection
local function get_mode_color()
    local mode_code = api.nvim_get_mode().mode
    local color_group = mode_color_map[mode_code] or "ModeColorNormal"
    return get_highlight_color(color_group) or "#ffffff"
end

-- Create or update highlight group for current mode
local function update_mode_highlight()
    local color = get_mode_color()
    if color then
        api.nvim_set_hl(0, "ChunkGuidesMode", { fg = color })
        return "ChunkGuidesMode"
    end
    return "Comment" -- Fallback
end

-- Clear highlights
local function clear_highlights(bufnr)
    if api.nvim_buf_is_valid(bufnr) then
        api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
    end
end

-- Set extmarks with bounds checking
local function set_extmarks_batch(bufnr, extmarks)
    if not api.nvim_buf_is_valid(bufnr) then
        return
    end

    local line_count = api.nvim_buf_line_count(bufnr)

    for _, mark in ipairs(extmarks) do
        if mark.row >= 0 and mark.row < line_count then
            pcall(api.nvim_buf_set_extmark, bufnr, M.ns_id, mark.row, mark.col, mark.opts)
        end
    end
end

-- Check if buffer exceeds max file size
local function check_buffer_size(bufnr)
    if not api.nvim_buf_is_valid(bufnr) then
        return false
    end

    local name = api.nvim_buf_get_name(bufnr)
    if name == "" then
        return false -- Don't check size for unnamed buffers
    end

    local ok, file_size = pcall(fn.getfsize, name)
    return ok and file_size > config.max_file_size
end

-- Main rendering function
local function render_chunk_guides(bufnr)
    if not api.nvim_buf_is_valid(bufnr) then
        return
    end

    -- Only render for current window
    local current_win = api.nvim_get_current_win()
    local current_buf = api.nvim_get_current_buf()
    if bufnr ~= current_buf then
        return
    end

    -- Check if this specific buffer is too large
    if check_buffer_size(bufnr) then
        if not M.disabled_buffers[bufnr] then
            M.disabled_buffers[bufnr] = true
            vim.notify("File is too large, chunk guides disabled for this buffer", vim.log.levels.WARN)
        end
        return
    end

    -- Check if this buffer was previously disabled but is now valid
    if M.disabled_buffers[bufnr] and not check_buffer_size(bufnr) then
        M.disabled_buffers[bufnr] = nil
    end

    local winid = api.nvim_get_current_win()
    local cursor = api.nvim_win_get_cursor(winid)
    local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-indexed

    clear_highlights(bufnr)

    local ret_code, chunk_range = get_chunk_range(bufnr, row, col, config.use_treesitter)

    if ret_code ~= CHUNK_RANGE_RET.OK and ret_code ~= CHUNK_RANGE_RET.CHUNK_ERR then
        return
    end

    if not chunk_range then
        return
    end

    -- Update highlight group based on current mode
    local highlight_group = update_mode_highlight()

    local start_row, end_row = chunk_range.start_row, chunk_range.end_row
    local leftcol = fn.winsaveview().leftcol
    local shiftwidth = fn.shiftwidth()

    -- Get indentation levels
    local start_indent = get_indent_level(bufnr, start_row)
    local end_indent = get_indent_level(bufnr, end_row)

    -- Get indentation levels and calculate guide position
    -- Use original logic but with safety checks for malformed indentation
    local guide_col = math.max(math.min(start_indent, end_indent) - shiftwidth, 0)

    -- SAFETY CHECK: Ensure guide doesn't overlap with actual text content
    -- Check all lines in the chunk to make sure guide_col is safe
    local min_content_start = math.huge

    for r = start_row, end_row do
        local line = api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
        if line:match("%S") then -- line contains non-whitespace
            -- Find where actual content starts (first non-whitespace character)
            local content_start = line:find("%S") - 1 -- Convert to 0-indexed
            min_content_start = math.min(min_content_start, content_start)
        end
    end

    -- If guide would overlap with content, move it to a safe position
    if min_content_start ~= math.huge and guide_col >= min_content_start then
        guide_col = math.max(min_content_start - 1, 0)
    end

    local extmarks = {}

    -- Render top corner - only if we have a safe position and actual indentation
    if start_indent > 0 and guide_col < start_indent and guide_col >= leftcol then
        -- Double-check that we won't overlap with text on the start row
        local start_line = api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
        local start_char_at_guide = start_line:sub(guide_col + 1, guide_col + 1)

        if start_char_at_guide:match("%s") or start_char_at_guide == "" then
            local virt_text_len = start_indent - guide_col
            local top_line = config.chars.corner_top
                .. config.chars.horizontal_line:rep(math.max(0, virt_text_len - 2))
                .. config.chars.horizontal_line

            local virt_text, win_col = calc_virt_text_pos(top_line, guide_col, leftcol)

            if win_col >= 0 and #virt_text > 0 then
                local chars = utf8_split(virt_text)
                for i, char in ipairs(chars) do
                    -- Additional safety: check each character position
                    local char_pos = guide_col + i - 1
                    local actual_char = start_line:sub(char_pos + 1, char_pos + 1)
                    if actual_char:match("%s") or actual_char == "" then
                        extmarks[#extmarks + 1] = {
                            row = start_row,
                            col = 0,
                            opts = {
                                virt_text = { { char, highlight_group } },
                                virt_text_pos = "overlay",
                                virt_text_win_col = win_col + i - 1,
                                hl_mode = "combine",
                                priority = 100,
                            },
                        }
                    end
                end
            end
        end
    end

    -- Render vertical lines for middle rows
    if guide_col >= leftcol then
        for r = start_row + 1, end_row - 1 do
            local line = api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
            local char_at_pos = ""

            if guide_col < #line then
                char_at_pos = line:sub(guide_col + 1, guide_col + 1)
            end

            -- Only place guide if position is whitespace or beyond line end
            if char_at_pos:match("%s") or char_at_pos == "" then
                extmarks[#extmarks + 1] = {
                    row = r,
                    col = 0,
                    opts = {
                        virt_text = { { config.chars.vertical_line, highlight_group } },
                        virt_text_pos = "overlay",
                        virt_text_win_col = guide_col - leftcol,
                        hl_mode = "combine",
                        priority = 100,
                    },
                }
            end
        end
    end

    -- Render bottom corner - only if we have a safe position and actual indentation
    if end_indent > 0 and guide_col < end_indent and guide_col >= leftcol then
        -- Double-check that we won't overlap with text on the end row
        local end_line = api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
        local end_char_at_guide = end_line:sub(guide_col + 1, guide_col + 1)

        if end_char_at_guide:match("%s") or end_char_at_guide == "" then
            local virt_text_len = end_indent - guide_col
            local bottom_line = config.chars.corner_bottom
                .. config.chars.horizontal_line:rep(math.max(0, virt_text_len - 2))
                .. config.chars.horizontal_line

            local virt_text, win_col = calc_virt_text_pos(bottom_line, guide_col, leftcol)

            if win_col >= 0 and #virt_text > 0 then
                local chars = utf8_split(virt_text)
                for i, char in ipairs(chars) do
                    -- Additional safety: check each character position
                    local char_pos = guide_col + i - 1
                    local actual_char = end_line:sub(char_pos + 1, char_pos + 1)
                    if actual_char:match("%s") or actual_char == "" then
                        extmarks[#extmarks + 1] = {
                            row = end_row,
                            col = 0,
                            opts = {
                                virt_text = { { char, highlight_group } },
                                virt_text_pos = "overlay",
                                virt_text_win_col = win_col + i - 1,
                                hl_mode = "combine",
                                priority = 100,
                            },
                        }
                    end
                end
            end
        end
    end

    -- Set all extmarks
    set_extmarks_batch(bufnr, extmarks)
end

-- Buffer validation
local function should_render(bufnr)
    -- Check if globally disabled
    if not M.enabled then
        return false
    end

    -- Check if this specific buffer is disabled
    if is_buffer_disabled(bufnr) then
        return false
    end

    local filetype = vim.bo[bufnr].filetype
    local buftype = vim.bo[bufnr].buftype

    -- Skip special buffer types
    if buftype ~= "" then
        return false
    elseif filetype == "" then
        return false
    elseif fn.shiftwidth() == 0 then
        return false
    end

    return true
end

-- Check if window is floating
local function is_floating_win(winid)
    local win_config = api.nvim_win_get_config(winid or 0)
    return win_config.relative ~= ""
end

-- Enable chunks with immediate rendering
local function enable_chunks()
    local bufnr = api.nvim_get_current_buf()
    if should_render(bufnr) then
        vim.schedule(function()
            if api.nvim_buf_is_valid(bufnr) and should_render(bufnr) then
                render_chunk_guides(bufnr)
            end
        end)
    end
end

-- Disable chunks for buffer
local function disable_chunks_for_buffer(bufnr)
    if api.nvim_buf_is_valid(bufnr) then
        clear_highlights(bufnr)
    end
end

-- Mode change handler
local function on_mode_changed()
    local current_mode = api.nvim_get_mode().mode

    -- Update the highlight group for the new mode
    update_mode_highlight()

    -- If we have a last regular window with chunks, re-render to update colors
    if M.last_regular_win and api.nvim_win_is_valid(M.last_regular_win) then
        api.nvim_win_call(M.last_regular_win, function()
            local bufnr = api.nvim_get_current_buf()
            if should_render(bufnr) then
                render_chunk_guides(bufnr)
            end
        end)
    end

    M.last_mode = current_mode
end

-- Handle cursor/text changes
local function on_change()
    if not M.enabled then
        return
    end

    local bufnr = api.nvim_get_current_buf()
    if should_render(bufnr) then
        render_chunk_guides(bufnr)
    end
end

-- Clean up disabled buffers when they are deleted
local function cleanup_disabled_buffer(bufnr)
    if M.disabled_buffers[bufnr] then
        M.disabled_buffers[bufnr] = nil
    end
end

-- Setup autocmds
local function setup_autocmds()
    M.augroup = api.nvim_create_augroup("CustomChunkGuides", { clear = true })

    -- Window management
    api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "BufEnter" }, {
        group = M.augroup,
        callback = function()
            local current_win = api.nvim_get_current_win()

            if is_floating_win(current_win) then
                return
            end

            -- Disable chunks on previous regular window if different
            if
                M.last_regular_win
                and M.last_regular_win ~= current_win
                and api.nvim_win_is_valid(M.last_regular_win)
            then
                api.nvim_win_call(M.last_regular_win, function()
                    local prev_bufnr = api.nvim_get_current_buf()
                    disable_chunks_for_buffer(prev_bufnr)
                end)
            end

            -- Enable chunks immediately if the module is enabled
            if M.enabled then
                enable_chunks()
            end

            M.last_regular_win = current_win
        end,
    })

    -- Updated: Use the same events as the working plugin
    api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = M.augroup,
        callback = function()
            if not M.enabled then
                return
            end
            local bufnr = api.nvim_get_current_buf()
            if should_render(bufnr) then
                render_chunk_guides(bufnr)
            end
        end,
    })

    -- Additional events for immediate updates
    api.nvim_create_autocmd({
        "CursorMoved",
        "CursorMovedI",
        "TextChanged",
        "TextChangedI",
        "TextChangedP", -- Added: handles completion changes
        "InsertLeave", -- Added: when leaving insert mode
        "InsertEnter", -- Added: when entering insert mode
    }, {
        group = M.augroup,
        callback = function()
            if not M.enabled then
                return
            end
            local bufnr = api.nvim_get_current_buf()
            if should_render(bufnr) then
                -- Use vim.schedule to avoid issues with events firing during text changes
                vim.schedule(function()
                    if api.nvim_buf_is_valid(bufnr) and should_render(bufnr) then
                        render_chunk_guides(bufnr)
                    end
                end)
            end
        end,
    })

    -- Mode changes
    api.nvim_create_autocmd({ "ModeChanged", "CmdlineEnter", "CmdlineLeave" }, {
        group = M.augroup,
        callback = on_mode_changed,
    })

    -- Session and startup
    api.nvim_create_autocmd({ "SessionLoadPost", "VimEnter" }, {
        group = M.augroup,
        callback = function()
            if M.enabled then
                vim.schedule(enable_chunks)
            end
        end,
    })

    -- Buffer cleanup
    api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = M.augroup,
        callback = function(event)
            cleanup_disabled_buffer(event.buf)
        end,
    })

    -- Cleanup
    api.nvim_create_autocmd({ "VimLeavePre" }, {
        group = M.augroup,
        callback = function()
            for _, bufnr in pairs(api.nvim_list_bufs()) do
                if api.nvim_buf_is_valid(bufnr) then
                    clear_highlights(bufnr)
                end
            end
        end,
    })
end

-- Initialize
local function init()
    setup_autocmds()

    vim.schedule(function()
        local bufnr = api.nvim_get_current_buf()
        if should_render(bufnr) then
            render_chunk_guides(bufnr)
        end
    end)
end

-- Public API
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
end

function M.enable()
    M.enabled = true
    enable_chunks()
end

function M.disable()
    M.enabled = false
    for _, bufnr in pairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(bufnr) then
            clear_highlights(bufnr)
        end
    end
end

function M.refresh()
    local bufnr = api.nvim_get_current_buf()
    if should_render(bufnr) then
        render_chunk_guides(bufnr)
    end
end

-- Enable chunk guides for a specific buffer (removes it from disabled list)
function M.enable_for_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if M.disabled_buffers[bufnr] then
        M.disabled_buffers[bufnr] = nil
        if should_render(bufnr) then
            render_chunk_guides(bufnr)
        end
    end
end

-- Disable chunk guides for a specific buffer
function M.disable_for_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    M.disabled_buffers[bufnr] = true
    clear_highlights(bufnr)
end

-- Check if chunk guides are enabled for a specific buffer
function M.is_enabled_for_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    return M.enabled and not M.disabled_buffers[bufnr]
end

-- Auto-initialize
init()

-- Snacks toggle integration
if Snacks and Snacks.toggle then
    Snacks.toggle({
        name = "Chunk Guides",
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
    }):map("<leader>uC")
end

return M

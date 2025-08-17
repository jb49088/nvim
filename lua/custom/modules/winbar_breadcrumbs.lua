-- winbar_breadcrumbs.lua - Enhanced with navic-style symbol handling and tree structure

local M = {}

-- Add enabled state tracking
M.enabled = false

-- Store client info per buffer (for the currently attached LSP)
local attached_lsp_clients = {}

-- Store parsed symbol trees per buffer (following navic's approach)
local buffer_symbol_trees = {}

-- Store context data per buffer (symbols containing cursor)
local buffer_context_data = {}

-- Store augroup IDs for cleanup
local augroups = {}

-- Track awaiting LSP response status
local awaiting_lsp_response = {}

-- Mode color mapping
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

-- Cache the current mode to avoid repeated calls
local current_cached_mode = nil
local mode_cache_timer = nil

-- Configuration options
local config = {
    lsp = {
        auto_attach = true,
        preference = nil,
        focus_only = true,
    },
    symbol_request = {
        debounce_ms = 500,
        max_retries = 3,
        retry_delay_ms = 200,
    },
    truncation = {
        enabled = true,
        separator = "  ",
        extends_symbol = "…",
        min_symbol_width = 1,
    },
    mode_colors = {
        enabled = true,
        separator_only = true,
        fallback_color = "#ffffff",
    },
    bar = {
        enable = function(buf, win)
            if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
                return false
            end

            if vim.fn.win_gettype(win) ~= "" then
                return false
            end

            local current_winbar = vim.wo[win].winbar
            if current_winbar ~= "" and not current_winbar:match("breadcrumbs") then
                return false
            end

            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname ~= "" then
                local stat = vim.uv.fs_stat(bufname)
                if stat and stat.size > 1024 * 1024 then
                    return false
                end
            end

            local buftype = vim.bo[buf].buftype
            if buftype == "quickfix" or buftype == "nofile" or buftype == "prompt" or buftype == "terminal" then
                return false
            end

            local filetype = vim.bo[buf].filetype
            if filetype == "markdown" or filetype == "help" then
                return true
            end

            local has_parser = pcall(vim.treesitter.get_parser, buf)
            if has_parser then
                return true
            end

            local lsp_clients = vim.lsp.get_clients({
                bufnr = buf,
                method = vim.lsp.protocol.Methods.textDocument_documentSymbol,
            })
            if not vim.tbl_isempty(lsp_clients) then
                return true
            end

            if buftype == "" and bufname ~= "" then
                return true
            end

            return false
        end,
    },
}

-- Debounce timer for symbol requests
local debounce_timers = {}

-- Utility function to get highlight color
local function get_highlight_color(group_name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group_name })
    if ok and hl.fg then
        return string.format("#%06x", hl.fg)
    end
    return nil
end

-- Get current mode color
local function get_mode_color()
    if not config.mode_colors.enabled then
        return nil
    end

    local mode_code = current_cached_mode or vim.api.nvim_get_mode().mode
    local color_group = mode_color_map[mode_code] or "ModeColorNormal"
    return get_highlight_color(color_group) or config.mode_colors.fallback_color
end

-- Update mode highlight group for breadcrumbs
local function update_mode_highlight()
    if not config.mode_colors.enabled then
        return nil
    end

    local color = get_mode_color()
    if color then
        vim.api.nvim_set_hl(0, "BreadcrumbsMode", { fg = color })
        return "BreadcrumbsMode"
    end
    return "WinBar"
end

-- Update cached mode and refresh all winbars
local function update_cached_mode_and_refresh()
    local new_mode = vim.api.nvim_get_mode().mode

    if new_mode ~= current_cached_mode then
        current_cached_mode = new_mode
        update_mode_highlight()

        vim.schedule(function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win) then
                    local current_winbar = vim.wo[win].winbar
                    if current_winbar and current_winbar:match("breadcrumbs") then
                        vim.api.nvim_win_set_option(win, "winbar", current_winbar)
                    end
                end
            end
        end)
    end
end

-- Get icon using mini.icons
local function get_file_icon(filename, filetype)
    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return nil, nil
    end

    local icon, hl, is_default
    if type(filename) == "string" and filename ~= "" then
        icon, hl, is_default = mini_icons.get("file", filename)
        if not is_default then
            return icon, hl
        end
    end

    if filetype and type(filetype) == "string" and filetype ~= "" then
        icon, hl, is_default = mini_icons.get("filetype", filetype)
        if not is_default then
            return icon, hl
        end
    end

    return nil, nil
end

-- Get LSP kind icon using mini.icons
local function get_lsp_kind_icon(kind)
    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return nil, nil
    end

    local kind_map = {
        [1] = "file",
        [2] = "module",
        [3] = "namespace",
        [4] = "package",
        [5] = "class",
        [6] = "method",
        [7] = "property",
        [8] = "field",
        [9] = "constructor",
        [10] = "enum",
        [11] = "interface",
        [12] = "function",
        [13] = "variable",
        [14] = "constant",
        [15] = "string",
        [16] = "number",
        [17] = "boolean",
        [18] = "array",
        [19] = "object",
        [20] = "key",
        [21] = "null",
        [22] = "enummember",
        [23] = "struct",
        [24] = "event",
        [25] = "operator",
        [26] = "typeparameter",
    }

    local kind_name = kind_map[kind]
    if kind_name then
        local icon, hl, is_default = mini_icons.get("lsp", kind_name)
        if not is_default then
            return icon, hl
        end
    end

    return nil, nil
end

--- Symbol tree parsing (following navic's approach)
local function symbol_relation(symbol, other)
    local s = symbol.scope
    local o = other.scope

    if
        o["end"].line < s["start"].line
        or (o["end"].line == s["start"].line and o["end"].character <= s["start"].character)
    then
        return "before"
    end

    if
        o["start"].line > s["end"].line
        or (o["start"].line == s["end"].line and o["start"].character >= s["end"].character)
    then
        return "after"
    end

    if
        (
            o["start"].line < s["start"].line
            or (o["start"].line == s["start"].line and o["start"].character <= s["start"].character)
        )
        and (
            o["end"].line > s["end"].line
            or (o["end"].line == s["end"].line and o["end"].character >= s["end"].character)
        )
    then
        return "around"
    end

    return "within"
end

local function symbolInfo_treemaker(symbols, root_node)
    -- Convert location to scope
    for _, node in ipairs(symbols) do
        node.scope = node.location.range
        node.scope["start"].line = node.scope["start"].line + 1
        node.scope["end"].line = node.scope["end"].line + 1
        node.location = nil
        node.name_range = node.scope
        node.containerName = nil
    end

    -- Sort symbols
    table.sort(symbols, function(a, b)
        local loc = symbol_relation(a, b)
        return loc == "after" or loc == "within"
    end)

    -- Build tree
    root_node.children = {}
    if #symbols == 0 then
        return
    end

    table.insert(root_node.children, symbols[1])
    symbols[1].parent = root_node
    local stack = { root_node }

    for i = 2, #symbols do
        local prev_chain_node_relation = symbol_relation(symbols[i], symbols[i - 1])
        local stack_top_node_relation = symbol_relation(symbols[i], stack[#stack])

        if prev_chain_node_relation == "around" then
            table.insert(stack, symbols[i - 1])
            if not symbols[i - 1].children then
                symbols[i - 1].children = {}
            end
            table.insert(symbols[i - 1].children, symbols[i])
            symbols[i].parent = symbols[i - 1]
        elseif prev_chain_node_relation == "before" and stack_top_node_relation == "around" then
            table.insert(stack[#stack].children, symbols[i])
            symbols[i].parent = stack[#stack]
        elseif stack_top_node_relation == "before" then
            while symbol_relation(symbols[i], stack[#stack]) ~= "around" do
                stack[#stack] = nil
            end
            table.insert(stack[#stack].children, symbols[i])
            symbols[i].parent = stack[#stack]
        end
    end

    local function dfs_index(node)
        if node.children == nil then
            return
        end

        for i = 1, #node.children do
            node.children[i].index = i
            dfs_index(node.children[i])
        end

        for i = 1, #node.children do
            local curr_node = node.children[i]
            if i ~= 1 then
                local prev_node = node.children[i - 1]
                prev_node.next = curr_node
                curr_node.prev = prev_node
            end
            if node.children[i + 1] ~= nil then
                local next_node = node.children[i + 1]
                next_node.prev = curr_node
                curr_node.next = next_node
            end
        end
    end

    dfs_index(root_node)
end

local function dfs(curr_symbol_layer, parent_node)
    if #curr_symbol_layer == 0 then
        return
    end

    parent_node.children = {}

    for _, val in ipairs(curr_symbol_layer) do
        local scope = val.range
        scope["start"].line = scope["start"].line + 1
        scope["end"].line = scope["end"].line + 1

        local name_range = val.selectionRange
        name_range["start"].line = name_range["start"].line + 1
        name_range["end"].line = name_range["end"].line + 1

        local curr_parsed_symbol = {
            name = val.name or "<???>",
            scope = scope,
            name_range = name_range,
            kind = val.kind or 0,
            parent = parent_node,
        }

        if val.children then
            dfs(val.children, curr_parsed_symbol)
        end

        table.insert(parent_node.children, curr_parsed_symbol)
    end

    table.sort(parent_node.children, function(a, b)
        if b.scope.start.line == a.scope.start.line then
            return b.scope.start.character > a.scope.start.character
        end
        return b.scope.start.line > a.scope.start.line
    end)

    for i = 1, #parent_node.children do
        parent_node.children[i].prev = parent_node.children[i - 1]
        parent_node.children[i].next = parent_node.children[i + 1]
        parent_node.children[i].index = i
    end
end

--- Parse LSP symbols into tree structure (following navic's approach)
local function parse_symbols(symbols)
    local root_node = {
        is_root = true,
        index = 1,
        scope = {
            start = { line = -10, character = 0 },
            ["end"] = { line = 2147483640, character = 0 },
        },
    }

    if #symbols >= 1 and symbols[1].range == nil then
        symbolInfo_treemaker(symbols, root_node)
    else
        dfs(symbols, root_node)
    end

    return root_node
end

--- Check if cursor position is within a range
local function in_range(cursor_pos, range)
    local line = cursor_pos[1]
    local char = cursor_pos[2]

    if line < range["start"].line then
        return -1
    elseif line > range["end"].line then
        return 1
    end

    if line == range["start"].line and char < range["start"].character then
        return -1
    elseif line == range["end"].line and char > range["end"].character then
        return 1
    end

    return 0
end

--- Update context data (symbols containing cursor) following navic's approach
local function update_context(bufnr, cursor_pos)
    cursor_pos = cursor_pos or vim.api.nvim_win_get_cursor(0)

    if buffer_context_data[bufnr] == nil then
        buffer_context_data[bufnr] = {}
    end

    local old_context_data = buffer_context_data[bufnr]
    local new_context_data = {}
    local curr = buffer_symbol_trees[bufnr]

    if curr == nil then
        return
    end

    -- Always keep root node
    if curr.is_root then
        table.insert(new_context_data, curr)
    end

    -- Find larger context that remained same
    for _, context in ipairs(old_context_data) do
        if curr == nil then
            break
        end
        if
            in_range(cursor_pos, context.scope) == 0
            and curr.children ~= nil
            and curr.children[context.index] ~= nil
            and context.name == curr.children[context.index].name
            and context.kind == curr.children[context.index].kind
        then
            table.insert(new_context_data, curr.children[context.index])
            curr = curr.children[context.index]
        else
            break
        end
    end

    -- Fill out context_data using binary search
    while curr.children ~= nil do
        local go_deeper = false
        local l = 1
        local h = #curr.children

        while l <= h do
            local m = bit.rshift(l + h, 1)
            local comp = in_range(cursor_pos, curr.children[m].scope)
            if comp == -1 then
                h = m - 1
            elseif comp == 1 then
                l = m + 1
            else
                table.insert(new_context_data, curr.children[m])
                curr = curr.children[m]
                go_deeper = true
                break
            end
        end

        if not go_deeper then
            break
        end
    end

    buffer_context_data[bufnr] = new_context_data
end

--- Get context data for buffer
local function get_context_data(bufnr)
    return buffer_context_data[bufnr]
end

--- Build breadcrumb parts with icons and highlights
local function build_breadcrumb_parts(filepath, context_symbols)
    local parts = {}

    if filepath == "" then
        return parts
    end

    local sep = package.config:sub(1, 1)
    local ok, mini_icons = pcall(require, "mini.icons")

    -- Normalize and process file path (keeping your existing logic)
    filepath = vim.fs.normalize(filepath)
    local cwd = vim.fs.normalize(vim.fn.getcwd())
    local relpath

    if filepath:sub(1, #cwd) == cwd then
        relpath = filepath:sub(#cwd + 1)
        if relpath:sub(1, 1) == sep then
            relpath = relpath:sub(2)
        end
        if relpath == "" then
            relpath = vim.fn.fnamemodify(filepath, ":t")
        end
    else
        local home = vim.fs.normalize(vim.env.HOME or vim.fn.expand("$HOME"))
        if filepath:sub(1, #home) == home then
            relpath = filepath:sub(#home + 1)
            if relpath:sub(1, 1) == sep then
                relpath = relpath:sub(2)
            end
        else
            relpath = filepath
            if relpath:sub(1, 1) == sep then
                relpath = relpath:sub(2)
            end
        end
    end

    -- Split path and add path parts
    local path_parts = vim.split(relpath, sep, { plain = true })
    local filtered_parts = {}
    for _, part in ipairs(path_parts) do
        if part ~= "" then
            table.insert(filtered_parts, part)
        end
    end

    for i, part in ipairs(filtered_parts) do
        local icon, hl_group = nil, nil

        if i < #filtered_parts and ok then
            icon, hl_group = mini_icons.get("directory", part)
        elseif i == #filtered_parts then
            local filename = part
            local filetype = vim.bo.filetype
            icon, hl_group = get_file_icon(filename, filetype)
        end

        table.insert(parts, {
            text = part,
            highlight = nil,
            icon = icon,
            icon_highlight = hl_group,
        })
    end

    -- Add context symbols (skip root)
    if context_symbols and #context_symbols > 1 then
        for i = 2, #context_symbols do -- Skip root node
            local symbol = context_symbols[i]
            if symbol.name and symbol.name ~= "" and not symbol.name:match("^%s*$") then
                local kind_icon, kind_hl = get_lsp_kind_icon(symbol.kind)

                table.insert(parts, {
                    text = symbol.name,
                    highlight = nil,
                    icon = kind_icon,
                    icon_highlight = kind_hl,
                })
            end
        end
    end

    return parts
end

--- Apply truncation logic (keeping your existing implementation)
local function apply_truncation(parts, available_width)
    if not config.truncation.enabled or #parts == 0 then
        return parts
    end

    local separator = config.truncation.separator
    local extends_symbol = config.truncation.extends_symbol
    local min_width = config.truncation.min_symbol_width

    local function get_part_display_width(part)
        local width = vim.fn.strdisplaywidth(part.text or "")
        if part.icon then
            width = width + vim.fn.strdisplaywidth(part.icon) + 1
        end
        return width
    end

    local function calculate_total_width(part_list)
        local total = 0
        local sep_width = vim.fn.strdisplaywidth(separator)

        for i, part in ipairs(part_list) do
            total = total + get_part_display_width(part)
            if i < #part_list then
                total = total + sep_width
            end
        end
        return total
    end

    local truncated_parts = {}
    for i, part in ipairs(parts) do
        truncated_parts[i] = {
            text = part.text,
            highlight = part.highlight,
            icon = part.icon,
            icon_highlight = part.icon_highlight,
            min_width = part.min_width or min_width,
        }
    end

    local current_width = calculate_total_width(truncated_parts)
    local delta = current_width - available_width

    if delta <= 0 then
        for _, part in ipairs(truncated_parts) do
            part.min_width = nil
        end
        return truncated_parts
    end

    -- Phase 1: Truncate individual parts
    for _, part in ipairs(truncated_parts) do
        if delta <= 0 then
            break
        end

        local text_len = vim.fn.strdisplaywidth(part.text)
        local extends_width = vim.fn.strdisplaywidth(extends_symbol)
        local min_len = extends_width + part.min_width

        if text_len > min_len then
            local max_reduction = text_len - min_len
            local reduction = math.min(delta, max_reduction)
            local new_len = text_len - reduction
            local truncated_chars = math.max(part.min_width, new_len - extends_width)
            part.text = vim.fn.strcharpart(part.text, 0, truncated_chars) .. extends_symbol
            delta = delta - reduction
        end
    end

    -- Phase 2: Remove parts from beginning
    if delta > 0 and #truncated_parts > 1 then
        local sep_width = vim.fn.strdisplaywidth(separator)
        local extends_part = {
            text = extends_symbol,
            highlight = nil,
            icon = nil,
            icon_highlight = nil,
        }

        local first_part = truncated_parts[1]
        local first_width = get_part_display_width(first_part)
        local extends_part_width = get_part_display_width(extends_part)
        local width_diff = extends_part_width - first_width

        if width_diff < 0 then
            truncated_parts[1] = extends_part
            delta = delta + width_diff

            while delta > 0 and #truncated_parts > 1 do
                local part_to_remove = truncated_parts[2]
                local part_width = get_part_display_width(part_to_remove)
                table.remove(truncated_parts, 2)
                delta = delta - part_width - sep_width
            end
        end
    end

    -- Phase 3: Final fallback
    if delta > 0 and #truncated_parts > 1 then
        local last_part = truncated_parts[#truncated_parts]
        local last_width = get_part_display_width(last_part)
        local extends_width = vim.fn.strdisplaywidth(extends_symbol)

        if last_width + extends_width <= available_width then
            truncated_parts = {
                { text = extends_symbol, highlight = nil, icon = nil, icon_highlight = nil },
                last_part,
            }
        else
            truncated_parts = {
                { text = extends_symbol, highlight = nil, icon = nil, icon_highlight = nil },
            }
        end
    end

    for _, part in ipairs(truncated_parts) do
        part.min_width = nil
    end

    return truncated_parts
end

--- Convert breadcrumb parts to display string (keeping your mode color logic)
local function parts_to_display_string(parts)
    if #parts == 0 then
        return ""
    end

    local separator = config.truncation.separator
    local result_parts = {}
    local mode_hl = update_mode_highlight()

    table.insert(result_parts, " ")

    for i, part in ipairs(parts) do
        if part.icon and part.icon_highlight then
            table.insert(result_parts, "%#" .. part.icon_highlight .. "#" .. part.icon .. "%*")
            table.insert(result_parts, " ")
        elseif part.icon then
            table.insert(result_parts, part.icon .. " ")
        end

        local text_hl = "WinBar"
        if config.mode_colors.enabled and not config.mode_colors.separator_only then
            text_hl = mode_hl or "WinBar"
        end
        table.insert(result_parts, "%#" .. text_hl .. "#" .. part.text .. "%*")

        if i < #parts then
            local separator_hl = "WinBar"
            if config.mode_colors.enabled then
                separator_hl = mode_hl or "WinBar"
            end
            table.insert(result_parts, "%#" .. separator_hl .. "#" .. separator .. "%*")
        end
    end

    table.insert(result_parts, " ")
    return table.concat(result_parts, "")
end

--- Attach winbar to window if conditions are met
local function attach_winbar(buf, win)
    buf = buf or vim.api.nvim_get_current_buf()
    win = win or vim.api.nvim_get_current_win()

    if not vim.api.nvim_win_is_valid(win) then
        return
    end

    if not M.enabled then
        local current_winbar = vim.wo[win].winbar
        if current_winbar:match("breadcrumbs") then
            vim.wo[win].winbar = ""
        end
        return
    end

    local should_enable
    if type(config.bar.enable) == "function" then
        should_enable = config.bar.enable(buf, win)
    else
        should_enable = config.bar.enable
    end

    if should_enable then
        vim.wo[win].winbar = "%{%v:lua.require'custom.modules.winbar_breadcrumbs'.get_filename_display()%}"
    else
        local current_winbar = vim.wo[win].winbar
        if current_winbar:match("breadcrumbs") then
            vim.wo[win].winbar = ""
        end
    end
end

--- Main function to get display string
function M.get_filename_display()
    if not M.enabled then
        return ""
    end

    local filepath = vim.api.nvim_buf_get_name(0)
    local bufnr = vim.api.nvim_get_current_buf()
    local context_symbols = get_context_data(bufnr)

    local parts = build_breadcrumb_parts(filepath, context_symbols)
    local available_width = vim.api.nvim_win_get_width(0) - 2

    if config.truncation.enabled then
        parts = apply_truncation(parts, available_width)
    end

    return parts_to_display_string(parts)
end

--- Cancel debounce timer for buffer
local function cancel_debounce_timer(bufnr)
    if debounce_timers[bufnr] then
        debounce_timers[bufnr]:stop()
        debounce_timers[bufnr]:close()
        debounce_timers[bufnr] = nil
    end
end

--- LSP callback following navic's approach
local function lsp_callback(bufnr, symbols)
    awaiting_lsp_response[bufnr] = false

    if symbols and #symbols > 0 then
        buffer_symbol_trees[bufnr] = parse_symbols(symbols)
    else
        buffer_symbol_trees[bufnr] = nil
    end

    vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
                local current_winbar = vim.wo[win].winbar
                if current_winbar and current_winbar:match("breadcrumbs") then
                    vim.wo[win].winbar = current_winbar
                end
            end
        end
    end)
end

--- Request symbols following navic's approach with retry logic
local function request_symbols(bufnr, client, retry_count)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end

    retry_count = retry_count or 10
    if retry_count == 0 then
        lsp_callback(bufnr, {})
        return
    end

    local textDocument_argument = vim.lsp.util.make_text_document_params(bufnr)

    local function make_request(...)
        if vim.fn.has("nvim-0.11") == 1 then
            client:request(...)
        else
            client.request(...)
        end
    end

    make_request("textDocument/documentSymbol", { textDocument = textDocument_argument }, function(err, symbols, _)
        if symbols == nil then
            if vim.api.nvim_buf_is_valid(bufnr) then
                lsp_callback(bufnr, {})
            end
        elseif err ~= nil then
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.defer_fn(function()
                    request_symbols(bufnr, client, retry_count - 1)
                end, 750)
            end
        elseif symbols ~= nil then
            if vim.api.nvim_buf_is_loaded(bufnr) then
                lsp_callback(bufnr, symbols)
            end
        end
    end, bufnr)
end

--- Attach LSP client following navic's approach
function M.attach(client, bufnr)
    if not client.server_capabilities.documentSymbolProvider then
        if not vim.g.navic_silence then
            vim.notify(
                'winbar_breadcrumbs: Server "' .. client.name .. '" does not support documentSymbols.',
                vim.log.levels.ERROR
            )
        end
        return
    end

    if vim.b[bufnr].breadcrumbs_client_id ~= nil and vim.b[bufnr].breadcrumbs_client_name ~= client.name then
        local prev_client = vim.b[bufnr].breadcrumbs_client_name
        if not vim.g.navic_silence then
            vim.notify(
                "winbar_breadcrumbs: Failed to attach to "
                    .. client.name
                    .. " for current buffer. Already attached to "
                    .. prev_client,
                vim.log.levels.WARN
            )
        end
        return
    end

    vim.b[bufnr].breadcrumbs_client_id = client.id
    vim.b[bufnr].breadcrumbs_client_name = client.name
    attached_lsp_clients[bufnr] = client
    local changedtick = 0

    local breadcrumbs_augroup = vim.api.nvim_create_augroup("breadcrumbs_lsp_" .. bufnr, { clear = false })
    vim.api.nvim_clear_autocmds({
        buffer = bufnr,
        group = breadcrumbs_augroup,
    })

    -- Request symbols on buffer changes
    vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter", "CursorHold" }, {
        callback = function()
            if not awaiting_lsp_response[bufnr] and changedtick < vim.b[bufnr].changedtick then
                awaiting_lsp_response[bufnr] = true
                changedtick = vim.b[bufnr].changedtick
                request_symbols(bufnr, client)
            end
        end,
        group = breadcrumbs_augroup,
        buffer = bufnr,
    })

    -- Update context on cursor movements
    vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
            update_context(bufnr)
        end,
        group = breadcrumbs_augroup,
        buffer = bufnr,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function()
            update_context(bufnr)
        end,
        group = breadcrumbs_augroup,
        buffer = bufnr,
    })

    -- Clean up on buffer delete
    vim.api.nvim_create_autocmd("BufDelete", {
        callback = function()
            buffer_symbol_trees[bufnr] = nil
            buffer_context_data[bufnr] = nil
            attached_lsp_clients[bufnr] = nil
            awaiting_lsp_response[bufnr] = nil
            cancel_debounce_timer(bufnr)
        end,
        group = breadcrumbs_augroup,
        buffer = bufnr,
    })

    -- Make initial request
    awaiting_lsp_response[bufnr] = true
    request_symbols(bufnr, client)
end

--- Check if breadcrumbs is available for buffer
function M.is_available(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return vim.b[bufnr].breadcrumbs_client_id ~= nil
end

--- Get breadcrumb data for buffer (following navic's API)
function M.get_data(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local context_data = get_context_data(bufnr)

    if context_data == nil or #context_data <= 1 then
        return nil
    end

    local ret = {}
    -- Skip root node (index 1)
    for i = 2, #context_data do
        local v = context_data[i]
        table.insert(ret, {
            kind = v.kind,
            name = v.name,
            scope = v.scope,
        })
    end

    return ret
end

--- Setup autocmds for LSP auto-attach
local function setup_lsp_auto_attach_autocmd()
    augroups.lsp_attach = vim.api.nvim_create_augroup("breadcrumbs_lsp_attach", { clear = true })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = augroups.lsp_attach,
        callback = function(args)
            if not M.enabled then
                return
            end

            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then
                return
            end

            if not client.server_capabilities.documentSymbolProvider then
                return
            end

            local prev_client = vim.b[args.buf].breadcrumbs_client_name
            if not prev_client or prev_client == client.name then
                if config.lsp.auto_attach then
                    if config.lsp.focus_only then
                        local current_buf = vim.api.nvim_get_current_buf()
                        if args.buf == current_buf then
                            M.attach(client, args.buf)
                        end
                    else
                        M.attach(client, args.buf)
                    end
                end
                return
            end

            if not config.lsp.preference then
                if not vim.g.navic_silence then
                    vim.notify(
                        "winbar_breadcrumbs: Trying to attach "
                            .. client.name
                            .. " for current buffer. Already attached to "
                            .. prev_client
                            .. ". Please use the preference option to set a higher preference for one of the servers",
                        vim.log.levels.WARN
                    )
                end
                return
            end

            for _, preferred_lsp in ipairs(config.lsp.preference) do
                if preferred_lsp == client.name then
                    vim.b[args.buf].breadcrumbs_client_id = nil
                    vim.b[args.buf].breadcrumbs_client_name = nil
                    M.attach(client, args.buf)
                    return
                elseif preferred_lsp == prev_client then
                    return
                end
            end
        end,
    })
end

--- Setup autocmds to refresh symbols when buffer content changes and cursor moves
local function setup_symbol_refresh_autocmds()
    augroups.symbol_refresh = vim.api.nvim_create_augroup("breadcrumbs_symbol_refresh", { clear = true })

    -- Refresh breadcrumbs display when cursor moves (no need to refetch symbols)
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = augroups.symbol_refresh,
        callback = function()
            if not M.enabled then
                return
            end

            vim.schedule(function()
                vim.cmd.redrawstatus()
            end)
        end,
    })
end

--- Setup autocmds to refresh breadcrumbs on mode changes for color updates
local function setup_mode_change_autocmds()
    if not config.mode_colors.enabled then
        return
    end

    augroups.mode_change = vim.api.nvim_create_augroup("breadcrumbs_mode_change", { clear = true })

    vim.api.nvim_create_autocmd({
        "ModeChanged",
        "CursorMoved",
        "CursorMovedI",
        "InsertEnter",
        "InsertLeave",
        "CmdlineEnter",
        "CmdlineLeave",
        "TermEnter",
        "TermLeave",
    }, {
        group = augroups.mode_change,
        callback = function()
            if not M.enabled then
                return
            end

            if mode_cache_timer then
                mode_cache_timer:stop()
                mode_cache_timer:close()
                mode_cache_timer = nil
            end

            update_cached_mode_and_refresh()

            mode_cache_timer = vim.defer_fn(function()
                update_cached_mode_and_refresh()
                mode_cache_timer = nil
            end, 10)
        end,
    })
end

--- Handle buffer focus changes to attach/detach breadcrumbs
local function setup_buffer_focus_autocmds()
    if not config.lsp.focus_only then
        return
    end

    augroups.focus = vim.api.nvim_create_augroup("breadcrumbs_focus", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = augroups.focus,
        callback = function()
            if not M.enabled then
                return
            end

            local bufnr = vim.api.nvim_get_current_buf()

            if attached_lsp_clients[bufnr] then
                return
            end

            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            if #clients > 0 then
                for _, client in ipairs(clients) do
                    if client.server_capabilities.documentSymbolProvider then
                        M.attach(client, bufnr)
                        break
                    end
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
        group = augroups.focus,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            cancel_debounce_timer(bufnr)

            if buffer_symbol_trees[bufnr] and not vim.api.nvim_buf_is_valid(bufnr) then
                buffer_symbol_trees[bufnr] = nil
                buffer_context_data[bufnr] = nil
                attached_lsp_clients[bufnr] = nil
                awaiting_lsp_response[bufnr] = nil
            end
        end,
    })
end

--- Setup autocmds to refresh breadcrumbs on window resize
local function setup_window_resize_autocmds()
    augroups.window_resize = vim.api.nvim_create_augroup("breadcrumbs_window_resize", { clear = true })

    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        group = augroups.window_resize,
        callback = function()
            if not M.enabled then
                return
            end

            vim.cmd.redrawstatus({ bang = true })
        end,
    })
end

--- Setup autocmds to refresh winbar when buffer changes
local function setup_winbar_refresh_autocmds()
    augroups.winbar_refresh = vim.api.nvim_create_augroup("breadcrumbs_winbar_refresh", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType", "BufWritePost" }, {
        group = augroups.winbar_refresh,
        callback = function(args)
            local buf = args.buf or vim.api.nvim_get_current_buf()
            local win = vim.api.nvim_get_current_win()
            attach_winbar(buf, win)
        end,
    })

    vim.api.nvim_create_autocmd({ "WinNew", "TabEnter" }, {
        group = augroups.winbar_refresh,
        callback = function()
            vim.schedule(function()
                local buf = vim.api.nvim_get_current_buf()
                local win = vim.api.nvim_get_current_win()
                attach_winbar(buf, win)
            end)
        end,
    })
end

--- Enable breadcrumbs
function M.enable()
    if M.enabled then
        return
    end
    M.enabled = true

    setup_lsp_auto_attach_autocmd()
    setup_buffer_focus_autocmds()
    setup_symbol_refresh_autocmds()
    setup_mode_change_autocmds()
    setup_window_resize_autocmds()
    setup_winbar_refresh_autocmds()

    -- Re-enable breadcrumbs on all visible windows/buffers
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_is_valid(buf) then
                local clients = vim.lsp.get_clients({ bufnr = buf })
                if #clients > 0 then
                    for _, client in ipairs(clients) do
                        if client.server_capabilities.documentSymbolProvider then
                            M.attach(client, buf)
                            break
                        end
                    end
                end
                attach_winbar(buf, win)
            end
        end
    end

    vim.schedule(function()
        vim.cmd("redrawstatus!")
    end)
end

--- Disable breadcrumbs
function M.disable()
    if not M.enabled then
        return
    end
    M.enabled = false

    -- Cancel all debounce timers
    for bufnr, _ in pairs(debounce_timers) do
        cancel_debounce_timer(bufnr)
    end

    if mode_cache_timer then
        mode_cache_timer:stop()
        mode_cache_timer:close()
        mode_cache_timer = nil
    end

    -- Clear winbar for all windows
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local current_winbar = vim.wo[win].winbar
            if current_winbar:match("breadcrumbs") then
                vim.wo[win].winbar = ""
            end
        end
    end

    -- Clear all autocmds
    for _, group_id in pairs(augroups) do
        if group_id then
            vim.api.nvim_clear_autocmds({ group = group_id })
        end
    end
    augroups = {}

    -- Clear all state
    attached_lsp_clients = {}
    buffer_symbol_trees = {}
    buffer_context_data = {}
    awaiting_lsp_response = {}
    current_cached_mode = nil

    vim.cmd("redrawstatus!")
end

--- Main setup function
function M.setup(opts)
    if opts then
        for k, v in pairs(opts) do
            if type(config[k]) == "table" and type(v) == "table" then
                for nk, nv in pairs(v) do
                    config[k][nk] = nv
                end
            else
                config[k] = v
            end
        end
    end

    if vim.fn.has("nvim-0.8") == 0 then
        vim.notify("breadcrumbs: Winbar is not supported in this Neovim version (requires 0.8+).", vim.log.levels.WARN)
        return
    end
end

-- Auto-setup and enable when the module is required
M.setup()
M.enable()

-- Snacks toggle integration
if Snacks and Snacks.toggle then
    Snacks.toggle({
        name = "Breadcrumbs",
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
    }):map("<leader>ub")
end

return M

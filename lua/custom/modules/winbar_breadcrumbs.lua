-- winbar_breadcrumbs.lua - Enhanced with content modification handling, truncation, and conditional display

local M = {}

-- Store client info per buffer (for the currently attached LSP)
local attached_lsp_clients = {}

-- Store processed symbols per buffer
local buffer_symbols = {}

-- Track pending requests to avoid duplicate requests
local pending_requests = {}

-- Track buffer versions to handle content modifications
local buffer_versions = {}

-- Configuration options (can be overridden by user in M.setup)
local config = {
    -- Placeholder for future general config options
    lsp = {
        auto_attach = true, -- Default to true
        preference = nil,
        focus_only = true, -- Only attach to currently focused buffer
    },
    -- New config options for handling content modifications
    symbol_request = {
        debounce_ms = 500, -- Debounce symbol requests by 500ms
        max_retries = 3, -- Maximum number of retries for failed requests
        retry_delay_ms = 200, -- Delay between retries
    },
    -- Updated truncation config options for winbar
    truncation = {
        enabled = true, -- Enable truncation
        separator = "  ", -- Separator between breadcrumb parts
        extends_symbol = "…", -- Symbol to show when truncated
        min_symbol_width = 1, -- Minimum width for each symbol when truncated
    },
    -- New: Enable/disable conditions for winbar
    bar = {
        ---@type boolean|fun(buf: integer, win: integer): boolean
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
            if filetype == "markdown" then
                return true
            end

            if filetype == "help" then
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

    -- Map LSP kind numbers to mini.icons LSP kind strings
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

--- Check if cursor position is within a symbol's range.
---@param cursor_pos table {line, character} - 1-indexed line, 0-indexed character
---@param range table LSP range with start/end line/character
---@return boolean
local function is_in_range(cursor_pos, range)
    local line = cursor_pos[1] - 1 -- Convert to 0-indexed for LSP comparison
    local char = cursor_pos[2]

    -- Check if position is within the range
    if line < range.start.line or line > range["end"].line then
        return false
    end

    if line == range.start.line and char < range.start.character then
        return false
    end

    if line == range["end"].line and char > range["end"].character then
        return false
    end

    return true
end

--- Find symbols that contain the current cursor position.
---@param bufnr number Buffer number
---@return table|nil Array of symbols from outermost to innermost
local function find_symbols_at_cursor(bufnr)
    local symbols = buffer_symbols[bufnr]
    if not symbols then
        return nil
    end

    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local containing_symbols = {}

    -- Find all symbols that contain the cursor position
    for _, symbol in ipairs(symbols) do
        if is_in_range(cursor_pos, symbol.range) then
            table.insert(containing_symbols, symbol)
        end
    end

    -- Sort by range size (larger ranges = more general/outer symbols)
    -- This ensures outermost to innermost ordering
    table.sort(containing_symbols, function(a, b)
        -- Calculate range size more accurately
        local a_lines = a.range["end"].line - a.range.start.line
        local a_chars = a.range["end"].character - a.range.start.character
        local b_lines = b.range["end"].line - b.range.start.line
        local b_chars = b.range["end"].character - b.range.start.character

        -- Primary sort by line span, secondary by character span
        if a_lines ~= b_lines then
            return a_lines > b_lines -- More lines = larger/outer symbol
        end

        return a_chars > b_chars -- More characters = larger/outer symbol
    end)

    return containing_symbols
end

--- Build breadcrumb parts with icons and highlights
---@param filepath string The file path
---@param symbols table|nil The symbols at cursor
---@return table Array of breadcrumb parts {text, highlight, icon, icon_highlight}
local function build_breadcrumb_parts(filepath, symbols)
    local parts = {}

    if filepath == "" then
        return parts -- Return empty parts array to show nothing
    end

    local sep = package.config:sub(1, 1) -- path separator
    local ok, mini_icons = pcall(require, "mini.icons")

    -- Normalize full path
    filepath = vim.fs.normalize(filepath)

    -- Get current working directory
    local cwd = vim.fn.getcwd()
    cwd = vim.fs.normalize(cwd)

    local relpath

    -- Check if the file is under the current working directory
    if filepath:sub(1, #cwd) == cwd then
        -- File is under CWD, make it relative to CWD
        relpath = filepath:sub(#cwd + 1)
        -- Remove leading separator if present
        if relpath:sub(1, 1) == sep then
            relpath = relpath:sub(2)
        end
        -- If relpath is empty (file is exactly at CWD), use filename
        if relpath == "" then
            relpath = vim.fn.fnamemodify(filepath, ":t")
        end
    else
        -- File is outside CWD, try to make it relative to HOME for better display
        local home = vim.env.HOME or vim.fn.expand("$HOME")
        home = vim.fs.normalize(home)

        if filepath:sub(1, #home) == home then
            relpath = filepath:sub(#home + 1)
            -- Remove leading separator if present
            if relpath:sub(1, 1) == sep then
                relpath = relpath:sub(2)
            end
        else
            -- File is outside both CWD and HOME, use full path
            relpath = filepath
            -- Remove leading separator if present for full paths
            if relpath:sub(1, 1) == sep then
                relpath = relpath:sub(2)
            end
        end
    end

    -- Split the relative path into parts
    local path_parts = vim.split(relpath, sep, { plain = true })

    -- Filter out empty parts to avoid phantom directory icons
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

    -- Add symbols
    if symbols and #symbols > 0 then
        for _, symbol in ipairs(symbols) do
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

--- Apply truncation logic to breadcrumb parts following dropbar approach
---@param parts table Array of breadcrumb parts with {text, highlight, icon, icon_highlight} structure
---@param available_width number Available width for the breadcrumb
---@return table Truncated breadcrumb parts
local function apply_truncation(parts, available_width)
    if not config.truncation.enabled or #parts == 0 then
        return parts
    end

    local separator = config.truncation.separator
    local extends_symbol = config.truncation.extends_symbol
    local min_width = config.truncation.min_symbol_width

    -- Helper function to get display width of a part (including icon if present)
    local function get_part_display_width(part)
        local width = vim.fn.strdisplaywidth(part.text or "")
        if part.icon then
            width = width + vim.fn.strdisplaywidth(part.icon) + 1 -- +1 for space between icon and text
        end
        return width
    end

    -- Helper function to calculate total width of parts
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

    -- Make a working copy of parts
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

    -- Return early if it already fits
    if delta <= 0 then
        -- Remove the min_width field from return value
        for _, part in ipairs(truncated_parts) do
            part.min_width = nil
        end
        return truncated_parts
    end

    -- Phase 1: Truncate individual parts by shortening their text (keep icons)
    for _, part in ipairs(truncated_parts) do
        if delta <= 0 then
            break
        end

        local text_len = vim.fn.strdisplaywidth(part.text)
        local extends_width = vim.fn.strdisplaywidth(extends_symbol)
        local min_len = extends_width + part.min_width

        if text_len > min_len then
            -- Calculate how much we can truncate from this part's text
            local max_reduction = text_len - min_len
            local reduction = math.min(delta, max_reduction)

            -- Truncate the text part only
            local new_len = text_len - reduction
            local truncated_chars = math.max(part.min_width, new_len - extends_width)
            part.text = vim.fn.strcharpart(part.text, 0, truncated_chars) .. extends_symbol

            -- Update delta
            delta = delta - reduction
        end
    end

    -- Phase 2: If still too long, remove parts from the beginning
    if delta > 0 and #truncated_parts > 1 then
        local sep_width = vim.fn.strdisplaywidth(separator)

        -- Create extends part to replace removed parts
        local extends_part = {
            text = extends_symbol,
            highlight = nil,
            icon = nil,
            icon_highlight = nil,
        }

        local first_part = truncated_parts[1]
        local first_width = get_part_display_width(first_part)
        local extends_part_width = get_part_display_width(extends_part)

        -- Check if replacing first part with extends helps
        local width_diff = extends_part_width - first_width

        if width_diff < 0 then -- extends is smaller than first part
            -- Replace first part with extends
            truncated_parts[1] = extends_part
            delta = delta + width_diff

            -- Keep removing parts from position 2 until we fit
            while delta > 0 and #truncated_parts > 1 do
                local part_to_remove = truncated_parts[2]
                local part_width = get_part_display_width(part_to_remove)

                table.remove(truncated_parts, 2)
                delta = delta - part_width - sep_width
            end
        end
    end

    -- Phase 3: Final fallback - if still doesn't fit, keep only the last part
    if delta > 0 and #truncated_parts > 1 then
        local last_part = truncated_parts[#truncated_parts]
        local last_width = get_part_display_width(last_part)
        local extends_width = vim.fn.strdisplaywidth(extends_symbol)

        -- If last part + extends symbol fits, use that
        if last_width + extends_width <= available_width then
            truncated_parts = {
                { text = extends_symbol, highlight = nil, icon = nil, icon_highlight = nil },
                last_part,
            }
        else
            -- Otherwise, just use extends symbol
            truncated_parts = {
                { text = extends_symbol, highlight = nil, icon = nil, icon_highlight = nil },
            }
        end
    end

    -- Clean up: remove min_width field from return value
    for _, part in ipairs(truncated_parts) do
        part.min_width = nil
    end

    return truncated_parts
end

--- Convert breadcrumb parts to display string with highlights
---@param parts table Array of breadcrumb parts with {text, highlight, icon, icon_highlight}
---@return string Display string with highlight codes
local function parts_to_display_string(parts)
    if #parts == 0 then
        return ""
    end

    local separator = config.truncation.separator
    local result_parts = {}

    -- Add left padding
    table.insert(result_parts, " ")

    -- Add parts with separators
    for i, part in ipairs(parts) do
        -- Add icon with its highlight if present (keep icon highlights unchanged)
        if part.icon and part.icon_highlight then
            table.insert(result_parts, "%#" .. part.icon_highlight .. "#" .. part.icon .. "%*")
            table.insert(result_parts, " ") -- Space between icon and text
        elseif part.icon then
            table.insert(result_parts, part.icon .. " ")
        end

        -- Add text with WinBar highlight (force WinBar for all text)
        table.insert(result_parts, "%#WinBar#" .. part.text .. "%*")

        -- Add separator between parts with WinBar highlight
        if i < #parts then
            table.insert(result_parts, "%#WinBar#" .. separator .. "%*")
        end
    end

    -- Add right padding
    table.insert(result_parts, " ")

    return table.concat(result_parts, "")
end

--- Attach winbar to window if conditions are met
---@param buf integer buffer number
---@param win integer window number
local function attach_winbar(buf, win)
    buf = buf or vim.api.nvim_get_current_buf()
    win = win or vim.api.nvim_get_current_win()

    if not vim.api.nvim_win_is_valid(win) then
        return
    end

    local should_enable
    if type(config.bar.enable) == "function" then
        should_enable = config.bar.enable(buf, win)
    else
        should_enable = config.bar.enable --[[@as boolean]]
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

-- Function to get the current filename and breadcrumb display
function M.get_filename_display()
    local filepath = vim.api.nvim_buf_get_name(0)
    local bufnr = vim.api.nvim_get_current_buf()
    local symbols = find_symbols_at_cursor(bufnr)

    -- Build breadcrumb parts
    local parts = build_breadcrumb_parts(filepath, symbols)

    -- Get available width (use current window width)
    local available_width = vim.api.nvim_win_get_width(0) - 2 -- Small buffer for safety

    -- Apply truncation if enabled
    if config.truncation.enabled then
        parts = apply_truncation(parts, available_width)
    end

    -- Convert to display string
    return parts_to_display_string(parts)
end

--- Process LSP document symbols into a flat list with hierarchy info.
---@param symbols table The raw LSP symbols
---@return table Processed symbols with position info
local function process_symbols(symbols)
    local processed = {}

    local function process_symbol(symbol, parent_names)
        parent_names = parent_names or {}

        -- Create a processed symbol entry
        local processed_symbol = {
            name = symbol.name,
            kind = symbol.kind,
            parent_names = vim.deepcopy(parent_names),
            range = symbol.range or symbol.location.range,
            selectionRange = symbol.selectionRange or symbol.range or symbol.location.range,
        }

        table.insert(processed, processed_symbol)

        -- Process children if they exist
        if symbol.children then
            local new_parent_names = vim.deepcopy(parent_names)
            table.insert(new_parent_names, symbol.name)

            for _, child in ipairs(symbol.children) do
                process_symbol(child, new_parent_names)
            end
        end
    end

    -- Process all top-level symbols
    for _, symbol in ipairs(symbols) do
        process_symbol(symbol, {})
    end

    return processed
end

--- Get the current buffer version (changeset number)
---@param bufnr number Buffer number
---@return number Buffer version
local function get_buffer_version(bufnr)
    return vim.api.nvim_buf_get_changedtick(bufnr)
end

--- Check if the error is a "Content modified" error
---@param err table Error object
---@return boolean True if this is a content modified error
local function is_content_modified_error(err)
    return err and err.code == -32801 and err.message == "Content modified."
end

--- Cancel debounce timer for buffer
---@param bufnr number Buffer number
local function cancel_debounce_timer(bufnr)
    if debounce_timers[bufnr] then
        debounce_timers[bufnr]:stop()
        debounce_timers[bufnr]:close()
        debounce_timers[bufnr] = nil
    end
end

--- Debounced symbol request to avoid rapid successive requests
---@param bufnr number Buffer number
---@param client table LSP client
---@param delay_ms number|nil Delay in milliseconds (optional)
local function debounced_request_symbols(bufnr, client, delay_ms)
    delay_ms = delay_ms or config.symbol_request.debounce_ms

    -- Cancel any existing timer for this buffer
    cancel_debounce_timer(bufnr)

    -- Create new timer
    debounce_timers[bufnr] = vim.defer_fn(function()
        debounce_timers[bufnr] = nil
        M.request_symbols(bufnr, client)
    end, delay_ms)
end

--- Make request to lsp server for document symbols with retry logic.
---@param bufnr number The buffer number
---@param client table The LSP client object
---@param retry_count number|nil Current retry attempt (default: 0)
function M.request_symbols(bufnr, client, retry_count)
    retry_count = retry_count or 0

    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end

    -- Check if there's already a pending request for this buffer
    if pending_requests[bufnr] then
        return
    end

    -- Store the current buffer version
    local current_version = get_buffer_version(bufnr)
    buffer_versions[bufnr] = current_version

    local textDocument_argument = vim.lsp.util.make_text_document_params(bufnr)

    local function make_lsp_request(method, params, callback)
        if vim.fn.has("nvim-0.11") == 1 then
            client:request(method, params, callback, bufnr)
        else
            client.request(method, params, callback, bufnr)
        end
    end

    -- Mark request as pending
    pending_requests[bufnr] = true

    make_lsp_request("textDocument/documentSymbol", { textDocument = textDocument_argument }, function(err, symbols, _)
        -- Clear pending request flag
        pending_requests[bufnr] = nil

        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        -- Check if buffer was modified during the request
        local new_version = get_buffer_version(bufnr)
        if buffer_versions[bufnr] and new_version ~= buffer_versions[bufnr] then
            -- Buffer was modified, request new symbols with debounce
            debounced_request_symbols(bufnr, client)
            return
        end

        if err then
            if is_content_modified_error(err) then
                -- Handle content modified error with retry logic
                if retry_count < config.symbol_request.max_retries then
                    vim.defer_fn(function()
                        M.request_symbols(bufnr, client, retry_count + 1)
                    end, config.symbol_request.retry_delay_ms)
                else
                    -- Max retries reached, use debounced request instead
                    debounced_request_symbols(bufnr, client)
                end
            end
            -- Removed error notification for production use
        elseif symbols then
            -- Process and store the symbols
            local processed_symbols = process_symbols(symbols)
            buffer_symbols[bufnr] = processed_symbols
        end
        -- Removed "no symbols" notification for production use
    end)
end

--- Attach LSP client to the buffer and request document symbols.
---@param client table The LSP client object
---@param bufnr number The buffer number
function M.attach(client, bufnr)
    if not client.server_capabilities.documentSymbolProvider then
        return
    end

    -- For now, always attach (we'll add preference logic in a later step)
    vim.b[bufnr].breadcrumbs_client_id = client.id
    vim.b[bufnr].breadcrumbs_client_name = client.name
    attached_lsp_clients[bufnr] = client

    -- Make the initial request for document symbols with debounce
    debounced_request_symbols(bufnr, client, 100) -- Shorter initial delay
end

--- Sets up the LspAttach autocommand for automatic breadcrumbs attachment.
local function setup_lsp_auto_attach_autocmd()
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            -- Add this check to ensure 'client' is not nil
            if client then
                -- Only auto-attach if the global config allows it
                if config.lsp.auto_attach then
                    -- Check if we should only attach to focused buffer
                    if config.lsp.focus_only then
                        local current_buf = vim.api.nvim_get_current_buf()
                        if args.buf == current_buf then
                            M.attach(client, args.buf)
                        end
                    else
                        M.attach(client, args.buf)
                    end
                end
            end
        end,
    })
end

--- Setup autocmds to refresh symbols when buffer content changes and cursor moves
local function setup_symbol_refresh_autocmds()
    local augroup = vim.api.nvim_create_augroup("breadcrumbs_symbol_refresh", { clear = true })

    -- Refresh symbols when buffer is modified
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = augroup,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            local client = attached_lsp_clients[bufnr]

            if client and client.server_capabilities.documentSymbolProvider then
                -- Use debounced request to avoid too many requests
                debounced_request_symbols(bufnr, client)
            end
        end,
    })

    -- Refresh breadcrumbs display when cursor moves (no need to refetch symbols)
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = augroup,
        callback = function()
            vim.schedule(function()
                vim.cmd.redrawstatus()
            end)
        end,
    })
end

--- Handle buffer focus changes to attach/detach breadcrumbs
local function setup_buffer_focus_autocmds()
    if not config.lsp.focus_only then
        return
    end

    -- Create augroup for focus-related autocmds
    local augroup = vim.api.nvim_create_augroup("breadcrumbs_focus", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = augroup,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()

            -- Check if this buffer already has breadcrumbs attached
            if attached_lsp_clients[bufnr] then
                return
            end

            -- Check if there's an LSP client available for this buffer
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            if #clients > 0 then
                -- Attach to the first available client that supports document symbols
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
        group = augroup,
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()

            -- Cancel any pending debounce timers
            cancel_debounce_timer(bufnr)

            -- Clean up symbols for buffers that are no longer focused
            -- This helps with memory management
            if buffer_symbols[bufnr] and not vim.api.nvim_buf_is_valid(bufnr) then
                buffer_symbols[bufnr] = nil
                attached_lsp_clients[bufnr] = nil
                pending_requests[bufnr] = nil
                buffer_versions[bufnr] = nil
            end
        end,
    })
end

--- Setup autocmds to refresh breadcrumbs on window resize
local function setup_window_resize_autocmds()
    local augroup = vim.api.nvim_create_augroup("breadcrumbs_window_resize", { clear = true })

    -- Refresh breadcrumbs when window is resized
    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        group = augroup,
        callback = function()
            -- Force redraw of winbar to apply truncation with new window size
            vim.cmd.redrawstatus({ bang = true })
        end,
    })
end

--- Setup autocmds to refresh winbar when buffer changes
local function setup_winbar_refresh_autocmds()
    local augroup = vim.api.nvim_create_augroup("breadcrumbs_winbar_refresh", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType", "BufWritePost" }, {
        group = augroup,
        callback = function(args)
            local buf = args.buf or vim.api.nvim_get_current_buf()
            local win = vim.api.nvim_get_current_win()
            attach_winbar(buf, win)
        end,
    })

    vim.api.nvim_create_autocmd({ "WinNew", "TabEnter" }, {
        group = augroup,
        callback = function()
            vim.schedule(function()
                local buf = vim.api.nvim_get_current_buf()
                local win = vim.api.nvim_get_current_win()
                attach_winbar(buf, win)
            end)
        end,
    })
end

--- Main setup function for the breadcrumbs module.
--- This can be called explicitly with options, or implicitly on require.
---@param opts table|nil
function M.setup(opts)
    -- Merge provided options with default config
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

    -- Check if winbar is supported (Neovim 0.8+)
    if vim.fn.has("nvim-0.8") == 0 then
        vim.notify("breadcrumbs: Winbar is not supported in this Neovim version (requires 0.8+).", vim.log.levels.WARN)
        return
    end

    -- Setup the LSP auto-attach autocmd
    setup_lsp_auto_attach_autocmd()

    -- Setup buffer focus autocmds if focus_only is enabled
    setup_buffer_focus_autocmds()

    -- Setup symbol refresh autocmds
    setup_symbol_refresh_autocmds()

    -- Setup window resize autocmds for truncation
    setup_window_resize_autocmds()

    -- Setup winbar refresh autocmds for conditional display
    setup_winbar_refresh_autocmds()

    -- Initial setup - attach winbar to current window if conditions are met
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    attach_winbar(buf, win)
end

-- Function to disable breadcrumbs
function M.disable()
    -- Cancel all debounce timers
    for bufnr, _ in pairs(debounce_timers) do
        cancel_debounce_timer(bufnr)
    end

    -- Clear winbar for all windows
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].winbar = ""
        end
    end

    -- Clear specific autocmds created by breadcrumbs
    vim.api.nvim_clear_autocmds({ group = "breadcrumbs_lsp_autocmds" })
    vim.api.nvim_clear_autocmds({ group = "breadcrumbs_focus" })
    vim.api.nvim_clear_autocmds({ group = "breadcrumbs_symbol_refresh" })
    vim.api.nvim_clear_autocmds({ group = "breadcrumbs_window_resize" })
    vim.api.nvim_clear_autocmds({ group = "breadcrumbs_winbar_refresh" })
end

-- Auto-setup when the module is required
M.setup()

return M

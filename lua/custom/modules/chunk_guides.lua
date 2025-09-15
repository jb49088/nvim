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
    max_file_size = 1024 * 1024, -- 1MB
    -- Scope configuration
    scope = {
        min_size = 2,
        max_size = nil,
        cursor = true,
        edge = true,
        siblings = false,
        filter = function(buf)
            return vim.bo[buf].buftype == "" and vim.b[buf].snacks_scope ~= false and vim.g.snacks_scope ~= false
        end,
        debounce = 30,
        treesitter = {
            enabled = true,
            injections = true,
            blocks = {
                enabled = false,
                "function_declaration",
                "function_definition",
                "method_declaration",
                "method_definition",
                "class_declaration",
                "class_definition",
                "do_statement",
                "while_statement",
                "repeat_statement",
                "if_statement",
                "for_statement",
            },
            field_blocks = {
                "local_declaration",
            },
        },
    },
}

-- Module state
local M = {
    ns_id = api.nvim_create_namespace("custom_chunk_guides"),
    enabled = true,
    disabled_buffers = {},
    current_scope = nil,
    scope_listener = nil,
    last_regular_win = nil,
}

-- Scope logic
local defaults = {
    min_size = 2,
    max_size = nil,
    cursor = true,
    edge = true,
    siblings = false,
    filter = function(buf)
        return vim.bo[buf].buftype == "" and vim.b[buf].snacks_scope ~= false and vim.g.snacks_scope ~= false
    end,
    debounce = 30,
    treesitter = {
        enabled = true,
        injections = true,
        blocks = {
            enabled = false,
            "function_declaration",
            "function_definition",
            "method_declaration",
            "method_definition",
            "class_declaration",
            "class_definition",
            "do_statement",
            "while_statement",
            "repeat_statement",
            "if_statement",
            "for_statement",
        },
        field_blocks = {
            "local_declaration",
        },
    },
}

---@class snacks.scope.Scope
local Scope = {}
Scope.__index = Scope

function Scope:new(scope, opts)
    local ret = setmetatable(scope, { __index = self, __eq = self.__eq, __tostring = self.__tostring })
    ret.opts = opts
    return ret
end

function Scope:__eq(other)
    return other
        and self.buf == other.buf
        and self.from == other.from
        and self.to == other.to
        and self.indent == other.indent
end

function Scope.get_indent(line)
    local ret = vim.fn.indent(line)
    return ret == -1 and nil or ret, line
end

function Scope:with(opts)
    opts = vim.tbl_extend("keep", opts, self)
    return setmetatable(opts, getmetatable(self))
end

function Scope:size()
    return self.to - self.from + 1
end

function Scope:size_with_edge()
    return self:with_edge():size()
end

function Scope:expand(line)
    local ret = self
    while ret do
        if line >= ret.from and line <= ret.to then
            return ret
        end
        ret = ret:parent()
    end
end

function Scope:__tostring()
    local meta = getmetatable(self)
    return ("%s(buf=%d, from=%d, to=%d, indent=%d)"):format(
        rawequal(meta, TSScope) and "TSScope" or rawequal(meta, IndentScope) and "IndentScope" or "Scope",
        self.buf or -1,
        self.from or -1,
        self.to or -1,
        self.indent or 0
    )
end

-- IndentScope class
---@class IndentScope : snacks.scope.Scope
local IndentScope = setmetatable({}, Scope)
IndentScope.__index = IndentScope

function IndentScope._expand(line, indent, up)
    local next = up and vim.fn.prevnonblank or vim.fn.nextnonblank
    while line do
        local i, l = IndentScope.get_indent(next(line + (up and -1 or 1)))
        if (i or 0) == 0 or i < indent or l == 0 then
            return line
        end
        line = l
    end
    return line
end

function IndentScope:inner()
    local from, to, indent = nil, nil, math.huge
    for l = self.from, self.to do
        local i, il = IndentScope.get_indent(vim.fn.nextnonblank(l))
        if il == l then
            if i > self.indent then
                from = from or l
                to = l
                indent = math.min(indent, i)
            end
        end
    end
    return from and to and self:with({ from = from, to = to, indent = indent }) or self
end

function IndentScope:with_edge()
    if self.indent == 0 then
        return self
    end
    local before_i, before_l = Scope.get_indent(vim.fn.prevnonblank(self.from - 1))
    local after_i, after_l = Scope.get_indent(vim.fn.nextnonblank(self.to + 1))
    local indent = math.min(math.max(before_i or self.indent, after_i or self.indent), self.indent)
    local from = before_i and before_i == indent and before_l or self.from
    local to = after_i and after_i == indent and after_l or self.to
    if from == 0 or to == 0 or indent < 0 then
        return self
    end
    return self:with({ from = from, to = to, indent = indent })
end

-- Helper function to check if cursor is actually inside an indented block
local function cursor_inside_block(cursor_line, scope_from, scope_to)
    -- Cursor must be between scope boundaries (inclusive)
    return cursor_line >= scope_from and cursor_line <= scope_to
end

-- Helper function to find the closest non-blank line with content
local function find_closest_content_line(line)
    local prev_line = vim.fn.prevnonblank(line)
    local next_line = vim.fn.nextnonblank(line)

    if prev_line == 0 and next_line == 0 then
        return nil
    elseif prev_line == 0 then
        return next_line
    elseif next_line == 0 then
        return prev_line
    else
        -- Return the closer one
        local prev_dist = line - prev_line
        local next_dist = next_line - line
        return prev_dist <= next_dist and prev_line or next_line
    end
end

function IndentScope:find(opts)
    local indent, line = Scope.get_indent(opts.pos[1])
    local cursor_line = opts.pos[1]

    -- If cursor is on a blank line, we need to be more careful about scope detection
    if vim.fn.prevnonblank(line) ~= line then
        local closest_line = find_closest_content_line(line)
        if not closest_line then
            return nil -- No content in buffer
        end

        -- Get the scope for the closest content line
        local content_indent, content_line = Scope.get_indent(closest_line)
        if content_line == 0 then
            return nil
        end

        -- Check if we can find a scope at the content line
        local temp_scope = IndentScope:find(vim.tbl_extend("keep", { pos = { content_line, 0 } }, opts))
        if temp_scope then
            -- Only return this scope if the cursor is actually within its boundaries
            if cursor_inside_block(cursor_line, temp_scope.from, temp_scope.to) then
                return temp_scope
            else
                -- Cursor is outside the detected scope, return nil
                return nil
            end
        end

        return nil
    end

    local prev_i, prev_l = Scope.get_indent(vim.fn.prevnonblank(line - 1))
    local next_i, next_l = Scope.get_indent(vim.fn.nextnonblank(line + 1))

    if line == 0 then
        return
    end

    if prev_i <= indent and next_i > indent then
        line = next_l
        indent = next_i
    elseif next_i <= indent and prev_i > indent then
        line = prev_l
        indent = prev_i
    elseif next_i > indent and prev_i > indent then
        line = next_l
        indent = next_i
    end

    if opts.cursor then
        indent = math.min(indent, vim.fn.virtcol(opts.pos) + 1)
    end

    local scope = IndentScope:new({
        buf = opts.buf,
        from = IndentScope._expand(line, indent, true),
        to = IndentScope._expand(line, indent, false),
        indent = indent,
    }, opts)

    -- Final check: ensure cursor is actually within the detected scope
    if scope and not cursor_inside_block(cursor_line, scope.from, scope.to) then
        return nil
    end

    return scope
end

function IndentScope:parent()
    for i = self.indent - 1, 1, -1 do
        local u, d = IndentScope._expand(self.from, i, true), IndentScope._expand(self.to, i, false)
        if u ~= self.from or d ~= self.to then
            return self:with({ from = u, to = d, indent = i })
        end
    end
end

-- TSScope class
---@class TSScope : snacks.scope.Scope
local TSScope = setmetatable({}, Scope)
TSScope.__index = TSScope

function TSScope:fill()
    local n = self.node
    local u, _, d = n:range()
    while n do
        local uu, _, dd = n:range()
        if uu == u and dd == d and not self:is_field(n) then
            self.node = n
        else
            break
        end
        n = n:parent()
    end
end

function TSScope:fix()
    self:fill()
    self.from, _, self.to = self.node:range()
    self.from, self.to = self.from + 1, self.to + 1
    self.indent = math.min(vim.fn.indent(self.from), vim.fn.indent(self.to))
    return self
end

function TSScope:is_field(node)
    node = node or self.node
    local parent = node:parent()
    parent = parent ~= node:tree():root() and parent or nil
    if not parent then
        return false
    end
    for child, field in parent:iter_children() do
        if child == node then
            return not (field == nil or vim.tbl_contains(self.opts.treesitter.field_blocks, field))
        end
    end
    error("node not found in parent")
end

function TSScope:with_edge()
    local ret = self
    while ret do
        if ret:size() >= 1 and not ret:is_field() then
            return ret
        end
        ret = ret:parent()
    end
    return self
end

function TSScope:root()
    if type(self.opts.treesitter.blocks) ~= "table" or not self.opts.treesitter.blocks.enabled then
        return self:fix()
    end
    local root = self.node
    while root do
        if vim.tbl_contains(self.opts.treesitter.blocks, root:type()) then
            return self:with({ node = root })
        end
        root = root:parent()
    end
    return self:fix()
end

function TSScope:with(opts)
    local ret = Scope.with(self, opts)
    return ret:fix()
end

function TSScope:parser(opts)
    local lang = vim.bo[opts.buf].filetype
    local has_parser, parser = pcall(vim.treesitter.get_parser, opts.buf, lang, { error = false })
    return has_parser and parser or nil
end

-- Utility function for treesitter parsing
local function parse_ts(parser, injections, cb)
    if not parser then
        return cb()
    end

    local function do_parse()
        if injections then
            parser:parse()
        end
        cb()
    end

    if parser:is_valid() then
        do_parse()
    else
        vim.schedule(do_parse)
    end
end

function TSScope:init(cb, opts)
    local parser = self:parser(opts)
    if not parser then
        return cb()
    end
    parse_ts(parser, opts.treesitter.injections, cb)
end

function TSScope:find(opts)
    local lang = vim.treesitter.language.get_lang(vim.bo[opts.buf].filetype)
    local cursor_line = opts.pos[1]
    local line = vim.fn.nextnonblank(cursor_line)
    line = line == 0 and vim.fn.prevnonblank(cursor_line) or line

    -- If we're on a blank line, check if we're actually inside a treesitter scope
    if vim.fn.prevnonblank(cursor_line) ~= cursor_line then
        local closest_line = find_closest_content_line(cursor_line)
        if not closest_line then
            return nil
        end

        -- Try to find scope at closest content line
        local temp_scope = TSScope:find(vim.tbl_extend("keep", { pos = { closest_line, 0 } }, opts))
        if temp_scope then
            -- Only return if cursor is within the scope boundaries
            if cursor_inside_block(cursor_line, temp_scope.from, temp_scope.to) then
                return temp_scope
            else
                return nil
            end
        end
        return nil
    end

    local pos = {
        math.max(line - 1, 0),
        (vim.fn.getline(line):find("%S") or 1) - 1,
    }

    local node = vim.treesitter.get_node({
        pos = pos,
        bufnr = opts.buf,
        lang = lang,
        ignore_injections = not opts.treesitter.injections,
    })

    if not node then
        return
    end

    if opts.cursor then
        local n = node
        local virtcol = vim.fn.virtcol(opts.pos)
        while n and n ~= n:tree():root() do
            local r, c = n:range()
            local virtcol_n = vim.fn.virtcol({ r + 1, c })
            if virtcol_n > virtcol then
                node, n = n, n:parent()
            else
                break
            end
        end
    end

    local scope = TSScope:new({ buf = opts.buf, node = node }, opts):root()

    -- Final check: ensure cursor is actually within the detected scope
    if scope and not cursor_inside_block(cursor_line, scope.from, scope.to) then
        return nil
    end

    return scope
end

function TSScope:parent()
    local parent = self.node:parent()
    return parent and parent ~= self.node:tree():root() and self:with({ node = parent }):root() or nil
end

function TSScope:inner()
    local from, to, indent = nil, nil, math.huge
    for l = self.from + 1, self.to do
        if l == vim.fn.nextnonblank(l) then
            local col = (vim.fn.getline(l):find("%S") or 1) - 1
            local node = vim.treesitter.get_node({ pos = { l - 1, col }, bufnr = self.buf })
            local s = TSScope:new({ buf = self.buf, node = node }, self.opts):fix()
            if s and s.from > self.from and s.to <= self.to then
                from = from or l
                to = l
                indent = math.min(indent, vim.fn.indent(l))
            end
        end
    end
    return from and to and IndentScope:new({ from = from, to = to, indent = indent }, self.opts) or self
end

-- Main scope detection function
local function get_scope(cb, opts)
    opts = vim.tbl_extend("keep", opts or {}, config.scope)
    opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf
    if not opts.pos then
        assert(opts.buf == vim.api.nvim_win_get_buf(0), "missing pos")
        opts.pos = vim.api.nvim_win_get_cursor(0)
    end

    -- Run in the context of the buffer if not current
    if vim.api.nvim_get_current_buf() ~= opts.buf then
        vim.api.nvim_buf_call(opts.buf, function()
            get_scope(cb, opts)
        end)
        return
    end

    local function get_lang(bufnr)
        local ft = vim.bo[bufnr].filetype
        local has_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
        return has_lang and lang or nil
    end

    local Class = (opts.treesitter.enabled and get_lang(opts.buf)) and TSScope or IndentScope
    if rawequal(Class, TSScope) and opts.parse ~= false then
        TSScope:init(function()
            opts.parse = false
            get_scope(cb, opts)
        end, opts)
        return
    end

    local scope = Class:find(opts)

    -- Fallback to indent based detection
    if not scope and rawequal(Class, TSScope) then
        Class = IndentScope
        scope = Class:find(opts)
    end

    -- When end_pos is provided, get its scope and expand the current scope
    if scope and opts.end_pos and not vim.deep_equal(opts.pos, opts.end_pos) then
        local end_scope = Class:find(vim.tbl_extend("keep", { pos = opts.end_pos }, opts))
        if end_scope and end_scope.from < scope.from then
            scope = scope:expand(end_scope.from) or scope
        end
        if end_scope and end_scope.to > scope.to then
            scope = scope:expand(end_scope.to) or scope
        end
    end

    local min_size = opts.min_size or 2
    local max_size = opts.max_size or min_size

    -- Only expand if we actually have a scope and cursor is within it
    if scope then
        local cursor_line = opts.pos[1]
        local s = scope
        while s do
            local size_check = opts.edge and s:size_with_edge() or s:size()
            local scope_size_check = opts.edge and scope:size_with_edge() or scope:size()

            if scope_size_check >= min_size and size_check > max_size then
                break
            end

            -- Make sure we don't expand beyond reasonable bounds when cursor is not in parent
            local parent = s:parent()
            if parent and not cursor_inside_block(cursor_line, parent.from, parent.to) then
                break
            end

            scope, s = s, parent
        end
        -- Expand with edge
        if opts.edge then
            scope = scope:with_edge()
        end
    end

    -- Expand single line blocks with single line siblings
    if opts.siblings and scope and scope:size() == 1 then
        local cursor_line = opts.pos[1]
        while scope and scope:size() < min_size do
            local prev, next = vim.fn.prevnonblank(scope.from - 1), vim.fn.nextnonblank(scope.to + 1)
            local prev_dist, next_dist = math.abs(cursor_line - prev), math.abs(cursor_line - next)
            local prev_s = prev > 0 and Class:find(vim.tbl_extend("keep", { pos = { prev, 0 } }, opts))
            local next_s = next > 0 and Class:find(vim.tbl_extend("keep", { pos = { next, 0 } }, opts))
            prev_s = prev_s and prev_s:size() == 1 and prev_s
            next_s = next_s and next_s:size() == 1 and next_s
            local s = prev_dist < next_dist and prev_s or next_s or prev_s
            if s and (s.from < scope.from or s.to > scope.to) then
                local new_scope =
                    Scope.with(scope, { from = math.min(scope.from, s.from), to = math.max(scope.to, s.to) })
                -- Only expand if cursor is still within the new scope
                if cursor_inside_block(cursor_line, new_scope.from, new_scope.to) then
                    scope = new_scope
                else
                    break
                end
            else
                break
            end
        end
    end

    cb(scope)
end

-- Scope listener
local Listener = {}
local id = 0

function Listener.new(cb, opts)
    local self = setmetatable({}, { __index = Listener })
    self.cb = cb
    self.dirty = {}
    self.timer = assert((vim.uv or vim.loop).new_timer())
    self.enabled = false
    self.opts = vim.tbl_extend("keep", opts or {}, defaults)
    id = id + 1
    self.id = id
    self.active = {}
    return self
end

function Listener:check(win)
    local buf = vim.api.nvim_win_get_buf(win)
    if not self.opts.filter(buf) then
        if self.active[win] then
            local prev = self.active[win]
            self.active[win] = nil
            self.cb(win, buf, nil, prev)
        end
        return
    end

    get_scope(
        function(scope)
            local prev = self.active[win]
            if prev == scope then
                return -- no change
            end
            self.active[win] = scope
            self.cb(win, buf, scope, prev)
        end,
        vim.tbl_extend("keep", {
            buf = buf,
            pos = vim.api.nvim_win_get_cursor(win),
        }, self.opts)
    )
end

function Listener:get(win)
    local scope = self.active[win]
    return scope and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == scope.buf and scope or nil
end

function Listener:clean()
    for win in pairs(self.active) do
        self.active[win] = self:get(win)
    end
end

function Listener:update(wins, opts)
    wins = type(wins) == "number" and { wins } or wins or vim.api.nvim_list_wins()
    for _, b in ipairs(wins) do
        self.dirty[b] = true
    end
    local function update()
        self:_update()
    end
    if opts and opts.now then
        update()
    end
    self.timer:start(self.opts.debounce, 0, vim.schedule_wrap(update))
end

function Listener:_update()
    for win in pairs(self.dirty) do
        if vim.api.nvim_win_is_valid(win) then
            self:check(win)
        end
    end
    self.dirty = {}
end

function Listener:enable()
    assert(not self.enabled, "already enabled")
    self.enabled = true
    self.augroup = vim.api.nvim_create_augroup("snacks_scope_" .. self.id, { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = self.augroup,
        callback = function(ev)
            for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
                self:update(win)
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete", "BufWipeout" }, {
        group = self.augroup,
        callback = function()
            self:clean()
        end,
    })
    self:update(nil, { now = true })
end

function Listener:disable()
    assert(self.enabled, "already disabled")
    self.enabled = false
    vim.api.nvim_del_augroup_by_id(self.augroup)
    self.timer:stop()
    self.active = {}
    self.dirty = {}
end

-- Rendering logic
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

local function clear_highlights(bufnr)
    if api.nvim_buf_is_valid(bufnr) then
        api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
    end
end

-- Simple highlight color cache
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

-- Render chunk guides based on scope
local function render_chunk_guides(scope)
    if not scope then
        local bufnr = api.nvim_get_current_buf()
        clear_highlights(bufnr)
        return
    end

    local bufnr = scope.buf
    if not api.nvim_buf_is_valid(bufnr) or bufnr ~= api.nvim_get_current_buf() then
        return
    end

    clear_highlights(bufnr)

    local highlight_group = update_mode_highlight()
    local start_row, end_row = scope.from - 1, scope.to - 1 -- Convert to 0-indexed
    local leftcol = fn.winsaveview().leftcol
    local shiftwidth = fn.shiftwidth()

    local start_indent = get_indent_level(bufnr, start_row)
    local end_indent = get_indent_level(bufnr, end_row)
    local guide_col = math.max(math.min(start_indent, end_indent) - shiftwidth, 0)

    -- Safety check for content overlap
    local min_content_start = math.huge
    for r = start_row, end_row do
        local line = api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
        if line:match("%S") then
            local content_start = line:find("%S") - 1
            min_content_start = math.min(min_content_start, content_start)
        end
    end

    if min_content_start ~= math.huge and guide_col >= min_content_start then
        guide_col = math.max(min_content_start - 1, 0)
    end

    -- Only render if guide is visible
    if guide_col < leftcol then
        return
    end

    local line_count = api.nvim_buf_line_count(bufnr)

    -- Helper function to place character overlay
    local function place_char_overlay(row, char, win_col)
        if row >= 0 and row < line_count and win_col >= 0 then
            pcall(api.nvim_buf_set_extmark, bufnr, M.ns_id, row, 0, {
                virt_text = { { char, highlight_group } },
                virt_text_pos = "overlay",
                virt_text_win_col = win_col,
                hl_mode = "combine",
                priority = 100,
            })
        end
    end

    -- Render top corner with horizontal line
    if start_indent > 0 and guide_col < start_indent then
        local start_line = api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
        local start_char_at_guide = start_line:sub(guide_col + 1, guide_col + 1)

        if start_char_at_guide:match("%s") or start_char_at_guide == "" then
            place_char_overlay(start_row, config.chars.corner_top, guide_col - leftcol)

            -- Add horizontal line extending right from the top corner
            for col_offset = 1, start_indent - guide_col - 1 do
                local target_col = guide_col + col_offset
                if target_col < #start_line then
                    local char_at_pos = start_line:sub(target_col + 1, target_col + 1)
                    if char_at_pos:match("%s") or char_at_pos == "" then
                        place_char_overlay(start_row, config.chars.horizontal_line, target_col - leftcol)
                    else
                        break -- Stop if we hit non-whitespace
                    end
                else
                    break -- Stop if we exceed line length
                end
            end
        end
    end

    -- Render vertical lines
    for r = start_row + 1, end_row - 1 do
        local line = api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
        local char_at_pos = guide_col < #line and line:sub(guide_col + 1, guide_col + 1) or ""

        if char_at_pos:match("%s") or char_at_pos == "" then
            place_char_overlay(r, config.chars.vertical_line, guide_col - leftcol)
        end
    end

    -- Render bottom corner with horizontal line
    if end_indent > 0 and guide_col < end_indent then
        local end_line = api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
        local end_char_at_guide = end_line:sub(guide_col + 1, guide_col + 1)

        if end_char_at_guide:match("%s") or end_char_at_guide == "" then
            place_char_overlay(end_row, config.chars.corner_bottom, guide_col - leftcol)

            -- Add horizontal line extending right from the bottom corner
            for col_offset = 1, end_indent - guide_col - 1 do
                local target_col = guide_col + col_offset
                if target_col < #end_line then
                    local char_at_pos = end_line:sub(target_col + 1, target_col + 1)
                    if char_at_pos:match("%s") or char_at_pos == "" then
                        place_char_overlay(end_row, config.chars.horizontal_line, target_col - leftcol)
                    else
                        break -- Stop if we hit non-whitespace
                    end
                else
                    break -- Stop if we exceed line length
                end
            end
        end
    end
end

-- Main module logic
local function should_render(bufnr)
    if not M.enabled or M.disabled_buffers[bufnr] then
        return false
    end

    local filetype = vim.bo[bufnr].filetype
    local buftype = vim.bo[bufnr].buftype

    if buftype ~= "" or filetype == "" or fn.shiftwidth() == 0 then
        return false
    end

    -- Check file size
    local name = api.nvim_buf_get_name(bufnr)
    if name ~= "" then
        local ok, file_size = pcall(fn.getfsize, name)
        if ok and file_size > config.max_file_size then
            M.disabled_buffers[bufnr] = true
            return false
        end
    end

    return true
end

-- Check if window is floating
local function is_floating_win(winid)
    local win_config = api.nvim_win_get_config(winid or 0)
    return win_config.relative ~= ""
end

-- Disable chunks for a specific buffer
local function disable_chunks_for_buffer(bufnr)
    if api.nvim_buf_is_valid(bufnr) then
        clear_highlights(bufnr)
    end
end

-- Immediate rendering function for buffer switches
local function render_immediately_for_current_buffer()
    local current_win = api.nvim_get_current_win()
    local current_buf = api.nvim_get_current_buf()

    -- Skip floating windows
    if is_floating_win(current_win) then
        return
    end

    if not should_render(current_buf) then
        clear_highlights(current_buf)
        return
    end

    -- Get scope immediately without debouncing
    get_scope(
        function(scope)
            if scope and should_render(current_buf) then
                M.current_scope = scope
                render_chunk_guides(scope)
            else
                M.current_scope = nil
                clear_highlights(current_buf)
            end
        end,
        vim.tbl_extend("keep", {
            buf = current_buf,
            pos = api.nvim_win_get_cursor(current_win),
        }, config.scope)
    )
end

-- Scope change callback
local function on_scope_change(win, buf, scope)
    -- Only render for current window/buffer
    if win == api.nvim_get_current_win() and buf == api.nvim_get_current_buf() then
        if scope and should_render(buf) then
            M.current_scope = scope
            render_chunk_guides(scope)
        else
            M.current_scope = nil
            clear_highlights(buf)
        end
    end
end

-- Initialize the scope listener
local function init_scope_listener()
    if M.scope_listener then
        M.scope_listener:disable()
    end

    M.scope_listener = Listener.new(on_scope_change, config.scope)
    M.scope_listener:enable()
end

-- Mode change handler
local function on_mode_changed()
    -- Update the highlight group for the new mode
    update_mode_highlight()

    -- If we have a last regular window with chunks, re-render to update colors
    if M.last_regular_win and api.nvim_win_is_valid(M.last_regular_win) then
        api.nvim_win_call(M.last_regular_win, function()
            local bufnr = api.nvim_get_current_buf()
            if should_render(bufnr) and M.current_scope then
                render_chunk_guides(M.current_scope)
            end
        end)
    end
end

-- Public API
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
end

function M.enable()
    M.enabled = true
    if not M.scope_listener then
        init_scope_listener()
    elseif not M.scope_listener.enabled then
        M.scope_listener:enable()
    end
    -- Force immediate update on enable
    render_immediately_for_current_buffer()
end

function M.disable()
    M.enabled = false
    if M.scope_listener then
        M.scope_listener:disable()
    end
    -- Clear all highlights
    for _, bufnr in pairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(bufnr) then
            clear_highlights(bufnr)
        end
    end
    M.current_scope = nil
end

function M.refresh()
    if M.scope_listener then
        M.scope_listener:update(nil, { now = true })
    end
end

-- Enable chunk guides for a specific buffer
function M.enable_for_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if M.disabled_buffers[bufnr] then
        M.disabled_buffers[bufnr] = nil
        render_immediately_for_current_buffer()
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

-- Get current scope (for debugging)
function M.get_current_scope()
    return M.current_scope
end

-- Initialize on module load
local function init()
    -- Set up mode change tracking for color updates
    local augroup = api.nvim_create_augroup("CustomChunkGuides", { clear = true })

    -- Mode change handling
    api.nvim_create_autocmd({ "ModeChanged", "CmdlineEnter", "CmdlineLeave" }, {
        group = augroup,
        callback = on_mode_changed,
    })

    -- Window focus management - immediate rendering without debounce
    api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "BufEnter" }, {
        group = augroup,
        callback = function()
            local current_win = api.nvim_get_current_win()

            -- Skip floating windows
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

            -- Render immediately for buffer switches
            if M.enabled then
                render_immediately_for_current_buffer()
            end

            M.last_regular_win = current_win
        end,
    })

    -- Clean up on exit
    api.nvim_create_autocmd({ "VimLeavePre" }, {
        group = augroup,
        callback = function()
            if M.scope_listener then
                M.scope_listener:disable()
            end
        end,
    })

    -- Auto-enable if enabled
    if M.enabled then
        init_scope_listener()
    end
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

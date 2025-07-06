local M = {}
local ellipsis = "…"
local max_depth = 3
-- Icon padding for specific icons
local icon_padding = {
    [""] = 1,
}

-- Lualine highlight formatting (borrowed from pretty-path)
local function lualine_format_hl(component, text, hl_group)
    if not hl_group or hl_group == "" or text == "" then
        return text
    end
    component.hl_cache = component.hl_cache or {}
    local lualine_hl_group = component.hl_cache[hl_group]
    if not lualine_hl_group then
        local u = require("lualine.utils.utils")
        local gui = vim.tbl_filter(function(x)
            return x
        end, {
            u.extract_highlight_colors(hl_group, "bold") and "bold",
            u.extract_highlight_colors(hl_group, "italic") and "italic",
        })
        lualine_hl_group = component:create_hl({
            fg = u.extract_highlight_colors(hl_group, "fg"),
            gui = #gui > 0 and table.concat(gui, ",") or nil,
        }, hl_group)
        component.hl_cache[hl_group] = lualine_hl_group
    end
    return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

local function shorten_path(parts, depth, ellipsis_char)
    if #parts <= depth then
        return parts
    end
    local shortened = {}
    -- first part
    table.insert(shortened, parts[1])
    -- ellipsis
    table.insert(shortened, ellipsis_char)
    -- last (depth - 1) parts
    for i = #parts - (depth - 2), #parts do
        table.insert(shortened, parts[i])
    end
    return shortened
end

-- Get icon using mini.icons directly
local function get_icon(filename, filetype)
    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return nil, nil
    end
    -- Try to get icon by filename first
    local icon, hl, is_default = mini_icons.get("file", filename)
    if not is_default then
        return icon, hl
    end
    -- Fall back to filetype
    if filetype and filetype ~= "" then
        icon, hl, is_default = mini_icons.get("filetype", filetype)
        if not is_default then
            return icon, hl
        end
    end
    return icon, hl
end

-- Get icon for current buffer
local function get_buffer_icon()
    local name = vim.fn.expand("%:t")
    local ft = vim.bo.filetype
    return get_icon(name, ft)
end

-- Format icon with padding (no color here)
local function format_icon(icon, hl_group)
    if not icon then
        return "", nil
    end
    local padding = icon_padding[icon] or 0
    local formatted_icon = icon .. string.rep(" ", padding)
    return formatted_icon, hl_group
end

-- Check if file is modified
local function is_modified()
    return vim.bo.modified
end

-- Apply color to filename only based on file state
local function colorize_filename(filename, component)
    if is_modified() then
        return lualine_format_hl(component, filename, "LualinePathModified")
    else
        return lualine_format_hl(component, filename, "LualinePathFile")
    end
end

function M.component(self)
    local path = vim.fn.expand(vim.g.pretty_path_use_absolute and "%:p" or "%:~:.")
    if path == "" then
        return lualine_format_hl(self, "[No Name]", "LualinePathFile")
    end

    -- Get icon for the current buffer
    local icon, hl_group = get_buffer_icon()
    local icon_str, icon_hl = format_icon(icon, hl_group)

    -- split path by OS path separator
    local path_sep = package.config:sub(1, 1)
    local parts = vim.split(path, path_sep, { trimempty = true })
    local shortened_parts = shorten_path(parts, max_depth, ellipsis)

    -- Separate directory path from filename
    local result = ""
    if #shortened_parts > 1 then
        -- Join all parts except the last one (directory path)
        local dir_parts = {}
        for i = 1, #shortened_parts - 1 do
            table.insert(dir_parts, shortened_parts[i])
        end
        local dir_path = table.concat(dir_parts, path_sep) .. path_sep

        -- Get the filename (last part)
        local filename = shortened_parts[#shortened_parts]

        -- Combine directory path (with LualinePathDir color) with colored filename
        result = lualine_format_hl(self, dir_path, "LualinePathDir") .. colorize_filename(filename, self)
    else
        -- Only filename, no directory
        result = colorize_filename(shortened_parts[1], self)
    end

    -- Combine icon and path with proper highlight handling
    if icon_str ~= "" then
        if icon_hl then
            local colored_icon = lualine_format_hl(self, icon_str, icon_hl)
            return colored_icon .. " " .. result
        else
            return icon_str .. " " .. result
        end
    else
        return result
    end
end

return M

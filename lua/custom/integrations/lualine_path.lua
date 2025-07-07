local M = {}

-- Configuration
local ellipsis = "…"
local max_depth = 3
local oil_max_depth = 4
local path_sep = package.config:sub(1, 1)
local icon_padding = { [""] = 1 }

-- Cache for highlight groups
local hl_cache = {}

-- Lualine highlight formatting
local function format_hl(component, text, hl_group)
    if not hl_group or hl_group == "" or text == "" then
        return text
    end

    local cached_hl = hl_cache[hl_group]
    if not cached_hl then
        local u = require("lualine.utils.utils")
        local gui_attrs = {}
        if u.extract_highlight_colors(hl_group, "bold") then
            table.insert(gui_attrs, "bold")
        end
        if u.extract_highlight_colors(hl_group, "italic") then
            table.insert(gui_attrs, "italic")
        end

        cached_hl = component:create_hl({
            fg = u.extract_highlight_colors(hl_group, "fg"),
            gui = #gui_attrs > 0 and table.concat(gui_attrs, ",") or nil,
        }, hl_group)
        hl_cache[hl_group] = cached_hl
    end

    return component:format_hl(cached_hl) .. text .. component:get_default_hl()
end

-- Shorten path by keeping first part, ellipsis, and last (depth-1) parts
local function shorten_path(parts, depth)
    if #parts <= depth then
        return parts
    end

    local result = { parts[1], ellipsis }
    for i = #parts - (depth - 2), #parts do
        table.insert(result, parts[i])
    end
    return result
end

-- Get icon using mini.icons
local function get_icon(filename, filetype)
    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return nil, nil
    end

    -- Try filename first, then filetype
    local icon, hl, is_default = mini_icons.get("file", filename)
    if not is_default then
        return icon, hl
    end

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
    local ft = vim.bo.buftype == "terminal" and "terminal" or vim.bo.filetype
    return get_icon(name, ft)
end

-- Format icon with padding
local function format_icon_with_padding(icon, hl_group)
    if not icon then
        return "", nil
    end
    local padding = icon_padding[icon] or 0
    return icon .. string.rep(" ", padding), hl_group
end

-- Combine icon and text with proper highlighting
local function combine_icon_text(component, icon_str, icon_hl, text)
    if icon_str == "" then
        return text
    end

    if icon_hl then
        local colored_icon = format_hl(component, icon_str, icon_hl)
        return colored_icon .. " " .. text
    else
        return icon_str .. " " .. text
    end
end

-- Handle checkhealth buffer display
local function handle_checkhealth(component)
    -- Always use checkhealth filetype for consistent icon
    local icon, hl = get_icon("", "checkhealth")
    local icon_str, icon_hl = format_icon_with_padding(icon, hl)
    local health_text = format_hl(component, "Health", "LualinePathHealth")
    return combine_icon_text(component, icon_str, icon_hl, health_text)
end

-- Handle terminal buffer display
local function handle_terminal(component)
    local path = vim.fn.expand("%")

    -- Extract terminal info (format: term://path//pid:shell)
    local terminal_info = vim.split(path, "//")[3] or ""
    local pid = terminal_info:match("^%d+")
    local shell_path = pid and terminal_info:gsub("^%d+:", "") or terminal_info

    -- Extract shell name and handle toggleterm format
    local shell_name = shell_path:match("([^/]+)$") or shell_path
    shell_name = shell_name:match("([^;]+)") or shell_name

    -- Build display text
    local display_name = shell_name ~= "" and shell_name or "Terminal"
    local result = format_hl(component, display_name, "LualinePathTerminal")

    if pid then
        result = result .. format_hl(component, " " .. pid, "LualinePathTerminalPID")
    end

    local icon_str, icon_hl = format_icon_with_padding(get_buffer_icon())
    return combine_icon_text(component, icon_str, icon_hl, result)
end

-- Handle oil buffer display
local function handle_oil(component)
    local ok, oil = pcall(require, "oil")
    if not ok then
        return ""
    end

    local current_dir = oil.get_current_dir()
    if not current_dir then
        return ""
    end

    -- Process path
    local cleaned_dir = current_dir:gsub(path_sep .. "$", "")
    local parts = vim.split(cleaned_dir, path_sep, { trimempty = true })
    local shortened_parts = shorten_path(parts, oil_max_depth)

    -- Build colored path
    local colored_path
    if #shortened_parts > 1 then
        local dir_parts = {}
        for i = 1, #shortened_parts - 1 do
            table.insert(dir_parts, shortened_parts[i])
        end
        local dir_path = table.concat(dir_parts, path_sep) .. path_sep
        local current_folder = shortened_parts[#shortened_parts]

        colored_path = format_hl(component, dir_path, "LualinePathOilDir")
            .. format_hl(component, current_folder, "LualinePathOilCurrent")
    else
        colored_path = format_hl(component, shortened_parts[1], "LualinePathOilCurrent")
    end

    local icon_str, icon_hl = format_icon_with_padding(get_buffer_icon())
    return combine_icon_text(component, icon_str, icon_hl, colored_path)
end

-- Handle regular files
local function handle_regular_file(component)
    local path = vim.fn.expand(vim.g.pretty_path_use_absolute and "%:p" or "%:~:.")
    if path == "" then
        return ""
    end

    local parts = vim.split(path, path_sep, { trimempty = true })
    local shortened_parts = shorten_path(parts, max_depth)

    -- Build result
    local result
    if #shortened_parts > 1 then
        local dir_parts = {}
        for i = 1, #shortened_parts - 1 do
            table.insert(dir_parts, shortened_parts[i])
        end
        local dir_path = table.concat(dir_parts, path_sep) .. path_sep
        local filename = shortened_parts[#shortened_parts]

        -- Color filename based on modification state
        local filename_hl = vim.bo.modified and "LualinePathModified" or "LualinePathFile"
        result = format_hl(component, dir_path, "LualinePathDir") .. format_hl(component, filename, filename_hl)
    else
        local filename_hl = vim.bo.modified and "LualinePathModified" or "LualinePathFile"
        result = format_hl(component, shortened_parts[1], filename_hl)
    end

    -- Add lock icon for non-modifiable buffers
    if not vim.bo.modifiable then
        result = result .. " " .. format_hl(component, "", "LualinePathLock")
    end

    local icon_str, icon_hl = format_icon_with_padding(get_buffer_icon())
    return combine_icon_text(component, icon_str, icon_hl, result)
end

-- Main component function
function M.component(self)
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype
    local bufname = vim.fn.expand("%")

    if buftype == "terminal" then
        return handle_terminal(self)
    elseif filetype == "oil" then
        return handle_oil(self)
    elseif filetype == "checkhealth" or bufname:match("^health://") or bufname:match("checkhealth") then
        return handle_checkhealth(self)
    else
        return handle_regular_file(self)
    end
end

return M

-- TODO: make lock not show on checkhealth.
-- add special handling for more filetypes

-- A custom component for heirline to display a truncated or special buffer path with icons.
local M = {}

-- Configuration
local ellipsis = "…"
local max_depth = 3
local oil_max_depth = 4 -- Max depth specifically for oil buffers
local path_sep = package.config:sub(1, 1)
local icon_padding = { [""] = 1 }
local lock_icon = " "

--- Get icon using mini.icons
local function get_icon(filename, filetype)
    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return nil, nil
    end

    local icon, hl, is_default

    -- Try filename first, but ONLY if filename is a string and not empty
    if type(filename) == "string" and filename ~= "" then
        icon, hl, is_default = mini_icons.get("file", filename)
        if not is_default then
            return icon, hl
        end
    end

    -- Then try filetype if it's available and is a string and not empty
    if filetype and type(filetype) == "string" and filetype ~= "" then
        icon, hl, is_default = mini_icons.get("filetype", filetype)
        if not is_default then
            return icon, hl
        end
    end

    -- Fallback if no specific icon found
    return nil, nil
end

--- Get icon for current buffer (general purpose)
local function get_buffer_icon()
    local name = vim.fn.expand("%:t")
    local ft = vim.bo.buftype == "terminal" and "terminal" or vim.bo.filetype
    -- Note: checkhealth icon override is handled directly in M.get_path
    return get_icon(name, ft)
end

--- Format icon with padding
local function format_icon_with_padding(icon, hl_group)
    if not icon then
        return "", nil
    end
    local padding = icon_padding[icon] or 0
    return icon .. string.rep(" ", padding), hl_group
end

--- Shortens a path by keeping the first part, an ellipsis, and the last few parts.
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

--- Handles display for terminal buffers.
local function handle_terminal()
    local path = vim.fn.expand("%")
    -- Extract info from "term://path//pid:shell"
    local terminal_info = vim.split(path, "//")[3] or ""
    local display_name = "Terminal"
    local pid_number = "" -- Will store just the PID number

    if terminal_info ~= "" then
        local pid_match = terminal_info:match("^%d+")
        local shell_path = pid_match and terminal_info:gsub("^%d+:", "") or terminal_info
        local shell_name = shell_path:match("([^/]+)$") or shell_path
        shell_name = shell_name:match("([^;]+)") or shell_name
        display_name = shell_name ~= "" and shell_name or "Terminal"

        if pid_match then
            pid_number = pid_match -- Store just the number
        end
    end

    return {
        display_name = display_name,
        pid_number = pid_number,
        display_hl = "HeirlinePathTerminal",
        pid_hl = "HeirlinePathTerminalPID",
    }
end

--- Handles display for oil buffers.
local function handle_oil()
    local ok, oil = pcall(require, "oil")
    if not ok then
        return "[oil not found]"
    end
    local current_dir = oil.get_current_dir()
    if not current_dir then
        return "[oil directory not found]"
    end
    -- Process and shorten the directory path
    local cleaned_dir = current_dir:gsub(path_sep .. "$", "")
    local parts = vim.split(cleaned_dir, path_sep, { trimempty = true })
    local shortened_parts = shorten_path(parts, oil_max_depth) -- Use oil-specific depth
    -- Reconstruct the path string
    if #shortened_parts <= 1 then
        return #shortened_parts == 1 and shortened_parts[1] or ""
    else
        local dir_parts = {}
        for i = 1, #shortened_parts - 1 do
            table.insert(dir_parts, shortened_parts[i])
        end
        local dir_path = table.concat(dir_parts, path_sep)
        local current_folder = shortened_parts[#shortened_parts]
        return dir_path .. path_sep .. current_folder
    end
end

--- Handles display for checkhealth buffers.
local function handle_checkhealth()
    return "Health"
end

--- Handles display for regular files.
local function handle_regular_file()
    local path = vim.fn.expand("%:~:.")
    if path == "" then
        return ""
    end
    local parts = vim.split(path, path_sep, { trimempty = true })
    local shortened_parts = shorten_path(parts, max_depth)
    if #shortened_parts <= 1 then
        return #shortened_parts == 1 and shortened_parts[1] or ""
    else
        local dir_parts = {}
        for i = 1, #shortened_parts - 1 do
            table.insert(dir_parts, shortened_parts[i])
        end
        local dir_path = table.concat(dir_parts, path_sep)
        local filename = shortened_parts[#shortened_parts]
        return dir_path .. path_sep .. filename
    end
end

--- Separate path and filename from a full path string
-- This function is designed to handle splitting a combined path string
-- into its directory and filename components.
local function separate_path_filename(full_path)
    if full_path == "" or full_path == "[No Name]" then
        return "", full_path
    end

    -- If the full_path doesn't contain the path separator or is in a special format,
    -- consider the whole thing as the "filename" part (no separate directory).
    if
        full_path:match("^%[.*%]$") -- e.g., "[oil not found]" or "[No Name]"
        or full_path:match("%(.*%)$") -- contains parentheses (like terminal, but separate_path_filename won't be used for terminal now)
        or not full_path:find(path_sep)
    then
        return "", full_path
    end

    local parts = vim.split(full_path, path_sep, { trimempty = true })
    if #parts <= 1 then
        return "", full_path
    end

    local filename = parts[#parts]
    table.remove(parts, #parts) -- Remove the last part (filename)
    local dir_path = table.concat(parts, path_sep)

    return dir_path .. path_sep, filename -- Add separator back to directory path
end

--- Gets the truncated path string with icon, dispatching to the correct handler.
function M.get_path()
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype
    local bufname = vim.fn.expand("%")

    local path_data = {
        type = "regular", -- Default type
    }

    -- Always get icon and base padding initially (can be overridden later for specific types)
    local icon, hl = get_buffer_icon()
    path_data.icon_str, path_data.icon_hl = format_icon_with_padding(icon, hl)
    -- *** CHANGE 1: Set padding_left to an empty string to remove the space ***
    path_data.padding_left = ""
    path_data.padding_right = " "

    if buftype == "terminal" then
        path_data.type = "terminal"
        local term_info = handle_terminal()
        path_data.terminal_display_name = term_info.display_name
        path_data.terminal_pid_number = term_info.pid_number
        path_data.terminal_display_hl = term_info.display_hl
        path_data.terminal_pid_hl = term_info.pid_hl
    elseif filetype == "oil" then
        path_data.type = "oil"
        local result_str = handle_oil() -- handle_oil returns combined string
        path_data.dir_path, path_data.filename = separate_path_filename(result_str)
    elseif filetype == "checkhealth" or bufname:match("^health://") or bufname:match("checkhealth") then
        path_data.type = "checkhealth"
        path_data.checkhealth_text = handle_checkhealth()
        -- Directly override icon for checkhealth, mimicking Lualine's behavior
        local checkhealth_icon, checkhealth_hl = get_icon(nil, "checkhealth") -- Force filetype lookup
        path_data.icon_str, path_data.icon_hl = format_icon_with_padding(checkhealth_icon, checkhealth_hl)
    else
        path_data.type = "regular"
        local result_str = handle_regular_file()
        path_data.dir_path, path_data.filename = separate_path_filename(result_str)
    end

    return path_data
end

-- The heirline component definition for the statusline
M.component = {
    condition = function()
        local bufname = vim.fn.expand("%")
        local buftype = vim.bo.buftype
        local filetype = vim.bo.filetype

        -- Show for meaningful buffer types
        if
            buftype == "terminal"
            or filetype == "oil"
            or filetype == "checkhealth"
            or bufname:match("^health://")
            or bufname:match("checkhealth")
        then
            return true
        end

        -- For regular files, only show if there's actually a filename
        -- This will hide it for empty/scratch buffers
        return bufname ~= "" and bufname ~= "[No Name]"
    end,

    -- 1. Icon Component
    {
        provider = function()
            local path_info = M.get_path()
            -- *** CHANGE 2: Remove path_info.padding_left from the return string ***
            return path_info.icon_str
        end,
        hl = function()
            local path_info = M.get_path()
            return path_info.icon_hl
        end,
    },

    -- 2. Directory Path / Terminal Name / Checkhealth Text Component
    {
        provider = function()
            local path_info = M.get_path()
            local display_text = ""
            if path_info.type == "oil" then
                -- For oil, this is the directory part
                display_text = path_info.dir_path
            elseif path_info.type == "terminal" then
                -- For terminal, this is the main shell/terminal name
                display_text = path_info.terminal_display_name
            elseif path_info.type == "checkhealth" then
                -- For checkhealth, this is the "Health" text
                display_text = path_info.checkhealth_text
            else -- regular file
                -- For regular files, this is the directory path
                display_text = path_info.dir_path
            end

            -- Add leading space only if an icon is present, otherwise use no padding (since padding_left is removed from icon)
            return path_info.icon_str ~= "" and " " .. display_text or display_text
        end,
        hl = function()
            local path_info = M.get_path()
            if path_info.type == "oil" then
                -- Only apply highlight if there's an actual directory path (e.g., not just "./")
                return path_info.dir_path ~= "" and "HeirlinePathOilDir" or nil
            elseif path_info.type == "terminal" then
                return path_info.terminal_display_hl
            elseif path_info.type == "checkhealth" then
                return "HeirlinePathHealth"
            else -- regular file
                return "HeirlinePathDir"
            end
        end,
    },

    -- 3. Filename / Current Oil Folder / Terminal PID Component
    {
        provider = function()
            local path_info = M.get_path()
            if path_info.type == "oil" then
                -- For oil, this is the current folder name
                return path_info.filename
            elseif path_info.type == "terminal" then
                -- For terminal, this is the PID number (with a leading space if it exists)
                return path_info.terminal_pid_number ~= "" and " " .. path_info.terminal_pid_number or ""
            else -- regular file
                -- For regular files, this is the filename
                return path_info.filename
            end
        end,
        hl = function()
            local path_info = M.get_path()
            if path_info.type == "oil" then
                return "HeirlinePathOilCurrent"
            elseif path_info.type == "terminal" then
                return path_info.terminal_pid_hl
            else -- regular file
                -- Use HeirlinePathModified if buffer is modified, otherwise use HeirlinePathFile
                return vim.bo.modified and "HeirlinePathModified" or "HeirlinePathFile"
            end
        end,
    },

    -- 4. Lock Icon Component
    {
        provider = function()
            local buftype = vim.bo.buftype
            local filetype = vim.bo.filetype

            if filetype ~= "oil" and buftype ~= "terminal" and not vim.bo.modifiable then
                local path_info = M.get_path()
                return lock_icon .. path_info.padding_right
            else
                return ""
            end
        end,
        hl = "HeirlinePathLock",
    },
}

return M

-- ================================================================================
-- =                                HEIRLINE PATH                                 =
-- ================================================================================

-- A flexible custom component for heirline to display a truncated or special buffer path with icons.
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

    if terminal_info ~= "" then
        local pid_match = terminal_info:match("^%d+")
        local shell_path = pid_match and terminal_info:gsub("^%d+:", "") or terminal_info

        if shell_path ~= "" then
            -- Remove leading slash if present
            if shell_path:sub(1, 1) == path_sep then
                shell_path = shell_path:sub(2)
            end

            -- Split the shell path into parts
            local shell_parts = vim.split(shell_path, path_sep, { trimempty = true })

            -- Apply the same truncation logic as regular files
            local shortened_parts = shorten_path(shell_parts, max_depth)

            if #shortened_parts <= 1 then
                return #shortened_parts == 1 and shortened_parts[1] or "Terminal"
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
    end

    return "Terminal" -- Fallback
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
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        return ""
    end

    local filepath = vim.fs.normalize(bufname)
    local home = vim.fs.normalize(vim.env.HOME or vim.fn.expand("$HOME"))
    local path_sep_pattern = path_sep == "\\" and "\\\\" or path_sep

    -- Ensure home ends with separator for proper matching
    local home_with_sep = home
    if home_with_sep:sub(-1) ~= path_sep then
        home_with_sep = home_with_sep .. path_sep
    end

    local display_path
    if filepath:sub(1, #home_with_sep) == home_with_sep then
        -- File is in home directory - just strip home prefix (NO ~)
        display_path = filepath:sub(#home_with_sep + 1)
    else
        -- File is outside home - show absolute path
        display_path = filepath
        -- Remove leading separator for consistency
        if display_path:sub(1, 1) == path_sep then
            display_path = display_path:sub(2)
        end
    end

    local parts = vim.split(display_path, path_sep_pattern, { trimempty = true })
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
    path_data.padding_left = ""
    path_data.padding_right = " "

    if buftype == "terminal" then
        path_data.type = "terminal"
        local result_str = handle_terminal() -- Now returns a path string like regular files
        path_data.dir_path, path_data.filename = separate_path_filename(result_str)
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

-- Helper function to get filename highlight
local function get_filename_hl(path_info)
    if path_info.type == "oil" then
        return "HeirlinePathOilCurrent"
    elseif path_info.type == "terminal" then
        return "HeirlinePathFile"
    else -- regular file
        -- Use HeirlinePathModified if buffer is modified, otherwise use HeirlinePathFile
        return vim.bo.modified and "HeirlinePathModified" or "HeirlinePathFile"
    end
end

-- The flexible heirline component definition for the statusline
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

    flexible = 2, -- Set priority for this flexible component

    -- Full path version (shown when there's enough space)
    {
        -- 1. Icon Component
        {
            provider = function()
                local path_info = M.get_path()
                return path_info.icon_str or ""
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
                    display_text = path_info.dir_path or ""
                elseif path_info.type == "terminal" then
                    -- For terminal, this is now the directory path like regular files
                    display_text = path_info.dir_path or ""
                elseif path_info.type == "checkhealth" then
                    -- For checkhealth, this is the "Health" text
                    display_text = path_info.checkhealth_text or ""
                else -- regular file
                    -- For regular files, this is the directory path
                    display_text = path_info.dir_path or ""
                end

                -- Add leading space only if an icon is present, otherwise use no padding
                return (path_info.icon_str and path_info.icon_str ~= "") and " " .. display_text or display_text
            end,
            hl = function()
                local path_info = M.get_path()
                if path_info.type == "oil" then
                    -- Only apply highlight if there's an actual directory path (e.g., not just "./")
                    return (path_info.dir_path and path_info.dir_path ~= "") and "HeirlinePathOilDir" or nil
                elseif path_info.type == "terminal" then
                    return "HeirlinePathDir" -- Use same highlight as regular files
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
                    return path_info.filename or ""
                elseif path_info.type == "terminal" then
                    -- For terminal, this is now the filename like regular files
                    return path_info.filename or ""
                else -- regular file
                    -- For regular files, this is the filename
                    return path_info.filename or ""
                end
            end,
            hl = function()
                local path_info = M.get_path()
                return get_filename_hl(path_info)
            end,
        },

        -- 4. Lock Icon Component
        {
            provider = function()
                local buftype = vim.bo.buftype
                local filetype = vim.bo.filetype
                local bufname = vim.fn.expand("%")

                -- Don't show lock for oil, terminal, or checkhealth buffers
                if
                    filetype ~= "oil"
                    and buftype ~= "terminal"
                    and filetype ~= "checkhealth"
                    and not bufname:match("^health://")
                    and not bufname:match("checkhealth")
                    and not vim.bo.modifiable
                then
                    local path_info = M.get_path()
                    return lock_icon .. (path_info.padding_right or " ")
                else
                    return ""
                end
            end,
            hl = "HeirlinePathLock",
        },
    },

    -- Filename only version (shown when space is limited)
    {
        -- 1. Icon Component
        {
            provider = function()
                local path_info = M.get_path()
                return path_info.icon_str or ""
            end,
            hl = function()
                local path_info = M.get_path()
                return path_info.icon_hl
            end,
        },

        -- 2. Filename Only Component
        {
            provider = function()
                local path_info = M.get_path()
                local display_text = ""

                if path_info.type == "checkhealth" then
                    -- For checkhealth, show the "Health" text
                    display_text = path_info.checkhealth_text or ""
                else
                    -- For all other types, show just the filename
                    display_text = path_info.filename or ""
                end

                -- Add leading space only if an icon is present
                return (path_info.icon_str and path_info.icon_str ~= "") and " " .. display_text or display_text
            end,
            hl = function()
                local path_info = M.get_path()
                if path_info.type == "checkhealth" then
                    return "HeirlinePathHealth"
                else
                    return get_filename_hl(path_info)
                end
            end,
        },

        -- 3. Lock Icon Component (same as full version)
        {
            provider = function()
                local buftype = vim.bo.buftype
                local filetype = vim.bo.filetype
                local bufname = vim.fn.expand("%")

                -- Don't show lock for oil, terminal, or checkhealth buffers
                if
                    filetype ~= "oil"
                    and buftype ~= "terminal"
                    and filetype ~= "checkhealth"
                    and not bufname:match("^health://")
                    and not bufname:match("checkhealth")
                    and not vim.bo.modifiable
                then
                    local path_info = M.get_path()
                    return lock_icon .. (path_info.padding_right or " ")
                else
                    return ""
                end
            end,
            hl = "HeirlinePathLock",
        },
    },
}

return M

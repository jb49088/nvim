-- ================================================================================
-- =                                CODE DEBUGGER                                 =
-- ================================================================================

local M = {}

local function get_debugger_path(debugger_cmd)
    local venv = os.getenv("VIRTUAL_ENV")
    if venv and debugger_cmd:match("^python") then
        return debugger_cmd:gsub("^python[%d%.]*", venv .. "/bin/python")
    end
    return debugger_cmd
end

function M.debug_in_zellij_vertical(debugger_cmd, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Debugging " .. display_name .. " in Zellij")
    local actual_debugger = get_debugger_path(debugger_cmd)
    local zellij_cmd = string.format('zellij run -- %s "%s"', actual_debugger, filename)
    vim.fn.system(zellij_cmd)
end

function M.debug_in_zellij_horizontal(debugger_cmd, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Debugging " .. display_name .. " in Zellij (horizontal)")
    local actual_debugger = get_debugger_path(debugger_cmd)
    local zellij_cmd = string.format('zellij run --direction down -- %s "%s"', actual_debugger, filename)
    vim.fn.system(zellij_cmd)
end

function M.debug_in_zellij_floating(debugger_cmd, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Debugging " .. display_name .. " in Zellij (floating)")
    local actual_debugger = get_debugger_path(debugger_cmd)
    local zellij_cmd = string.format(
        'zellij run --floating --width "80%%" --height "80%%" --x "10%%" --y "15%%" -- %s "%s"',
        actual_debugger,
        filename
    )
    vim.fn.system(zellij_cmd)
end

return M

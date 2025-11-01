local M = {}

function M.debug_in_zellij(debugger_cmd, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Debugging " .. display_name .. " in Zellij")
    local zellij_cmd = string.format('zellij run -- %s "%s"', debugger_cmd, filename)
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
    local zellij_cmd = string.format('zellij run --direction down -- %s "%s"', debugger_cmd, filename)
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
    local zellij_cmd = string.format(
        'zellij run --floating --width "80%%" --height "80%%" --x "10%%" --y "15%%" -- %s "%s"',
        debugger_cmd,
        filename
    )
    vim.fn.system(zellij_cmd)
end

return M

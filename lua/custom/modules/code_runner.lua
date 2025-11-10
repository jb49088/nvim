-- ================================================================================
-- =                                 CODE RUNNER                                  =
-- ================================================================================

local M = {}

function M.run_in_zellij_vertical(interpreter, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local zellij_cmd = string.format('zellij run -- %s "%s"', interpreter, filename)
    vim.fn.system(zellij_cmd)
end

function M.run_in_zellij_horizontal(interpreter, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local zellij_cmd = string.format('zellij run --direction down -- %s "%s"', interpreter, filename)
    vim.fn.system(zellij_cmd)
end

function M.run_in_zellij_floating(interpreter, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local zellij_cmd = string.format(
        'zellij run --floating --width "80%%" --height "80%%" --x "10%%" --y "15%%" -- %s "%s"',
        interpreter,
        filename
    )
    vim.fn.system(zellij_cmd)
end

function M.run_background(runner_cmd, filename)
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " detached")
    vim.cmd("silent !" .. runner_cmd)
end

return M

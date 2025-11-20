-- ================================================================================
-- =                                 CODE RUNNER                                  =
-- ================================================================================

local M = {}

local function get_interpreter_path(interpreter)
    local venv = os.getenv("VIRTUAL_ENV")
    if venv and interpreter:match("python") then
        return venv .. "/bin/" .. interpreter
    end
    return interpreter
end

function M.run_in_zellij_vertical(interpreter, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local actual_interpreter = get_interpreter_path(interpreter)
    local zellij_cmd = string.format('zellij run -- %s "%s"', actual_interpreter, filename)
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
    local actual_interpreter = get_interpreter_path(interpreter)
    local zellij_cmd = string.format('zellij run --direction down -- %s "%s"', actual_interpreter, filename)
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
    local actual_interpreter = get_interpreter_path(interpreter)
    local zellij_cmd = string.format(
        'zellij run --floating --width "80%%" --height "80%%" --x "10%%" --y "15%%" -- %s "%s"',
        actual_interpreter,
        filename
    )
    vim.fn.system(zellij_cmd)
end

function M.run_detached(interpreter, filename)
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " detached")
    local actual_interpreter = get_interpreter_path(interpreter)
    vim.cmd("silent !" .. actual_interpreter .. ' "' .. filename .. '"')
end

return M

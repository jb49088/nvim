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

function M.run_in_zellij(interpreter, filename, args)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local actual_interpreter = get_interpreter_path(interpreter)
    local args_str = args and (" " .. args) or ""
    local zellij_cmd = string.format('zellij run -- %s "%s"%s', actual_interpreter, filename, args_str)
    vim.fn.system(zellij_cmd)
end

function M.run_in_zellij_floating(interpreter, filename, args)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " in Zellij")
    local actual_interpreter = get_interpreter_path(interpreter)
    local args_str = args and (" " .. args) or ""
    local zellij_cmd = string.format(
        'zellij run --floating --width "80%%" --height "80%%" --x "10%%" --y "15%%" -- %s "%s"%s',
        actual_interpreter,
        filename,
        args_str
    )
    vim.fn.system(zellij_cmd)
end

function M.run_detached(interpreter, filename, args)
    vim.cmd("update")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " detached")
    local actual_interpreter = get_interpreter_path(interpreter)

    local cmd = { actual_interpreter, filename }
    if args then
        vim.list_extend(cmd, vim.split(args, " "))
    end

    vim.fn.jobstart(cmd, {
        detach = true,
        on_exit = function()
            vim.notify(display_name .. " finished")
        end,
    })
end

function M.with_args_prompt(run_func, interpreter, filename)
    vim.ui.input({
        prompt = "Arguments: ",
        default = "",
    }, function(input)
        if input ~= nil then
            run_func(interpreter, filename, input ~= "" and input or nil)
        end
    end)
end

return M

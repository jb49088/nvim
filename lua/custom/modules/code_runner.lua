local M = {}

function M.run_in_zellij(interpreter, filename)
    if os.getenv("ZELLIJ") == nil then
        vim.notify("Not in a Zellij session", vim.log.levels.WARN)
        return
    end

    vim.cmd("write")
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
    vim.cmd("write")
    local display_name = vim.fn.fnamemodify(filename, ":t")
    vim.notify("Running " .. display_name .. " detached")
    vim.cmd("silent !" .. runner_cmd)
end

return M

-- ================================================================================
-- =                              MODE_NUMBER_COLOR                               =
-- ================================================================================

local modes = {
    n = "ModeColorNormal",
    nt = "ModeColorNormal",
    i = "ModeColorInsert",
    v = "ModeColorVisual",
    V = "ModeColorVisual",
    ["\22"] = "ModeColorVisual",
    s = "ModeColorVisual",
    S = "ModeColorVisual",
    ["\19"] = "ModeColorVisual",
    c = "ModeColorCommand",
    t = "ModeColorTerminal",
    R = "ModeColorReplace",
    Rc = "ModeColorReplace",
    Rx = "ModeColorReplace",
    Rv = "ModeColorReplace",
    Rvc = "ModeColorReplace",
    Rvx = "ModeColorReplace",
    r = "ModeColorReplace",
}

local function update_line_color(mode)
    if modes[mode] then
        vim.api.nvim_set_hl(0, "CursorLineNr", { link = modes[mode] })
        if mode == "c" then
            vim.cmd.redraw()
        end
    end
end

update_line_color(vim.api.nvim_get_mode().mode)

local group = vim.api.nvim_create_augroup("LineNumberMode", { clear = true })

vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
        vim.schedule(function()
            update_line_color(vim.api.nvim_get_mode().mode)
        end)
    end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
        vim.schedule(function()
            update_line_color(vim.api.nvim_get_mode().mode)
        end)
    end,
})

-- TODO: add support for more modes

local modes = {
    n = "ModeColorNormal",
    i = "ModeColorInsert",
    v = "ModeColorVisual",
    V = "ModeColorVisual",
    c = "ModeColorCommand",
    t = "ModeColorTerminal",
    R = "ModeColorReplace",
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
vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("LineNumberMode", { clear = true }),
    callback = function()
        update_line_color(vim.api.nvim_get_mode().mode)
    end,
})

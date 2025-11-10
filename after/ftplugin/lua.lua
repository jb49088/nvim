-- ================================================================================
-- =                                     LUA                                      =
-- ================================================================================

local runner = require("custom.modules.code_runner")

-- Indentation
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true

-- Run keymaps
vim.keymap.set("n", "<leader>rv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_vertical("lua", filename)
end, { buffer = true, desc = "Run Lua in Vertical Pane" })

vim.keymap.set("n", "<leader>rh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_horizontal("lua", filename)
end, { buffer = true, desc = "Run Lua in Horizontal Pane" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("lua", filename)
end, { buffer = true, desc = "Run Lua in Floating Pane" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    local cmd = vim.fn.has("win32") == 1 and 'start /B lua.exe "' .. filename .. '"'
        or 'nohup lua "' .. filename .. '" > /dev/null 2>&1 &'
    runner.run_background(cmd, filename)
end, { buffer = true, desc = "Run Lua Detached" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

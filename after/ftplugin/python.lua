-- ================================================================================
-- =                                    PYTHON                                    =
-- ================================================================================

local runner = require("custom.modules.code_runner")
local debugger = require("custom.modules.code_debugger")

-- Indentation
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true

-- Run keymaps
vim.keymap.set("n", "<leader>rv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_vertical("python3", filename)
end, { buffer = true, desc = "Run Python in Vertical Pane" })

vim.keymap.set("n", "<leader>rh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_horizontal("python3", filename)
end, { buffer = true, desc = "Run Python in Horizontal Pane" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("python3", filename)
end, { buffer = true, desc = "Run Python in Floating Pane" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("python3", filename)
end, { buffer = true, desc = "Run Python Detached" })

-- Debug keymaps
vim.keymap.set("n", "<leader>dv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_vertical("python3 -m ipdb", filename)
end, { buffer = true, desc = "Debug Python in Vertical Pane" })

vim.keymap.set("n", "<leader>dh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_horizontal("python3 -m ipdb", filename)
end, { buffer = true, desc = "Debug Python in Horizontal Pane" })

vim.keymap.set("n", "<leader>df", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_floating("python3 -m ipdb", filename)
end, { buffer = true, desc = "Debug Python in Floating Pane" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

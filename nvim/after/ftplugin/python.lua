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

-- Run keymaps (without args)
vim.keymap.set("n", "<leader>rv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_vertical("python3", filename)
end, { buffer = true, desc = "Run Python (Vertical Pane)" })

vim.keymap.set("n", "<leader>rh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_horizontal("python3", filename)
end, { buffer = true, desc = "Run Python (Horizontal Pane" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("python3", filename)
end, { buffer = true, desc = "Run Python (Floating Pane)" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("python3", filename)
end, { buffer = true, desc = "Run Python (Detached)" })

-- Run keymaps (with args)
vim.keymap.set("n", "<leader>rV", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_vertical, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Vertical Pane)" })

vim.keymap.set("n", "<leader>rH", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_horizontal, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Horizontal Pane)" })

vim.keymap.set("n", "<leader>rF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_floating, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Floating Pane)" })

vim.keymap.set("n", "<leader>rD", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_detached, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Detached)" })

-- Debug keymaps (without args)
vim.keymap.set("n", "<leader>dv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_vertical("python3", filename)
end, { buffer = true, desc = "Debug Python (Vertical Pane)" })

vim.keymap.set("n", "<leader>dh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_horizontal("python3", filename)
end, { buffer = true, desc = "Debug Python (Horizontal Pane)" })

vim.keymap.set("n", "<leader>df", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_floating("python3", filename)
end, { buffer = true, desc = "Debug Python (Floating Pane)" })

-- Debug keymaps (with args)
vim.keymap.set("n", "<leader>dV", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.with_args_prompt(debugger.debug_in_zellij_vertical, "python3", filename)
end, { buffer = true, desc = "Debug Python With Args (Vertical Pane)" })

vim.keymap.set("n", "<leader>dH", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.with_args_prompt(debugger.debug_in_zellij_horizontal, "python3", filename)
end, { buffer = true, desc = "Debug Python With Args (Horizontal Pane)" })

vim.keymap.set("n", "<leader>dF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.with_args_prompt(debugger.debug_in_zellij_floating, "python3", filename)
end, { buffer = true, desc = "Debug Python With Args (Floating Pane)" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

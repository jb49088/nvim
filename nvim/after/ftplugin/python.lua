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
vim.keymap.set("n", "<leader>rr", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij("python3", filename)
end, { buffer = true, desc = "Run Python" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("python3", filename)
end, { buffer = true, desc = "Run Python (Floating)" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("python3", filename)
end, { buffer = true, desc = "Run Python (Detached)" })

-- Run keymaps (with args)
vim.keymap.set("n", "<leader>rR", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij, "python3", filename)
end, { buffer = true, desc = "Run Python With Args" })

vim.keymap.set("n", "<leader>rF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_floating, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Floating)" })

vim.keymap.set("n", "<leader>rD", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_detached, "python3", filename)
end, { buffer = true, desc = "Run Python With Args (Detached)" })

-- Debug keymaps (without args)
vim.keymap.set("n", "<leader>dd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij("python3", filename)
end, { buffer = true, desc = "Debug Python" })

vim.keymap.set("n", "<leader>df", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.debug_in_zellij_floating("python3", filename)
end, { buffer = true, desc = "Debug Python (Floating)" })

-- Debug keymaps (with args)
vim.keymap.set("n", "<leader>dD", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.with_args_prompt(debugger.debug_in_zellij, "python3", filename)
end, { buffer = true, desc = "Debug Python With Args" })

vim.keymap.set("n", "<leader>dF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    debugger.with_args_prompt(debugger.debug_in_zellij_floating, "python3", filename)
end, { buffer = true, desc = "Debug Python With Args (Floating)" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

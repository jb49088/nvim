-- ================================================================================
-- =                                     BASH                                     =
-- ================================================================================

local runner = require("custom.modules.code_runner")

-- Indentation
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true

-- Run keymaps (without args)
vim.keymap.set("n", "<leader>rv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_vertical("bash", filename)
end, { buffer = true, desc = "Run Bash (Vertical Pane)" })

vim.keymap.set("n", "<leader>rh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_horizontal("bash", filename)
end, { buffer = true, desc = "Run Bash (Horizontal Pane)" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("bash", filename)
end, { buffer = true, desc = "Run Bash (Floating Pane)" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("bash", filename)
end, { buffer = true, desc = "Run Bash (Detached)" })

-- Run keymaps (with args)
vim.keymap.set("n", "<leader>rV", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_vertical, "bash", filename)
end, { buffer = true, desc = "Run Bash With Args (Vertical Pane)" })

vim.keymap.set("n", "<leader>rH", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_horizontal, "bash", filename)
end, { buffer = true, desc = "Run Bash With Args (Horizontal Pane)" })

vim.keymap.set("n", "<leader>rF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_floating, "bash", filename)
end, { buffer = true, desc = "Run Bash With Args (Floating Pane)" })

vim.keymap.set("n", "<leader>rD", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_detached, "bash", filename)
end, { buffer = true, desc = "Run Bash With Args (Detached)" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

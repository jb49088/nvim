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

-- Run keymaps
vim.keymap.set("n", "<leader>rv", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_vertical("bash", filename)
end, { buffer = true, desc = "Run Bash in Vertical Pane" })

vim.keymap.set("n", "<leader>rh", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_horizontal("bash", filename)
end, { buffer = true, desc = "Run Bash in Horizontal Pane" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("bash", filename)
end, { buffer = true, desc = "Run Bash in Floating Pane" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("bash", filename)
end, { buffer = true, desc = "Run Bash Detached" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

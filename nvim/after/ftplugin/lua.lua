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

-- Run keymaps (without args)
vim.keymap.set("n", "<leader>rr", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij("lua", filename)
end, { buffer = true, desc = "Run Lua" })

vim.keymap.set("n", "<leader>rf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij_floating("lua", filename)
end, { buffer = true, desc = "Run Lua (Floating)" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_detached("lua", filename)
end, { buffer = true, desc = "Run Lua (Detached)" })

-- Run keymaps (with args)
vim.keymap.set("n", "<leader>rR", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij, "lua", filename)
end, { buffer = true, desc = "Run Lua With Args" })

vim.keymap.set("n", "<leader>rF", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_in_zellij_floating, "lua", filename)
end, { buffer = true, desc = "Run Lua With Args (Floating)" })

vim.keymap.set("n", "<leader>rD", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.with_args_prompt(runner.run_detached, "lua", filename)
end, { buffer = true, desc = "Run Lua With Args (Detached)" })

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

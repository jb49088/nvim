local runner = require("custom.modules.code_runner")

-- Indentation
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true

-- Keymaps
vim.keymap.set("n", "<leader>rt", function()
    local filename = vim.api.nvim_buf_get_name(0)
    runner.run_in_zellij("python3", filename)
end, { buffer = true, desc = "Run Python in Terminal" })

vim.keymap.set("n", "<leader>rd", function()
    local filename = vim.api.nvim_buf_get_name(0)
    local cmd = vim.fn.has("win32") == 1 and 'start /B pythonw.exe "' .. filename .. '"'
        or 'nohup python3 "' .. filename .. '" > /dev/null 2>&1 &'
    runner.run_background(cmd, filename)
end, { buffer = true, desc = "Run Python Detached" })

require("which-key").add({
    { "<leader>rt", icon = { icon = "", hl = "MiniIconsRed" }, buffer = vim.api.nvim_get_current_buf() },
    { "<leader>rd", icon = { icon = "", hl = "MiniIconsRed" }, buffer = vim.api.nvim_get_current_buf() },
})

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent<"

--- Editor behavior ---
vim.api.nvim_create_augroup("editor_behavior", { clear = true })

-- Disable commenting next line
vim.api.nvim_create_autocmd("FileType", {
    group = "editor_behavior",
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
    end,
})

-- Restore terminal cursor on exit
vim.api.nvim_create_autocmd("VimLeave", {
    group = "editor_behavior",
    command = "set guicursor=a:ver25",
})

--- UI/Visual enhancements ---
vim.api.nvim_create_augroup("ui_enhancements", { clear = true })

-- Highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = "ui_enhancements",
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Always open help in vertical split
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = "ui_enhancements",
    callback = function()
        if vim.bo.filetype == "help" then
            vim.cmd("wincmd L")
        end
    end,
})

--- Terminal settings ---
vim.api.nvim_create_augroup("terminal_settings", { clear = true })

-- Set filetype for terminal buffers for mini.icons
vim.api.nvim_create_autocmd("TermOpen", {
    group = "terminal_settings",
    callback = function()
        vim.bo.filetype = "terminal"
    end,
})

-- Open terminals buffers in terminal mode
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
    group = "terminal_settings",
    pattern = "*",
    callback = function()
        if vim.bo.buftype == "terminal" then
            vim.cmd("normal! G$")
            vim.cmd("startinsert")
        end
    end,
})

-- Turn off sidescrolloff in terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
    group = "terminal_settings",
    pattern = "*",
    callback = function()
        vim.opt_local.sidescrolloff = 0
    end,
})

-- Fix scrolloff glitch when switching to terminal buffers in normal mode
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = "terminal_settings",
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "terminal" then
            vim.wo.scrolloff = 0
            vim.cmd("redraw!")
        end
    end,
})

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

-- Automatically check for external file changes and reload buffers
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = "editor_behavior",
    pattern = "*",
    command = "if mode() != 'c' | checktime | endif",
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

-- Hide diagnostics in insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.hide()
    end,
})

-- Show diagnostics when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.show()
    end,
})

-- Always open help in vertical split
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = "ui_enhancements",
    callback = function()
        if vim.bo.filetype == "help" then
            -- Check if we're in a picker/preview window
            local win_config = vim.api.nvim_win_get_config(0)
            if win_config.relative ~= "" then
                -- This is a floating window (likely a picker preview), skip the repositioning
                return
            end

            -- Check if the current window is part of a picker by looking at buffer name or other indicators
            local buf_name = vim.api.nvim_buf_get_name(0)
            if buf_name:match("snacks://") or buf_name:match("picker://") then
                return
            end

            vim.cmd("wincmd L")
            -- Recalculate scrolloff based on the new window size
            vim.opt_local.scrolloff = 10
        end
    end,
})

-- Fix flickering line numbers on windows terminal
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = "ui_enhancements",
    callback = function()
        vim.o.cursorline = false
        vim.o.cursorline = true
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

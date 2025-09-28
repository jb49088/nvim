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
vim.api.nvim_create_autocmd({ "VimLeave", "ExitPre" }, {
    group = "editor_behavior",
    command = "set guicursor=a:ver25",
})

-- Automatically check for external file changes and reload buffers
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = "editor_behavior",
    pattern = "*",
    command = "if mode() != 'c' | checktime | endif",
})

-- Automatically remove LuaSnip snippet session if you leave insert/snippet mode
vim.api.nvim_create_autocmd("ModeChanged", {
    group = "editor_behavior",
    pattern = { "s:n", "i:*" },
    callback = function()
        local luasnip = require("luasnip")
        if luasnip.session and luasnip.session.current_nodes[vim.api.nvim_get_current_buf()] then
            luasnip.unlink_current()
        end
    end,
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

-- Hide diagnostics in insert mode for current buffer only
vim.api.nvim_create_autocmd("InsertEnter", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.hide(nil, vim.api.nvim_get_current_buf())
    end,
})

-- Show diagnostics when leaving insert mode for current buffer only
vim.api.nvim_create_autocmd("InsertLeave", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.show(nil, vim.api.nvim_get_current_buf())
    end,
})

-- Auto-balance windows when terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
    group = "ui_enhancements",
    callback = function()
        vim.cmd("wincmd =")
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
    callback = function(args)
        if vim.bo[args.buf].buftype == "terminal" and args.buf == vim.api.nvim_get_current_buf() then
            local original_buf = args.buf
            vim.schedule(function()
                -- Double schedule prevents startinsert from "bleeding over" to non-terminal
                -- buffers during rapid buffer switching (session restoration, splits)
                vim.schedule(function()
                    local current_buf = vim.api.nvim_get_current_buf()
                    local mode = vim.api.nvim_get_mode().mode
                    -- Only proceed if we're still in the right terminal and not already in insert
                    if current_buf == original_buf and vim.bo[current_buf].buftype == "terminal" and mode ~= "t" then -- Don't interfere if already in terminal insert mode
                        vim.cmd("normal! G$")
                        vim.cmd("startinsert")
                    end
                end)
            end)
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

-- -- Ensures that when exiting NeoVim, Zellij returns to normal mode
-- vim.api.nvim_create_autocmd("VimLeave", {
--     pattern = "*",
--     command = "silent !zellij action switch-mode normal",
-- })

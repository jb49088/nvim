-- Highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Restore terminal cursor on exit
vim.api.nvim_create_autocmd("VimLeave", {
    group = vim.api.nvim_create_augroup("restore_cursor_shape_on_exit", { clear = true }),
    command = "set guicursor=a:ver25",
})

-- Always open help in vertical split
vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function()
        if vim.bo.filetype == "help" then
            vim.cmd("wincmd L")
        end
    end,
})

-- Disable commenting next line
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
    end,
})

-- Open terminals in terminal mode
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
    pattern = "*",
    callback = function()
        if vim.opt.buftype:get() == "terminal" then
            vim.cmd(":startinsert")
        end
    end,
})

-- -- Refresh devicons after installing a new plugin
-- vim.api.nvim_create_autocmd("User", {
--     pattern = "LazyInstall",
--     callback = function()
--         vim.defer_fn(function()
--             local ok, devicons = pcall(require, "nvim-web-devicons")
--             if ok and devicons then
--                 devicons.refresh()
--             end
--         end, 10)
--     end,
-- })

-- -- Turn off cursorline in unfocused/inactive windows
-- vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave", "BufLeave" }, {
--     group = vim.api.nvim_create_augroup("CursorLineFocus", { clear = true }),
--     callback = function(args)
--         if vim.api.nvim_win_get_config(0).relative ~= "" then
--             vim.opt_local.cursorline = false
--             return
--         end
--         vim.opt_local.cursorline = args.event == "WinEnter" or args.event == "BufEnter"
--     end,
-- })

-- -- Hide cursor in SnacksDashboardOpened
-- vim.api.nvim_create_autocmd("User", {
--     pattern = "SnacksDashboardOpened",
--     callback = function()
--         local hl = vim.api.nvim_get_hl(0, { name = "Cursor", create = true })
--         hl.blend = 100
--         vim.api.nvim_set_hl(0, "Cursor", hl)
--         vim.cmd("set guicursor+=a:Cursor/lCursor")
--     end,
-- })

-- -- Unhide cursor in SnacksDashboardClosed
-- vim.api.nvim_create_autocmd("User", {
--     pattern = "SnacksDashboardClosed",
--     callback = function()
--         local hl = vim.api.nvim_get_hl(0, { name = "Cursor", create = true })
--         hl.blend = 0
--         vim.api.nvim_set_hl(0, "Cursor", hl)
--         -- vim.opt.guicursor.append("a:Cursor/lCursor")
--         vim.cmd("set guicursor+=a:Cursor/lCursor")
--     end,
-- })

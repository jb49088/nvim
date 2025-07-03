-- Highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Restore terminal cursor on vim leave
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

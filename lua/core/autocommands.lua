-- ================================================================================
-- =                                 AUTOCOMMANDS                                 =
-- ================================================================================

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- =============================== EDITOR BEHAVIOR ================================

augroup("editor_behavior", { clear = true })

-- Disable commenting next line
autocmd("FileType", {
    group = "editor_behavior",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "o" })
    end,
})

-- Restore terminal cursor on exit
autocmd({ "VimLeave", "ExitPre" }, {
    group = "editor_behavior",
    command = "set guicursor=a:ver25",
})

-- Automatically check for external file changes and reload buffers
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = "editor_behavior",
    command = "if mode() != 'c' | checktime | endif",
})

-- Save view when leaving buffer or writing (cursor position, folds, etc.)
autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
    group = "editor_behavior",
    callback = function(args)
        if vim.b[args.buf].view_activated then
            vim.cmd.mkview({ mods = { emsg_silent = true } })
        end
    end,
})

-- Restore view when entering buffer
autocmd("BufWinEnter", {
    group = "editor_behavior",
    callback = function(args)
        if not vim.b[args.buf].view_activated then
            local buftype = vim.bo[args.buf].buftype
            local filetype = vim.bo[args.buf].filetype
            local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }

            if buftype == "" and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
                vim.b[args.buf].view_activated = true
                vim.cmd.loadview({ mods = { emsg_silent = true } })
            end
        end
    end,
})

-- ============================ UI/VISUAL ENHANCEMENTS ============================

augroup("ui_enhancements", { clear = true })

-- Highlight text on yank
autocmd("TextYankPost", {
    group = "ui_enhancements",
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Hide diagnostics in insert mode
autocmd("InsertEnter", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.hide(nil, vim.api.nvim_get_current_buf())
    end,
})

-- Show diagnostics when leaving insert mode
autocmd("InsertLeave", {
    group = "ui_enhancements",
    callback = function()
        vim.diagnostic.show(nil, vim.api.nvim_get_current_buf())
    end,
})

-- Auto-balance windows when terminal is resized
autocmd("VimResized", {
    group = "ui_enhancements",
    callback = function()
        vim.cmd("wincmd =")
    end,
})

-- Always open help in vertical split
autocmd("BufWinEnter", {
    group = "ui_enhancements",
    callback = function()
        if vim.bo.filetype == "help" then
            local win_config = vim.api.nvim_win_get_config(0)
            if win_config.relative ~= "" then
                return
            end

            local buf_name = vim.api.nvim_buf_get_name(0)
            if buf_name:match("snacks://") or buf_name:match("picker://") then
                return
            end

            vim.cmd("wincmd L")
            vim.opt_local.scrolloff = 10
        end
    end,
})

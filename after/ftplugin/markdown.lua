-- ================================================================================
-- =                                   MARKDOWN                                   =
-- ================================================================================

-- Indentation
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Text display and editing
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.spell = true

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
    .. "| setlocal tabstop< shiftwidth< expandtab< wrap< linebreak< breakindent< spell<"
